<?php

namespace App\Http\Controllers\Api\v1\Payment;

use App\Enums\VirtualAccountStatus;
use App\Exceptions\Payment\DuitkuException;
use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\VirtualAccount;
use App\Services\Payment\DuitkuService;
use App\Services\WalletService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Ramsey\Uuid\Uuid;
use Throwable;

class DuitkuController extends Controller
{
    public function __construct(
        private readonly DuitkuService $duitku,
        private readonly WalletService $wallets,
    ) {}

    /**
     * Ambil VA aktif milik santri yang sedang login.
     * Mengembalikan Virtual Account resmi Duitku yang terdaftar di Sandbox/Production.
     * Digunakan oleh aplikasi mobile siswa untuk halaman Top Up.
     */
    public function studentVa(Request $request): JsonResponse
    {
        $student = $request->user();

        if (! $student instanceof Student) {
            throw new AuthorizationException('Akses khusus aplikasi siswa.');
        }

        $validated = $request->validate([
            'va_type' => ['sometimes', 'string', 'in:fixed,dynamic'],
            'amount' => ['required_if:va_type,dynamic', 'numeric', 'min:10000'],
            'payment_method' => ['nullable', 'string', 'max:10'],
            'force_new' => ['sometimes', 'boolean'],
        ]);

        $vaType = $validated['va_type'] ?? 'fixed';
        $paymentMethod = (string) ($validated['payment_method'] ?? '');
        if ($paymentMethod === '') {
            $paymentMethod = $this->duitku->defaultPaymentMethod();
        }
        $paymentMethod = strtoupper($paymentMethod);

        if ($vaType === 'fixed') {
            $virtualAccount = $this->duitku->getOrCreateFixedVirtualAccount($student, $paymentMethod);

            return response()->json([
                'message' => 'Virtual account santri aktif.',
                'virtual_account' => $this->virtualAccountPayload($virtualAccount),
                'is_new' => false,
            ]);
        }

        $amount = (float) round((float) $validated['amount']);
        $forceNew = $request->boolean('force_new');

        // Cari VA aktif yang terdaftar di Duitku (status pending, belum expired, memiliki nomor VA & referensi)
        $virtualAccount = null;
        if (! $forceNew) {
            $virtualAccount = VirtualAccount::query()
                ->where('provider', DuitkuService::PROVIDER)
                ->where('student_id', $student->id)
                ->where('payment_code', $paymentMethod)
                ->where('is_static', false)
                ->where('amount', $amount)
                ->where('status', VirtualAccountStatus::Pending->value)
                ->whereNotNull('account_number')
                ->whereNotNull('provider_reference')
                ->where('expires_at', '>', now())
                ->latest('id')
                ->first();
        }

        $isNew = false;
        if ($virtualAccount === null) {
            try {
                $virtualAccount = $this->duitku->createVirtualAccount(
                    student: $student,
                    amount: $amount,
                    paymentMethod: $paymentMethod,
                );
                $isNew = true;
            } catch (DuitkuException $exception) {
                Log::error('Duitku createVirtualAccount failed in studentVa', [
                    'student_id' => $student->id,
                    'payment_method' => $paymentMethod,
                    'error' => $exception->getMessage(),
                ]);

                return response()->json([
                    'message' => 'Gagal menerbitkan Virtual Account Duitku: '.$exception->getMessage(),
                ], 422);
            }
        }

        return response()->json([
            'message' => 'Virtual account santri aktif.',
            'virtual_account' => $this->virtualAccountPayload($virtualAccount),
            'is_new' => $isNew,
        ]);
    }

    public function studentVas(Request $request): JsonResponse
    {
        $student = $request->user();

        if (! $student instanceof Student) {
            throw new AuthorizationException('Akses khusus aplikasi siswa.');
        }

        $limit = min(max($request->integer('limit', 50), 1), 100);
        $virtualAccounts = VirtualAccount::query()
            ->with('student')
            ->where('student_id', $student->id)
            ->where('is_static', false)
            ->latest('created_at')
            ->limit($limit)
            ->get();

        return response()->json([
            'data' => $virtualAccounts->map(
                fn (VirtualAccount $virtualAccount): array => $this->virtualAccountPayload($virtualAccount),
            )->values(),
        ]);
    }

    /**
     * Inquiry request dari Duitku Fixed Virtual Account.
     * Dipanggil oleh Duitku saat nasabah memasukkan nomor VA di ATM/m-banking/simulator.
     */
    public function inquiry(Request $request): JsonResponse
    {
        $data = $request->all();

        if (! $this->duitku->verifyInquiry($data)) {
            Log::warning('Duitku inquiry signature verification failed', ['payload' => $data]);

            return response()->json([
                'vaNo' => (string) ($data['vaNo'] ?? ''),
                'name' => '',
                'amount' => 0,
                'merchantOrderId' => '',
                'statusCode' => '99',
                'statusMessage' => 'Invalid signature',
            ], 200);
        }

        $vaNo = (string) ($data['vaNo'] ?? ($data['account_number'] ?? ''));

        // Cari record Virtual Account dengan nomor VA yang diinquiry
        $virtualAccount = VirtualAccount::query()
            ->where('provider', DuitkuService::PROVIDER)
            ->where('account_number', $vaNo)
            ->first();

        // Jika belum ada record VA, coba parse dari nomor VA santri (prefix bank + id)
        if ($virtualAccount === null) {
            $virtualAccount = $this->resolveVirtualAccountFromVaNumber($vaNo, (string) ($data['bin'] ?? ''));
        }

        if ($virtualAccount === null || $virtualAccount->student === null) {
            Log::warning('Duitku inquiry VA number not found', ['vaNo' => $vaNo]);

            return response()->json([
                'vaNo' => $vaNo,
                'name' => '',
                'amount' => 0,
                'merchantOrderId' => '',
                'statusCode' => '01',
                'statusMessage' => 'NOT FOUND',
            ], 200);
        }

        $student = $virtualAccount->student;

        // Generate merchantOrderId unik per sesi pembayaran inquiry
        $sessionOrderId = sprintf(
            'FIXED-%s-%s-%s',
            $student->id,
            now()->format('ymdHis'),
            Str::upper(Str::random(4))
        );

        // Update record dengan session order ID terbaru agar callback langsung mengenali
        $virtualAccount->update([
            'merchant_order_id' => $sessionOrderId,
            'request_payload' => $data,
        ]);

        // Format nama maks 20 karakter sesuai batas perbankan Duitku
        $name = Str::limit('SEMESTA '.strtoupper((string) $student->name), 20, '');

        Log::info('Duitku inquiry successful', [
            'vaNo' => $vaNo,
            'student_id' => $student->id,
            'merchantOrderId' => $sessionOrderId,
        ]);

        return response()->json([
            'vaNo' => $vaNo,
            'name' => $name,
            'amount' => 0, // 0 = Open Amount (pembayar memasukkan nominal bebas di ATM/m-banking)
            'merchantOrderId' => $sessionOrderId,
            'statusCode' => '00',
            'statusMessage' => 'SUCCESS',
        ], 200);
    }

    /**
     * Daftar payment method virtual account yang aktif di project Duitku.
     */
    public function methods(Request $request): JsonResponse
    {
        $amount = (int) $request->query('amount', 10000);

        try {
            $methods = $this->duitku->getPaymentMethods($amount);
        } catch (DuitkuException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }

        return response()->json(['data' => $methods]);
    }

    /**
     * Buat virtual account baru untuk seorang santri.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'student_id' => ['required', 'integer', 'exists:students,id'],
            'amount' => ['required', 'numeric', 'min:10000'],
            'payment_method' => ['nullable', 'string', 'max:10'],
        ]);

        $student = Student::findOrFail($data['student_id']);

        try {
            $virtualAccount = $this->duitku->createVirtualAccount(
                student: $student,
                amount: (float) $data['amount'],
                paymentMethod: $data['payment_method'] ?? null,
            );
        } catch (DuitkuException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Virtual account berhasil dibuat.',
            'virtual_account' => $this->virtualAccountPayload($virtualAccount),
        ], 201);
    }

    /**
     * Callback pembayaran dari Duitku (application/x-www-form-urlencoded).
     */
    public function callback(Request $request): JsonResponse
    {
        $data = $request->all();

        if (! $this->duitku->verifyCallback($data)) {
            Log::warning('Duitku callback signature verification failed', ['payload' => $data]);

            return response()->json(['message' => 'Invalid signature'], 403);
        }

        $merchantOrderId = (string) ($data['merchantOrderId'] ?? '');
        $resultCode = (string) ($data['resultCode'] ?? '');
        $vaNumber = (string) ($data['vaNumber'] ?? ($data['vaNo'] ?? ''));

        $virtualAccount = VirtualAccount::query()
            ->where('provider', DuitkuService::PROVIDER)
            ->where(function ($q) use ($merchantOrderId, $vaNumber) {
                $q->where('merchant_order_id', $merchantOrderId);
                if ($vaNumber !== '') {
                    $q->orWhere('account_number', $vaNumber);
                }
            })
            ->first();

        // Jika tidak ditemukan dan merchantOrderId berpola FIXED-{studentId}-..., cari via student_id
        if ($virtualAccount === null && Str::startsWith($merchantOrderId, 'FIXED-')) {
            $parts = explode('-', $merchantOrderId);
            $studentId = $parts[1] ?? null;
            if ($studentId) {
                $virtualAccount = VirtualAccount::query()
                    ->where('provider', DuitkuService::PROVIDER)
                    ->where('student_id', $studentId)
                    ->where('is_static', true)
                    ->latest('id')
                    ->first();
            }
        }

        // Jika masih null dan vaNumber ada, coba cari lewat format nomor VA
        if ($virtualAccount === null && $vaNumber !== '') {
            $virtualAccount = $this->resolveVirtualAccountFromVaNumber($vaNumber);
        }

        if ($virtualAccount === null) {
            Log::warning('Duitku callback received for unknown order', [
                'merchant_order_id' => $merchantOrderId,
                'va_number' => $vaNumber,
            ]);

            return response()->json(['message' => 'Order not found']);
        }

        if ($resultCode !== '00') {
            if (! $virtualAccount->isStatic() && ! $virtualAccount->isPaid()) {
                $virtualAccount->update([
                    'status' => VirtualAccountStatus::Failed->value,
                    'callback_payload' => $data,
                ]);
            }

            return response()->json(['message' => 'Callback received']);
        }

        $callbackAmount = (float) ($data['amount'] ?? 0);

        if ($callbackAmount <= 0) {
            Log::error('Duitku callback invalid amount', [
                'merchant_order_id' => $merchantOrderId,
                'received' => $callbackAmount,
            ]);

            return response()->json(['message' => 'Invalid amount'], 422);
        }

        // Untuk VA non-statis (dynamic), wajib cocok dengan nominal request awal
        if (! $virtualAccount->isStatic() && abs($callbackAmount - (float) $virtualAccount->amount) > 0.01) {
            Log::error('Duitku callback amount mismatch', [
                'merchant_order_id' => $merchantOrderId,
                'expected' => (float) $virtualAccount->amount,
                'received' => $callbackAmount,
            ]);

            return response()->json(['message' => 'Amount mismatch'], 422);
        }

        $reference = (string) ($data['reference'] ?? '');
        // Idempotency key per referensi pembayaran unik Duitku
        $idempotencySeed = $reference !== ''
            ? "duitku:{$reference}"
            : "duitku:{$merchantOrderId}:{$callbackAmount}:".now()->format('Y-m-d-H');
        $idempotencyKey = Uuid::uuid5(Uuid::NAMESPACE_URL, $idempotencySeed)->toString();

        try {
            DB::transaction(function () use ($virtualAccount, $data, $merchantOrderId, $callbackAmount, $idempotencyKey): void {
                $locked = VirtualAccount::query()
                    ->whereKey($virtualAccount->id)
                    ->lockForUpdate()
                    ->firstOrFail();

                // Jika dynamic VA dan sudah pernah dibayar, abaikan duplikat
                if (! $locked->isStatic() && $locked->isPaid()) {
                    return;
                }

                $this->wallets->topup(
                    student: $locked->student,
                    amount: $callbackAmount,
                    method: 'duitku_va',
                    reference: $merchantOrderId,
                    idempotencyKey: $idempotencyKey,
                );

                $metadata = $locked->metadata ?? [];
                $metadata['last_paid_amount'] = $callbackAmount;
                $metadata['total_received'] = ((float) ($metadata['total_received'] ?? 0)) + $callbackAmount;
                $metadata['payments_count'] = (((int) ($metadata['payments_count'] ?? 0)) + 1);

                $updateData = [
                    'paid_at' => now(),
                    'provider_reference' => $data['reference'] ?? $locked->provider_reference,
                    'callback_payload' => $data,
                    'metadata' => $metadata,
                ];

                if (! $locked->isStatic()) {
                    $updateData['status'] = VirtualAccountStatus::Paid->value;
                } else {
                    // Static VA tetap pending/aktif agar selalu siap menerima transfer berikutnya
                    $updateData['status'] = VirtualAccountStatus::Pending->value;
                }

                $locked->update($updateData);
            });
        } catch (Throwable $exception) {
            Log::error('Failed to process Duitku callback', [
                'merchant_order_id' => $merchantOrderId,
                'error' => $exception->getMessage(),
                'payload' => $data,
            ]);

            return response()->json(['message' => 'Internal Server Error'], 500);
        }

        return response()->json(['message' => 'Success']);
    }

    /**
     * Cari atau inisialisasi Virtual Account dari nomor VA statis (prefix bank + id/nis santri).
     */
    private function resolveVirtualAccountFromVaNumber(string $vaNo, string $bin = ''): ?VirtualAccount
    {
        foreach (DuitkuService::BANK_PREFIXES as $code => $prefix) {
            if (Str::startsWith($vaNo, $prefix) || ($bin !== '' && $bin === $prefix)) {
                $prefixLen = strlen($prefix);
                $identifier = ltrim(substr($vaNo, $prefixLen), '0');
                if (is_numeric($identifier) && (int) $identifier > 0) {
                    $student = Student::find((int) $identifier)
                        ?? Student::where('nis', $identifier)->first();

                    if ($student !== null) {
                        return $this->duitku->getOrCreateFixedVirtualAccount($student, $code);
                    }
                }
                break;
            }
        }

        return null;
    }

    /**
     * @return array<string, mixed>
     */
    private function virtualAccountPayload(VirtualAccount $virtualAccount): array
    {
        $student = $virtualAccount->student;

        return [
            'id' => $virtualAccount->id,
            'student_id' => $virtualAccount->student_id,
            'student_name' => $student?->name,
            'student_nis' => $student?->nis,
            'account_name' => 'SEMESTA '.strtoupper((string) ($student?->name ?? 'SANTRI')),
            'provider' => $virtualAccount->provider,
            'payment_method' => $virtualAccount->payment_code,
            'bank_name' => $virtualAccount->bank_name,
            'account_number' => $virtualAccount->account_number,
            'merchant_order_id' => $virtualAccount->merchant_order_id,
            'reference' => $virtualAccount->provider_reference,
            'amount' => (float) $virtualAccount->amount,
            'status' => $virtualAccount->status,
            'is_static' => (bool) $virtualAccount->is_static,
            'is_open_amount' => (bool) $virtualAccount->is_static,
            'payment_url' => $virtualAccount->payment_url,
            'expires_at' => $virtualAccount->expires_at?->toIso8601String(),
            'created_at' => $virtualAccount->created_at?->toIso8601String(),
        ];
    }
}
