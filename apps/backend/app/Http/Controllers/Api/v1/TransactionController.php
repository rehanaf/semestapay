<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Transaction::with(['student', 'merchant', 'outlet'])
            ->latest('created_at');

        if ($type = $request->query('type')) {
            $query->where('type', $type);
        }

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        if ($merchantId = $request->query('merchant_id')) {
            $query->where('merchant_id', $merchantId);
        }

        $transactions = $query->limit(50)->get();

        return response()->json([
            'data' => $transactions->map(fn (Transaction $tx) => [
                'id' => $tx->id,
                'created_at' => $tx->created_at->toISOString(),
                'type' => $tx->type,
                'amount' => (float) $tx->amount,
                'status' => $tx->status,
                'student_name' => $tx->student?->name ?? 'Umum',
                'student_nis' => $tx->student?->nis,
                'merchant_name' => $tx->merchant?->name ?? 'Kantin Utama',
                'note' => $tx->note,
            ]),
        ]);
    }
}
