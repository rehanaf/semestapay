<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Merchant;
use App\Models\Student;
use App\Services\WalletService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    private const ADMIN_ROLES = ['super-admin', 'admin', 'finance'];

    public function __construct(private readonly WalletService $wallets) {}

    public function auditLogs(Request $request): JsonResponse
    {
        $this->authorizeAdmin($request);

        $query = AuditLog::with('user')->latest('created_at');

        if ($request->filled('action')) {
            $query->where('action', 'like', '%'.$request->query('action').'%');
        }

        $logs = $query->limit(min((int) $request->query('limit', 100), 200))->get();

        return response()->json([
            'data' => $logs->map(fn (AuditLog $log) => [
                'id' => $log->id,
                'action' => $log->action,
                'actor' => $log->user?->name ?? 'Sistem',
                'actor_email' => $log->user?->email,
                'auditable_type' => $log->auditable_type,
                'auditable_id' => $log->auditable_id,
                'meta' => $log->meta,
                'ip_address' => $log->ip_address,
                'created_at' => $log->created_at?->toISOString(),
            ]),
        ]);
    }

    public function setStudentBalance(Request $request, Student $student): JsonResponse
    {
        $user = $this->authorizeAdmin($request);

        $validated = $request->validate([
            'balance' => 'required|numeric|min:0',
            'note' => 'nullable|string|max:255',
        ]);

        $oldBalance = (float) $student->balance;
        $newBalance = (float) $validated['balance'];

        $transaction = $this->wallets->adjustStudentBalance(
            student: $student,
            newBalance: $newBalance,
            actor: $user,
            note: $validated['note'] ?? 'Penyesuaian saldo oleh admin',
        );

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'student.balance_updated',
            'auditable_type' => Student::class,
            'auditable_id' => (string) $student->id,
            'meta' => [
                'old_balance' => $oldBalance,
                'new_balance' => $newBalance,
                'transaction_id' => $transaction?->id,
                'note' => $validated['note'] ?? null,
            ],
            'ip_address' => $request->ip(),
        ]);

        $student->refresh();

        return response()->json([
            'message' => 'Saldo santri berhasil diperbarui.',
            'student' => [
                'id' => $student->id,
                'nis' => $student->nis,
                'name' => $student->name,
                'balance' => (float) $student->balance,
            ],
            'transaction_id' => $transaction?->id,
        ]);
    }

    public function setMerchantBalance(Request $request, Merchant $merchant): JsonResponse
    {
        $user = $this->authorizeAdmin($request);

        $validated = $request->validate([
            'balance' => 'required|numeric|min:0',
            'note' => 'nullable|string|max:255',
        ]);

        $oldBalance = (float) $merchant->balance;
        $newBalance = (float) $validated['balance'];

        $this->wallets->setMerchantBalance($merchant, $newBalance);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'merchant.balance_updated',
            'auditable_type' => Merchant::class,
            'auditable_id' => (string) $merchant->id,
            'meta' => [
                'old_balance' => $oldBalance,
                'new_balance' => (float) $merchant->fresh()->balance,
                'note' => $validated['note'] ?? null,
            ],
            'ip_address' => $request->ip(),
        ]);

        return response()->json([
            'message' => 'Saldo merchant berhasil diperbarui.',
            'merchant' => [
                'id' => $merchant->id,
                'name' => $merchant->name,
                'balance' => (float) $merchant->fresh()->balance,
            ],
        ]);
    }

    private function authorizeAdmin(Request $request)
    {
        $user = $request->user();

        if ($user === null || ! $user->hasAnyRole(self::ADMIN_ROLES)) {
            throw new AuthorizationException('Akses ditolak.');
        }

        return $user;
    }
}
