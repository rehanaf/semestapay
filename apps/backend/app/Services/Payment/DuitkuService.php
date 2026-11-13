<?php

namespace App\Services\Payment;

use App\Enums\VirtualAccountStatus;
use App\Exceptions\Payment\DuitkuException;
use App\Models\PaymentGatewayConfig;
use App\Models\Student;
use App\Models\VirtualAccount;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class DuitkuService
{
    public const PROVIDER = PaymentGatewayConfig::DUITKU;

    public const SANDBOX_BASE_URL = 'https://sandbox.duitku.com/webapi/api/merchant';

    public const PRODUCTION_BASE_URL = 'https://passport.duitku.com/webapi/api/merchant';

    /**
     * Nama bank berdasarkan kode payment method Duitku.
     *
     * @var array<string, string>
     */
    private const PAYMENT_METHODS = [
        'BC' => 'BCA Virtual Account',
        'M2' => 'Mandiri Virtual Account',
        'VA' => 'Maybank Virtual Account',
        'I1' => 'BNI Virtual Account',
        'B1' => 'CIMB Niaga Virtual Account',
        'BT' => 'Permata Bank Virtual Account',
        'A1' => 'ATM Bersama',
        'AG' => 'Bank Artha Graha',
        'NC' => 'Bank Neo Commerce',
        'BR' => 'BRIVA',
        'S1' => 'Bank Sahabat Sampoerna',
        'DM' => 'Danamon Virtual Account',
        'BV' => 'BSI Virtual Account',
    ];

    private ?PaymentGatewayConfig $gateway = null;

    /**
     * Paksa service memakai konfigurasi tertentu (berguna untuk test).
     */
    public function useGateway(PaymentGatewayConfig $gateway): static
    {
        $this->gateway = $gateway;

        return $this;
    }

    /**
     * Apakah kredensial utama Duitku sudah diisi di database.
     */
    public function isConfigured(): bool
    {
        try {
            $gateway = $this->gateway();
        } catch (DuitkuException) {
            return false;
        }

        return $gateway->hasValue('api_key') && $gateway->hasValue('merchant_code');
    }

    public function merchantCode(): string
    {
        return $this->required('merchant_code');
    }

    public function apiKey(): string
    {
        return $this->required('api_key');
    }

    public function baseUrl(): string
    {
        return rtrim((string) $this->config('base_url', self::SANDBOX_BASE_URL), '/');
    }

    public function defaultPaymentMethod(): string
    {
        return (string) $this->config('payment_method', 'BC');
    }

    public function expiryPeriod(): int
    {
        return max(1, (int) $this->config('expiry_period', 1440));
    }

    public function callbackUrl(): string
    {
        $configured = $this->config('callback_url');

        if (is_string($configured) && $configured !== '') {
            return $configured;
        }

        return route('duitku.callback');
    }

    public function returnUrl(): string
    {
        $configured = $this->config('return_url');

        if (is_string($configured) && $configured !== '') {
            return $configured;
        }

        return (string) config('app.url', 'https://semestapay.id');
    }

    /**
     * Ambil daftar payment method yang aktif pada project Duitku.
     *
     * @return array<int, array<string, mixed>>
     */
    public function getPaymentMethods(int $amount = 10000): array
    {
        $datetime = now()->format('Y-m-d H:i:s');
        $signature = hash_hmac('sha256', $this->merchantCode().$amount.$datetime, $this->apiKey());

        $response = $this->client()->post($this->baseUrl().'/paymentmethod/getpaymentmethod', [
            'merchantcode' => $this->merchantCode(),
            'amount' => $amount,
            'datetime' => $datetime,
            'signature' => $signature,
        ]);

        $body = $this->decode($response->json(), $response->body(), $response->failed());

        if (($body['responseCode'] ?? null) !== '00') {
            throw new DuitkuException(
                'Gagal mengambil payment method Duitku: '.($body['responseMessage'] ?? 'respons tidak dikenal')
            );
        }

        return $body['paymentFee'] ?? [];
    }

    /**
     * Buat virtual account baru melalui endpoint inquiry Duitku.
     */
    public function createVirtualAccount(
        Student $student,
        float $amount,
        ?string $paymentMethod = null,
        ?string $merchantOrderId = null,
    ): VirtualAccount {
        $paymentAmount = $this->normalizeAmount($amount);
        $paymentMethod = $paymentMethod !== null && $paymentMethod !== ''
            ? strtoupper($paymentMethod)
            : strtoupper($this->defaultPaymentMethod());
        $merchantOrderId ??= $this->generateMerchantOrderId($student);

        $payload = $this->inquiryPayload($student, $paymentAmount, $paymentMethod, $merchantOrderId);

        $response = $this->client()->post($this->baseUrl().'/v2/inquiry', $payload);
        $body = $this->decode($response->json(), $response->body(), $response->failed());

        if (($body['statusCode'] ?? null) !== '00') {
            throw new DuitkuException(
                'Duitku menolak permintaan virtual account: '.($body['statusMessage'] ?? 'respons tidak dikenal')
            );
        }

        return VirtualAccount::create([
            'student_id' => $student->id,
            'provider' => self::PROVIDER,
            'payment_code' => $paymentMethod,
            'bank_name' => self::PAYMENT_METHODS[$paymentMethod] ?? $paymentMethod,
            'account_number' => $body['vaNumber'] ?? null,
            'merchant_order_id' => $merchantOrderId,
            'provider_reference' => $body['reference'] ?? null,
            'amount' => $paymentAmount,
            'status' => VirtualAccountStatus::Pending->value,
            'payment_url' => $body['paymentUrl'] ?? null,
            'expires_at' => now()->addMinutes($this->expiryPeriod()),
            'request_payload' => $payload,
            'response_payload' => $body,
            'metadata' => [
                'payment_method_name' => self::PAYMENT_METHODS[$paymentMethod] ?? $paymentMethod,
                'customer_name' => $student->name,
            ],
        ]);
    }

    /**
     * Cek status transaksi berdasarkan merchant order id.
     *
     * @return array<string, mixed>
     */
    public function checkTransaction(string $merchantOrderId): array
    {
        $signature = hash_hmac('sha256', $this->merchantCode().$merchantOrderId, $this->apiKey());

        $response = $this->client()->post($this->baseUrl().'/transactionStatus', [
            'merchantCode' => $this->merchantCode(),
            'merchantOrderId' => $merchantOrderId,
            'signature' => $signature,
        ]);

        $body = $this->decode($response->json(), $response->body(), $response->failed());

        if (! isset($body['statusCode'])) {
            throw new DuitkuException('Respons status transaksi Duitku tidak valid.');
        }

        return $body;
    }

    /**
     * Verifikasi signature callback Duitku (HMAC SHA256).
     *
     * @param  array<string, mixed>  $data
     */
    public function verifyCallback(array $data): bool
    {
        $merchantCode = (string) ($data['merchantCode'] ?? '');
        $amount = (string) ($data['amount'] ?? '');
        $merchantOrderId = (string) ($data['merchantOrderId'] ?? '');
        $signature = (string) ($data['signature'] ?? '');

        if ($merchantCode === '' || $amount === '' || $merchantOrderId === '' || $signature === '') {
            return false;
        }

        try {
            if (! hash_equals($this->merchantCode(), $merchantCode)) {
                return false;
            }

            $expected = hash_hmac('sha256', $merchantCode.$amount.$merchantOrderId, $this->apiKey());
        } catch (DuitkuException) {
            return false;
        }

        return hash_equals($expected, $signature);
    }

    /**
     * @return array<string, mixed>
     */
    private function inquiryPayload(
        Student $student,
        int $paymentAmount,
        string $paymentMethod,
        string $merchantOrderId,
    ): array {
        $name = trim((string) $student->name) !== '' ? trim((string) $student->name) : 'Santri';
        $firstName = Str::before($name, ' ');
        $lastName = Str::contains($name, ' ') ? Str::after($name, ' ') : $firstName;
        $email = $student->email ?: ($student->parent_email ?: 'santri'.$student->id.'@semestapay.id');
        $phoneNumber = $this->normalizePhone($student->phone_parent);

        $signature = hash_hmac(
            'sha256',
            $this->merchantCode().$merchantOrderId.$paymentAmount,
            $this->apiKey(),
        );

        $payload = [
            'merchantCode' => $this->merchantCode(),
            'paymentAmount' => $paymentAmount,
            'paymentMethod' => $paymentMethod,
            'merchantOrderId' => $merchantOrderId,
            'productDetails' => 'Topup Saldo Santri '.$name,
            'additionalParam' => '',
            'merchantUserInfo' => $student->nis,
            'customerVaName' => Str::limit($name, 20, ''),
            'email' => $email,
            'itemDetails' => [
                [
                    'name' => Str::limit('Topup Saldo Santri', 255),
                    'price' => $paymentAmount,
                    'quantity' => 1,
                ],
            ],
            'customerDetail' => [
                'firstName' => $firstName,
                'lastName' => $lastName,
                'email' => $email,
            ],
            'callbackUrl' => $this->callbackUrl(),
            'returnUrl' => $this->returnUrl(),
            'signature' => $signature,
            'expiryPeriod' => $this->expiryPeriod(),
        ];

        if ($phoneNumber !== null) {
            $payload['phoneNumber'] = $phoneNumber;
            $payload['customerDetail']['phoneNumber'] = $phoneNumber;
        }

        return $payload;
    }

    private function normalizeAmount(float $amount): int
    {
        $normalized = (int) round($amount);

        if ($normalized < 10000) {
            throw new DuitkuException('Nominal minimal virtual account Duitku adalah Rp10.000.');
        }

        return $normalized;
    }

    private function generateMerchantOrderId(Student $student): string
    {
        return sprintf(
            'VA%s%s%s',
            $student->id,
            now()->format('ymdHis'),
            Str::upper(Str::random(4)),
        );
    }

    private function normalizePhone(?string $phone): ?string
    {
        if ($phone === null) {
            return null;
        }

        $normalized = (string) preg_replace('/[^0-9+]/', '', $phone);

        if (str_starts_with($normalized, '+62')) {
            $normalized = '0'.substr($normalized, 3);
        } elseif (str_starts_with($normalized, '62')) {
            $normalized = '0'.substr($normalized, 2);
        }

        return $normalized !== '' ? $normalized : null;
    }

    /**
     * @return array<string, mixed>
     */
    private function decode(mixed $json, string $rawBody, bool $failed): array
    {
        if (! is_array($json)) {
            throw new DuitkuException('Respons Duitku tidak valid: '.Str::limit($rawBody, 200));
        }

        if ($failed && ! isset($json['statusCode']) && ! isset($json['responseCode'])) {
            throw new DuitkuException('Permintaan ke Duitku gagal: '.Str::limit($rawBody, 200));
        }

        return $json;
    }

    private function client(): PendingRequest
    {
        return Http::acceptJson()->asJson()->timeout(30);
    }

    private function gateway(): PaymentGatewayConfig
    {
        if ($this->gateway instanceof PaymentGatewayConfig) {
            return $this->gateway;
        }

        $gateway = PaymentGatewayConfig::active(self::PROVIDER);

        if ($gateway === null) {
            throw new DuitkuException('Konfigurasi Duitku belum tersedia atau tidak aktif.');
        }

        return $this->gateway = $gateway;
    }

    private function config(string $key, mixed $default = null): mixed
    {
        return $this->gateway()->value($key, $default);
    }

    private function required(string $key): string
    {
        $value = $this->config($key);

        if (! is_string($value) || ! $this->gateway()->hasValue($key)) {
            throw new DuitkuException("Konfigurasi Duitku '{$key}' belum diatur di database.");
        }

        return trim($value);
    }
}
