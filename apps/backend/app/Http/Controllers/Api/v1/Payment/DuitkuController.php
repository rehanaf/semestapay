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
use Ramsey\Uuid\Uuid;
use Throwable;

class DuitkuController extends Controller
{
    public function __construct(
        private readonly DuitkuService $duitku,
        private readonly WalletService $wallets,
    ) {}

    /**
     * Ambil VA aktif milik santri yang sedang login, atau buat yang baru.
     * Digunakan oleh aplikasi mobile siswa untuk halaman Top Up.
     */
    public function studentVa(Request $request): JsonResponse
    {
        $student = $request->user();

        if (! $student instanceof Student) {
            throw new AuthorizationException('Akses khusus aplikasi siswa.');
        }

        $amount = (float) $request->input('amount', 10000);
        $paymentMethod = (string) $request->input('payment_method', '');

        // Cari VA statis atau VA pending aktif milik student ini
        $query = VirtualAccount::query()
            ->where('provider', DuitkuService::PROVIDER)
            ->where('student_id', $student->id)
            ->where(function ($q) {
                $q->where('is_static', true)
                    ->orWhere(function ($sub) {
                        $sub->where('status', VirtualAccountStatus::Pending->value)
                            ->where('expires_at', '>', now());
                    });
            });

        if ($paymentMethod !== '') {
            $query->where('payment_code', strtoupper($paymentMethod));
        }

        $existing = $query->latest('created_at')->first();

        if ($existing !== null) {
            return response()->json([
                'message' => 'Virtual Account statis santri aktif.',
                'virtual_account' => $this->virtualAccountPayload($existing),
                'is_new' => false,
            ]);
        }

        // Tidak ada VA aktif — buat VA statis baru
        try {
            $virtualAccount = $this->duitku->createVirtualAccount(
                student: $student,
                amount: $amount > 0 ? $amount : 10000,
                paymentMethod: $paymentMethod !== '' ? $paymentMethod : null,
                isStatic: true,
            );
        } catch (DuitkuException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Virtual account statis santri berhasil dibuat.',
            'virtual_account' => $this->virtualAccountPayload($virtualAccount),
            'is_new' => true,
        ], 201);
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
        $vaNumber = (string) ($data['vaNumber'] ?? '');

        $virtualAccount = VirtualAccount::query()
            ->where('provider', DuitkuService::PROVIDER)
            ->where(function ($q) use ($merchantOrderId, $vaNumber) {
                $q->where('merchant_order_id', $merchantOrderId);
                if ($vaNumber !== '') {
                    $q->orWhere('account_number', $vaNumber);
                }
            })
            ->first();

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
        ];
    }
}
