<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\v1\TopupRequest;
use App\Models\Student;
use App\Models\User;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;

class TopupController extends Controller
{
    public function __construct(private readonly WalletService $wallets) {}

    public function store(TopupRequest $request): JsonResponse
    {
        $data = $request->validated();

        $student = Student::findOrFail($data['student_id']);
        $receivedBy = $data['received_by'] ?? null;
        $actor = $receivedBy !== null ? User::find($receivedBy) : $request->user();

        $tx = $this->wallets->topup(
            student: $student,
            amount: (float) $data['amount'],
            method: $data['method'],
            reference: $data['reference'] ?? null,
            receivedBy: $actor,
            idempotencyKey: $data['idempotency_key'],
        );

        return response()->json([
            'transaction_id' => $tx->id,
            'type' => 'topup',
            'balance_after' => (float) $tx->balance_after,
            'student' => [
                'id' => $student->id,
                'name' => $student->name,
            ],
        ], 201);
    }
}
