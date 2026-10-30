<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    /**
     * Saldo dompet santri — dibaca langsung dari kolom tersimpan.
     */
    public function show(Request $request, Student $student): JsonResponse
    {
        return response()->json([
            'wallet' => [
                'student_id' => $student->id,
                'balance' => (float) $student->balance,
                'currency' => $student->currency,
                'status' => $student->wallet_status,
                'balance_updated_at' => $student->balance_updated_at,
            ],
        ]);
    }

    /**
     * Riwayat mutasi dompet santri (descending).
     */
    public function mutations(Request $request, Student $student): JsonResponse
    {
        $limit = min((int) $request->integer('limit', 20), 100);

        $transactions = $student->transactions()
            ->with(['outlet.merchant'])
            ->latest('created_at')
            ->limit($limit)
            ->get();

        return response()->json([
            'data' => $transactions->map(fn ($tx) => [
                'id' => $tx->id,
                'type' => $tx->type,
                'amount' => (float) $tx->amount,
                'balance_after' => $tx->balance_after === null ? null : (float) $tx->balance_after,
                'status' => $tx->status,
                'merchant' => $tx->outlet?->merchant?->name,
                'outlet' => $tx->outlet?->name,
                'note' => $tx->note,
                'created_at' => $tx->created_at,
            ]),
        ]);
    }
}
