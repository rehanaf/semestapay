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
