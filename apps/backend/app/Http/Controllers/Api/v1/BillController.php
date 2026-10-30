<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\v1\PayBillRequest;
use App\Models\Bill;
use App\Models\Student;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BillController extends Controller
{
    public function __construct(private readonly WalletService $wallets) {}

    /**
     * GET /api/v1/bills?student_id=&status=
     */
    public function index(Request $request): JsonResponse
    {
        $studentId = (int) $request->integer('student_id');

        if ($studentId < 1 || Student::whereKey($studentId)->doesntExist()) {
            return response()->json([
                'message' => 'student_id wajib dan harus valid.',
                'code' => 'STUDENT_NOT_FOUND',
            ], 422);
        }

        $query = Bill::where('student_id', $studentId);

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $bills = $query->orderByDesc('due_date')->get();

        return response()->json([
            'data' => $bills->map(fn (Bill $bill) => [
                'id' => $bill->id,
                'type' => $bill->type,
                'period' => $bill->period,
                'description' => $bill->description,
                'amount' => (float) $bill->amount,
                'paid_amount' => (float) $bill->paid_amount,
                'due_date' => $bill->due_date,
                'status' => $bill->status,
            ]),
        ]);
    }

    /**
     * POST /api/v1/bills/{bill}/pay — bayar tagihan dari saldo dompet.
     */
    public function pay(Bill $bill, PayBillRequest $request): JsonResponse
    {
        $tx = $this->wallets->payBill(
            bill: $bill,
            actor: $request->user(),
            idempotencyKey: $request->validated('idempotency_key'),
        );

        $bill->refresh();

        return response()->json([
            'transaction_id' => $tx->id,
            'bill' => [
                'id' => $bill->id,
                'status' => $bill->status,
                'paid_amount' => (float) $bill->paid_amount,
            ],
            'balance_after' => (float) $tx->balance_after,
        ], 201);
    }
}
