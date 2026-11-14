<?php

namespace Tests\Feature;

use App\Enums\VirtualAccountStatus;
use App\Models\PaymentGatewayConfig;
use App\Models\Student;
use App\Models\User;
use App\Models\VirtualAccount;
use App\Services\Payment\DuitkuService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class DuitkuVirtualAccountTest extends TestCase
{
    use RefreshDatabase;

    private const MERCHANT_CODE = 'D0001';

    private const API_KEY = 'test_api_key';

    protected function setUp(): void
    {
        parent::setUp();

        PaymentGatewayConfig::create([
            'provider' => PaymentGatewayConfig::DUITKU,
            'is_active' => true,
            'config' => [
                'api_key' => self::API_KEY,
                'merchant_code' => self::MERCHANT_CODE,
                'base_url' => DuitkuService::SANDBOX_BASE_URL,
                'payment_method' => 'BC',
                'callback_url' => 'https://example.test/api/v1/payments/duitku/callback',
                'return_url' => 'https://example.test/return',
                'expiry_period' => 60,
            ],
        ]);
    }

    public function test_duitku_config_is_read_from_database(): void
    {
        $service = app(DuitkuService::class);

        $this->assertTrue($service->isConfigured());
        $this->assertSame(self::MERCHANT_CODE, $service->merchantCode());
        $this->assertSame(self::API_KEY, $service->apiKey());
        $this->assertSame(DuitkuService::SANDBOX_BASE_URL, $service->baseUrl());
    }

    public function test_it_creates_virtual_account_with_hmac_signature(): void
    {
        Http::fake([
            'sandbox.duitku.com/*' => Http::response([
                'merchantCode' => self::MERCHANT_CODE,
                'reference' => 'D0001REF123',
                'paymentUrl' => 'https://sandbox.duitku.com/payment/D0001REF123',
                'vaNumber' => '8808123456789012',
                'amount' => '50000',
                'statusCode' => '00',
                'statusMessage' => 'SUCCESS',
            ]),
        ]);

        $student = Student::factory()->create(['balance' => 0]);
        $virtualAccount = app(DuitkuService::class)->createVirtualAccount($student, 50000);

        $this->assertSame('8808123456789012', $virtualAccount->account_number);
        $this->assertSame('BC', $virtualAccount->payment_code);
        $this->assertSame(VirtualAccountStatus::Pending->value, $virtualAccount->status);
        $this->assertSame('D0001REF123', $virtualAccount->provider_reference);

        Http::assertSent(function (Request $request): bool {
            $orderId = (string) $request['merchantOrderId'];
            $expectedSignature = hash_hmac('sha256', self::MERCHANT_CODE.$orderId.'50000', self::API_KEY);

            return $request->url() === DuitkuService::SANDBOX_BASE_URL.'/v2/inquiry'
                && $request['merchantCode'] === self::MERCHANT_CODE
                && $request['paymentAmount'] === 50000
                && $request['paymentMethod'] === 'BC'
                && $request['signature'] === $expectedSignature;
        });
    }

    public function test_authenticated_user_can_create_virtual_account(): void
    {
        Http::fake([
            'sandbox.duitku.com/*' => Http::response([
                'reference' => 'D0001REF999',
                'paymentUrl' => 'https://sandbox.duitku.com/payment/D0001REF999',
                'vaNumber' => '7007014001444348',
                'amount' => '25000',
                'statusCode' => '00',
                'statusMessage' => 'SUCCESS',
            ]),
        ]);

        $student = Student::factory()->create(['balance' => 0]);
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/payments/duitku/va', [
            'student_id' => $student->id,
            'amount' => 25000,
            'payment_method' => 'BC',
        ]);

        $response->assertCreated()
            ->assertJsonPath('virtual_account.account_number', '7007014001444348')
            ->assertJsonPath('virtual_account.amount', 25000)
            ->assertJsonPath('virtual_account.status', VirtualAccountStatus::Pending->value);

        $this->assertDatabaseHas('virtual_accounts', [
            'student_id' => $student->id,
            'provider' => 'duitku',
            'account_number' => '7007014001444348',
            'amount' => 25000,
        ]);
    }

    public function test_callback_credits_wallet_once_and_is_idempotent(): void
    {
        $student = Student::factory()->create(['balance' => 10000]);
        $virtualAccount = $this->makeVirtualAccount($student, 50000);

        $payload = $this->validCallbackPayload($virtualAccount, 50000);

        $this->post('/api/v1/payments/duitku/callback', $payload)->assertOk();

        $this->assertSame(60000.0, (float) $student->fresh()->balance);
        $this->assertSame(VirtualAccountStatus::Paid->value, $virtualAccount->fresh()->status);

        // Callback kedua tidak boleh menambah saldo lagi.
        $this->post('/api/v1/payments/duitku/callback', $payload)->assertOk();

        $this->assertSame(60000.0, (float) $student->fresh()->balance);
        $this->assertDatabaseCount('transactions', 1);
    }

    public function test_callback_rejects_invalid_signature(): void
    {
        $student = Student::factory()->create(['balance' => 10000]);
        $virtualAccount = $this->makeVirtualAccount($student, 50000);

        $payload = $this->validCallbackPayload($virtualAccount, 50000);
        $payload['signature'] = str_repeat('a', 64);

        $this->post('/api/v1/payments/duitku/callback', $payload)->assertForbidden();

        $this->assertSame(10000.0, (float) $student->fresh()->balance);
        $this->assertSame(VirtualAccountStatus::Pending->value, $virtualAccount->fresh()->status);
    }

    public function test_callback_rejects_amount_mismatch(): void
    {
        $student = Student::factory()->create(['balance' => 10000]);
        $virtualAccount = $this->makeVirtualAccount($student, 50000);

        $payload = $this->validCallbackPayload($virtualAccount, 50000);
        $payload['amount'] = '10000';
        $payload['signature'] = hash_hmac(
            'sha256',
            self::MERCHANT_CODE.'10000'.$virtualAccount->merchant_order_id,
            self::API_KEY,
        );

        $this->post('/api/v1/payments/duitku/callback', $payload)->assertStatus(422);

        $this->assertSame(10000.0, (float) $student->fresh()->balance);
    }

    public function test_callback_static_va_accepts_open_amount_and_keeps_pending_status(): void
    {
        $student = Student::factory()->create(['balance' => 10000]);
        // VA statis dengan order awal 10.000
        $virtualAccount = $this->makeVirtualAccount($student, 10000, isStatic: true);

        // Transfer nominal bebas/open amount: misal Rp 75.000
        $payload = $this->validCallbackPayload($virtualAccount, 75000);

        $this->post('/api/v1/payments/duitku/callback', $payload)->assertOk();

        // Saldo bertambah 75.000 (10.000 + 75.000 = 85.000)
        $this->assertSame(85000.0, (float) $student->fresh()->balance);
        // Status VA tetap pending sehingga bisa digunakan lagi
        $this->assertSame(VirtualAccountStatus::Pending->value, $virtualAccount->fresh()->status);

        // Transfer kedua dengan referensi baru Rp 25.000
        $payload2 = $this->validCallbackPayload($virtualAccount, 25000);
        $payload2['reference'] = 'D0001REF456';
        $payload2['signature'] = hash_hmac(
            'sha256',
            self::MERCHANT_CODE.'25000'.$virtualAccount->merchant_order_id,
            self::API_KEY,
        );

        $this->post('/api/v1/payments/duitku/callback', $payload2)->assertOk();

        // Saldo bertambah lagi (85.000 + 25.000 = 110.000)
        $this->assertSame(110000.0, (float) $student->fresh()->balance);
        $this->assertDatabaseCount('transactions', 2);
    }

    public function test_artisan_command_simulates_va_payment(): void
    {
        $student = Student::factory()->create(['balance' => 20000, 'name' => 'Budi Santoso', 'nis' => 'BUDI-001']);
        $virtualAccount = $this->makeVirtualAccount($student, 50000, isStatic: true);

        $this->artisan('va:pay', [
            'identifier' => $virtualAccount->account_number,
            'amount' => '30000',
        ])->assertSuccessful();

        $this->assertSame(50000.0, (float) $student->fresh()->balance);
        $this->assertDatabaseCount('transactions', 1);
    }

    public function test_student_topup_va_returns_permanent_fixed_va(): void
    {
        $student = Student::factory()->create(['balance' => 0, 'nis' => '12345678']);

        $response = $this->actingAs($student, 'sanctum')->getJson('/api/v1/student/topup/va?payment_method=BC');

        $response->assertOk()
            ->assertJsonPath('virtual_account.bank_name', 'BCA Virtual Account')
            ->assertJsonPath('virtual_account.is_static', true)
            ->assertJsonPath('virtual_account.is_open_amount', true);

        $vaNumber = $response->json('virtual_account.account_number');
        $this->assertNotEmpty($vaNumber);
        $this->assertStringStartsWith('70070', $vaNumber);

        // Panggilan kedua tetap mengembalikan nomor VA yang persis sama
        $response2 = $this->actingAs($student, 'sanctum')->getJson('/api/v1/student/topup/va?payment_method=BC');
        $response2->assertOk()
            ->assertJsonPath('virtual_account.account_number', $vaNumber);
    }

    public function test_student_can_create_amount_bound_dynamic_va(): void
    {
        Http::preventStrayRequests();
        Http::fake([
            'sandbox.duitku.com/webapi/api/merchant/v2/inquiry' => Http::response([
                'reference' => 'D0001DYNAMIC123',
                'paymentUrl' => 'https://sandbox.duitku.com/payment/D0001DYNAMIC123',
                'vaNumber' => '7007014001555566',
                'amount' => '25000',
                'statusCode' => '00',
                'statusMessage' => 'SUCCESS',
            ]),
        ]);

        $student = Student::factory()->create(['balance' => 0]);
        $response = $this->actingAs($student, 'sanctum')->getJson(
            '/api/v1/student/topup/va?va_type=dynamic&amount=25000&payment_method=BC',
        );

        $response->assertOk()
            ->assertJsonPath('virtual_account.amount', 25000)
            ->assertJsonPath('virtual_account.is_static', false)
            ->assertJsonPath('virtual_account.is_open_amount', false)
            ->assertJsonPath('virtual_account.status', VirtualAccountStatus::Pending->value);

        $this->assertDatabaseHas('virtual_accounts', [
            'student_id' => $student->id,
            'payment_code' => 'BC',
            'account_number' => '7007014001555566',
            'amount' => 25000,
            'is_static' => false,
        ]);

        Http::assertSent(fn (Request $request): bool => $request->url() === DuitkuService::SANDBOX_BASE_URL.'/v2/inquiry'
            && $request['paymentAmount'] === 25000
            && $request['paymentMethod'] === 'BC');
    }

    public function test_dynamic_va_requires_a_valid_amount(): void
    {
        Http::preventStrayRequests();
        $student = Student::factory()->create(['balance' => 0]);

        $this->actingAs($student, 'sanctum')
            ->getJson('/api/v1/student/topup/va?va_type=dynamic&payment_method=BC')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('amount');

        $this->assertDatabaseCount('virtual_accounts', 0);
    }

    public function test_inquiry_returns_student_info_with_open_amount(): void
    {
        $student = Student::factory()->create(['name' => 'Ahmad Santri', 'balance' => 0]);
        $fixedVa = app(DuitkuService::class)->getOrCreateFixedVirtualAccount($student, 'BC');

        $session = 'session-guid-1234';
        $signature = md5(self::MERCHANT_CODE.'inquiry'.$fixedVa->account_number.$session.self::API_KEY);

        $response = $this->post('/api/v1/payments/duitku/inquiry', [
            'action' => 'inquiry',
            'merchantCode' => self::MERCHANT_CODE,
            'bin' => '70070',
            'vaNo' => $fixedVa->account_number,
            'session' => $session,
            'signature' => $signature,
        ]);

        $response->assertOk()
            ->assertJsonPath('statusCode', '00')
            ->assertJsonPath('statusMessage', 'SUCCESS')
            ->assertJsonPath('vaNo', $fixedVa->account_number)
            ->assertJsonPath('name', 'SEMESTA AHMAD SANTRI')
            ->assertJsonPath('amount', 0);

        $merchantOrderId = $response->json('merchantOrderId');
        $this->assertNotEmpty($merchantOrderId);
        $this->assertStringStartsWith('FIXED-'.$student->id.'-', $merchantOrderId);
    }

    public function test_inquiry_rejects_invalid_signature(): void
    {
        $student = Student::factory()->create(['name' => 'Ahmad Santri', 'balance' => 0]);
        $fixedVa = app(DuitkuService::class)->getOrCreateFixedVirtualAccount($student, 'BC');

        $response = $this->post('/api/v1/payments/duitku/inquiry', [
            'action' => 'inquiry',
            'merchantCode' => self::MERCHANT_CODE,
            'bin' => '70070',
            'vaNo' => $fixedVa->account_number,
            'session' => 'session-guid-1234',
            'signature' => 'invalidsignature123',
        ]);

        $response->assertOk()
            ->assertJsonPath('statusCode', '99')
            ->assertJsonPath('statusMessage', 'Invalid signature');
    }

    public function test_inquiry_returns_not_found_for_unknown_va(): void
    {
        $session = 'session-guid-unknown';
        $unknownVa = '7007099999999999';
        $signature = md5(self::MERCHANT_CODE.'inquiry'.$unknownVa.$session.self::API_KEY);

        $response = $this->post('/api/v1/payments/duitku/inquiry', [
            'action' => 'inquiry',
            'merchantCode' => self::MERCHANT_CODE,
            'bin' => '70070',
            'vaNo' => $unknownVa,
            'session' => $session,
            'signature' => $signature,
        ]);

        $response->assertOk()
            ->assertJsonPath('statusCode', '01')
            ->assertJsonPath('statusMessage', 'NOT FOUND');
    }

    public function test_callback_supports_md5_signature_for_fixed_va(): void
    {
        $student = Student::factory()->create(['balance' => 10000]);
        $virtualAccount = app(DuitkuService::class)->getOrCreateFixedVirtualAccount($student, 'BC');

        $amount = 150000;
        $orderId = $virtualAccount->merchant_order_id;
        $signatureMd5 = md5(self::MERCHANT_CODE.$amount.$orderId.self::API_KEY);

        $payload = [
            'merchantCode' => self::MERCHANT_CODE,
            'amount' => (string) $amount,
            'merchantOrderId' => $orderId,
            'resultCode' => '00',
            'reference' => 'D0001REFFIXEDMD5',
            'vaNumber' => $virtualAccount->account_number,
            'signature' => $signatureMd5,
        ];

        $this->post('/api/v1/payments/duitku/callback', $payload)->assertOk();

        $this->assertSame(160000.0, (float) $student->fresh()->balance);
        $this->assertSame(VirtualAccountStatus::Pending->value, $virtualAccount->fresh()->status);
        $this->assertDatabaseCount('transactions', 1);
    }

    private function makeVirtualAccount(Student $student, int $amount, bool $isStatic = false): VirtualAccount
    {
        return VirtualAccount::create([
            'student_id' => $student->id,
            'provider' => DuitkuService::PROVIDER,
            'payment_code' => 'BC',
            'bank_name' => 'BCA Virtual Account',
            'account_number' => '8808123456789012',
            'merchant_order_id' => 'VA'.$student->id.now()->format('ymdHis').'TEST',
            'provider_reference' => 'D0001REF123',
            'amount' => $amount,
            'status' => VirtualAccountStatus::Pending->value,
            'is_static' => $isStatic,
            'expires_at' => $isStatic ? now()->addYears(5) : now()->addMinutes(60),
        ]);
    }

    /**
     * @return array<string, string>
     */
    private function validCallbackPayload(VirtualAccount $virtualAccount, int $amount): array
    {
        return [
            'merchantCode' => self::MERCHANT_CODE,
            'amount' => (string) $amount,
            'merchantOrderId' => $virtualAccount->merchant_order_id,
            'resultCode' => '00',
            'reference' => 'D0001REF123',
            'vaNumber' => $virtualAccount->account_number,
            'signature' => hash_hmac(
                'sha256',
                self::MERCHANT_CODE.$amount.$virtualAccount->merchant_order_id,
                self::API_KEY,
            ),
        ];
    }
}
