<?php

namespace App\Http\Controllers\Api\v1;

use App\Exceptions\Domain\IdempotencyConflictException;
use App\Exceptions\Domain\InsufficientBalanceException;
use App\Exceptions\Domain\WalletNotActiveException;
use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Services\WalletService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class StudentTransferController extends Controller
{
    public function __construct(private readonly WalletService $wallets) {}

    public function recipients(Request $request): JsonResponse
    {
        $sender = $this->authenticatedStudent($request);
        $validated = $request->validate([
            'q' => ['nullable', 'string', 'max:80'],
            'limit' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ]);
        $query = trim((string) ($validated['q'] ?? ''));

        $recipients = Student::query()
            ->select(['id', 'name', 'nis', 'class_id'])
            ->with('klass:id,name')
            ->where('id', '!=', $sender->id)
            ->where('status', 'active')
            ->where('wallet_status', 'active')
            ->when($query !== '', function ($students) use ($query): void {
                $students->where(function ($matches) use ($query): void {
                    $matches->where('name', 'like', '%'.$query.'%')
                        ->orWhere('nis', 'like', '%'.$query.'%')
                        ->orWhere('username', 'like', '%'.$query.'%');
                });
            })
            ->orderBy('name')
            ->limit((int) ($validated['limit'] ?? 30))
            ->get();

        return response()->json([
            'data' => $recipients->map(fn (Student $student): array => [
                'id' => $student->id,
                'name' => $student->name,
                'nis' => $student->nis,
                'class' => $student->klass?->name,
            ])->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $sender = $this->authenticatedStudent($request);
        $validated = $request->validate([
            'recipient_id' => ['required', 'integer', 'exists:students,id'],
            'amount' => ['required', 'numeric', 'min:1', 'max:999999999999'],
            'note' => ['nullable', 'string', 'max:50'],
            'idempotency_key' => ['required', 'uuid'],
        ]);

        $recipient = Student::query()->findOrFail($validated['recipient_id']);
        if ($recipient->is($sender)) {
            throw ValidationException::withMessages([
                'recipient_id' => ['Tidak dapat transfer ke akun sendiri.'],
            ]);
        }

        try {
            $transactions = $this->wallets->transferBetweenStudents(
                sender: $sender,
                recipient: $recipient,
                amount: (float) $validated['amount'],
                note: $validated['note'] ?? null,
                idempotencyKey: $validated['idempotency_key'],
            );
        } catch (InsufficientBalanceException|WalletNotActiveException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        } catch (IdempotencyConflictException $exception) {
            return response()->json(['message' => $exception->getMessage()], 409);
        }

        $senderTransaction = $transactions['sender'];

        return response()->json([
            'transfer' => [
                'transaction_id' => $senderTransaction->id,
                'recipient_transaction_id' => $transactions['recipient']->id,
                'recipient_id' => $recipient->id,
                'recipient_name' => $recipient->name,
                'recipient_nis' => $recipient->nis,
                'amount' => (float) $senderTransaction->amount,
                'balance_after' => (float) $senderTransaction->balance_after,
                'status' => $senderTransaction->status,
                'note' => $senderTransaction->note,
                'created_at' => $senderTransaction->created_at?->toIso8601String(),
            ],
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
}
