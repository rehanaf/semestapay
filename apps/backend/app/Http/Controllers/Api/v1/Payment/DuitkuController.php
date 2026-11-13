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

        // Cari VA yang masih pending dan belum expired untuk student ini
        $existing = VirtualAccount::query()
            ->where('provider', DuitkuService::PROVIDER)
            ->where('student_id', $student->id)
            ->where('status', VirtualAccountStatus::Pending->value)
            ->where('expires_at', '>', now())
            ->when($paymentMethod !== '', fn ($q) => $q->where('payment_code', strtoupper($paymentMethod)))
            ->latest('created_at')
            ->first();

        if ($existing !== null) {
            return response()->json([
                'message' => 'VA aktif ditemukan.',
                'virtual_account' => $this->virtualAccountPayload($existing),
                'is_new' => false,
            ]);
        }

        // Tidak ada VA aktif — buat baru
        try {
            $virtualAccount = $this->duitku->createVirtualAccount(
                student: $student,
                amount: $amount,
                paymentMethod: $paymentMethod !== '' ? $paymentMethod : null,
            );
        } catch (DuitkuException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Virtual account berhasil dibuat.',
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

        $virtualAccount = VirtualAccount::query()
            ->where('provider', DuitkuService::PROVIDER)
            ->where('merchant_order_id', $merchantOrderId)
            ->first();

        if ($virtualAccount === null) {
            Log::warning('Duitku callback received for unknown order', [
                'merchant_order_id' => $merchantOrderId,
            ]);

            return response()->json(['message' => 'Order not found']);
        }

        if ($resultCode !== '00') {
            if (! $virtualAccount->isPaid()) {
                $virtualAccount->update([
                    'status' => VirtualAccountStatus::Failed->value,
                    'callback_payload' => $data,
                ]);
            }

            return response()->json(['message' => 'Callback received']);
        }

        $callbackAmount = (float) ($data['amount'] ?? 0);

        if (abs($callbackAmount - (float) $virtualAccount->amount) > 0.01) {
            Log::error('Duitku callback amount mismatch', [
                'merchant_order_id' => $merchantOrderId,
                'expected' => (float) $virtualAccount->amount,
                'received' => $callbackAmount,
            ]);

            return response()->json(['message' => 'Amount mismatch'], 422);
        }

        try {
            DB::transaction(function () use ($virtualAccount, $data, $merchantOrderId): void {
                $locked = VirtualAccount::query()
                    ->whereKey($virtualAccount->id)
                    ->lockForUpdate()
                    ->firstOrFail();

                if ($locked->isPaid()) {
                    return;
                }

                $this->wallets->topup(
                    student: $locked->student,
                    amount: (float) $locked->amount,
                    method: 'duitku_va',
                    reference: $merchantOrderId,
                    idempotencyKey: Uuid::uuid5(Uuid::NAMESPACE_URL, 'duitku:'.$merchantOrderId)->toString(),
                );

                $locked->update([
                    'status' => VirtualAccountStatus::Paid->value,
                    'paid_at' => now(),
                    'provider_reference' => $data['reference'] ?? $locked->provider_reference,
                    'callback_payload' => $data,
                ]);
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
        return [
            'id' => $virtualAccount->id,
            'student_id' => $virtualAccount->student_id,
            'provider' => $virtualAccount->provider,
            'payment_method' => $virtualAccount->payment_code,
            'bank_name' => $virtualAccount->bank_name,
            'account_number' => $virtualAccount->account_number,
            'merchant_order_id' => $virtualAccount->merchant_order_id,
            'reference' => $virtualAccount->provider_reference,
            'amount' => (float) $virtualAccount->amount,
            'status' => $virtualAccount->status,
            'payment_url' => $virtualAccount->payment_url,
            'expires_at' => $virtualAccount->expires_at?->toIso8601String(),
        ];
    }
}
