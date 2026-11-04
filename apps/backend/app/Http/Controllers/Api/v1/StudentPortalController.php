<?php

namespace App\Http\Controllers\Api\v1;

use App\Enums\TransactionType;
use App\Http\Controllers\Controller;
use App\Models\Bill;
use App\Models\DailyUsage;
use App\Models\Student;
use App\Models\Transaction;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentPortalController extends Controller
{
    /**
     * Ringkasan dompet & aktivitas untuk aplikasi SmPay Mobile.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $student = $this->authenticatedStudent($request);
        $student->load('klass');

        $dailyUsed = (float) (DailyUsage::where('student_id', $student->id)
            ->where('usage_date', today())
            ->value('total_used') ?? 0);

        $transactions = $student->transactions()
            ->with(['outlet.merchant'])
            ->latest('created_at')
            ->limit(10)
            ->get();

        $bills = $student->bills()
            ->orderByDesc('due_date')
            ->limit(10)
            ->get();

        return response()->json([
            'student' => $this->studentPayload($student),
            'daily_used' => $dailyUsed,
            'remaining_daily_limit' => $this->remainingDailyLimit($student, $dailyUsed),
            'recent_transactions' => $transactions->map(fn (Transaction $tx) => $this->transactionPayload($tx)),
            'bills' => $bills->map(fn (Bill $bill) => $this->billPayload($bill)),
        ]);
    }

    /**
     * Riwayat mutasi dompet santri.
     */
    public function mutations(Request $request): JsonResponse
    {
        $student = $this->authenticatedStudent($request);
        $limit = min((int) $request->integer('limit', 50), 100);

        $transactions = $student->transactions()
            ->with(['outlet.merchant'])
            ->latest('created_at')
            ->limit($limit)
            ->get();

        return response()->json([
            'data' => $transactions->map(fn (Transaction $tx) => $this->transactionPayload($tx)),
        ]);
    }

    /**
     * Tagihan santri (SPP, pondok, dll).
     */
    public function bills(Request $request): JsonResponse
    {
        $student = $this->authenticatedStudent($request);

        $bills = $student->bills()
            ->orderByDesc('due_date')
            ->get();

        return response()->json([
            'data' => $bills->map(fn (Bill $bill) => $this->billPayload($bill)),
        ]);
    }

    private function authenticatedStudent(Request $request): Student
    {
        $student = $request->user();

        if (! $student instanceof Student) {
            throw new AuthorizationException('Akses khusus aplikasi siswa.');
        }

        return $student;
    }

    /**
     * @return array<string, mixed>
     */
    private function studentPayload(Student $student): array
    {
        return [
            'id' => $student->id,
            'name' => $student->name,
            'nis' => $student->nis,
            'class' => $student->klass?->name,
            'card_uid' => $student->card_uid,
            'card_status' => $student->card_status,
            'status' => $student->status,
            'balance' => (float) $student->balance,
            'currency' => $student->currency,
            'wallet_status' => $student->wallet_status,
            'daily_limit' => (float) $student->daily_limit,
            'balance_updated_at' => $student->balance_updated_at,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function transactionPayload(Transaction $transaction): array
    {
        $isCredit = in_array($transaction->type, [
            TransactionType::Topup->value,
            TransactionType::Reversal->value,
            TransactionType::Adjustment->value,
        ], true);

        return [
            'id' => $transaction->id,
            'type' => $transaction->type,
            'direction' => $isCredit ? 'credit' : 'debit',
            'amount' => (float) $transaction->amount,
            'balance_after' => $transaction->balance_after === null ? null : (float) $transaction->balance_after,
            'status' => $transaction->status,
            'merchant' => $transaction->outlet?->merchant?->name,
            'outlet' => $transaction->outlet?->name,
            'note' => $transaction->note,
            'created_at' => $transaction->created_at?->toISOString(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function billPayload(Bill $bill): array
    {
        return [
            'id' => $bill->id,
            'type' => $bill->type,
            'period' => $bill->period,
            'description' => $bill->description,
            'amount' => (float) $bill->amount,
            'paid_amount' => (float) $bill->paid_amount,
            'due_date' => $bill->due_date?->toDateString(),
            'status' => $bill->status,
        ];
    }

    private function remainingDailyLimit(Student $student, float $dailyUsed): float
    {
        if ((float) $student->daily_limit <= 0) {
            return (float) $student->balance;
        }

        return max(0.0, (float) $student->daily_limit - $dailyUsed);
    }
}
