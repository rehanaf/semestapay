<?php

namespace App\Http\Controllers\Api\v1;

use App\Enums\CardStatus;
use App\Enums\StudentStatus;
use App\Enums\TransactionType;
use App\Exceptions\Domain\CardNotUsableException;
use App\Exceptions\Domain\StudentNotActiveException;
use App\Http\Controllers\Controller;
use App\Models\Merchant;
use App\Models\Outlet;
use App\Models\Student;
use App\Models\Transaction;
use App\Services\AvatarService;
use App\Services\CashierShiftService;
use App\Services\WalletService;
use Carbon\Carbon;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class MerchantController extends Controller
{
    private const MERCHANT_ROLES = ['super-admin', 'admin', 'finance', 'operator', 'cashier', 'merchant'];

    public function __construct(
        private readonly WalletService $wallets,
        private readonly CashierShiftService $shifts,
        private readonly AvatarService $avatars,
    ) {}

    /**
     * Ringkasan merchant + saldo pendapatan untuk aplikasi SmPay Merchant.
     */
    public function summary(Request $request): JsonResponse
    {
        $merchant = $this->resolveMerchant($request);

        if ($merchant === null) {
            return response()->json([
                'message' => 'Merchant belum tersedia.',
                'code' => 'MERCHANT_NOT_FOUND',
            ], 404);
        }

        $merchant->loadMissing('outlets');

        $todayIncome = (float) Transaction::where('merchant_id', $merchant->id)
            ->where('type', TransactionType::Payment->value)
            ->where('status', 'posted')
            ->whereDate('created_at', today())
            ->sum('amount');

        $todayCashOut = (float) Transaction::where('merchant_id', $merchant->id)
            ->where('type', TransactionType::CashOut->value)
            ->where('status', 'posted')
            ->whereDate('created_at', today())
            ->sum('amount');

        $lastTransactionAt = Transaction::where('merchant_id', $merchant->id)
            ->latest('created_at')
            ->value('created_at');

        return response()->json([
            'merchant' => array_merge($this->merchantPayload($merchant), [
                'balance' => (float) $merchant->balance,
                'today_income' => $todayIncome,
                'today_cash_out' => $todayCashOut,
                'transaction_count' => Transaction::where('merchant_id', $merchant->id)
                    ->where('type', TransactionType::Payment->value)
                    ->where('status', 'posted')
                    ->count(),
                'last_transaction_at' => $lastTransactionAt,
                'outlets' => $merchant->outlets->map(fn ($outlet) => [
                    'id' => $outlet->id,
                    'code' => $outlet->code,
                    'name' => $outlet->name,
                    'status' => $outlet->status,
                ]),
            ]),
        ]);
    }

    /**
     * Profil merchant untuk aplikasi merchant.
     */
    public function profile(Request $request): JsonResponse
    {
        $merchant = $this->resolveMerchant($request);

        if ($merchant === null) {
            return response()->json([
                'message' => 'Merchant belum tersedia.',
                'code' => 'MERCHANT_NOT_FOUND',
            ], 404);
        }

        $merchant->loadMissing('outlets');

        return response()->json([
            'merchant' => array_merge($this->merchantPayload($merchant), [
                'balance' => (float) $merchant->balance,
                'outlets' => $merchant->outlets->map(fn ($outlet) => [
                    'id' => $outlet->id,
                    'code' => $outlet->code,
                    'name' => $outlet->name,
                    'status' => $outlet->status,
                ]),
            ]),
            'user' => $request->user() ? [
                'id' => $request->user()->id,
                'name' => $request->user()->name,
                'username' => $request->user()->username,
                'email' => $request->user()->email,
                'phone' => $request->user()->phone,
                'avatar_url' => $request->user()->avatarUrl(),
            ] : null,
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $merchant = $this->resolveMerchant($request);

        if ($merchant === null) {
            return response()->json([
                'message' => 'Merchant belum tersedia.',
                'code' => 'MERCHANT_NOT_FOUND',
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:150',
            'type' => 'sometimes|nullable|string|max:50',
            'owner_name' => 'sometimes|nullable|string|max:150',
            'phone' => 'sometimes|nullable|string|max:30',
            'email' => 'sometimes|nullable|email|max:150',
            'address' => 'sometimes|nullable|string',
            'description' => 'sometimes|nullable|string',
            'logo' => 'sometimes|nullable|string',
        ]);

        if (array_key_exists('logo', $validated)) {
            $stored = $this->avatars->storeBase64($validated['logo'], 'merchants');
            if ($stored !== null) {
                $this->avatars->delete($merchant->logo_path);
                $validated['logo_path'] = $stored;
            }
            unset($validated['logo']);
        }

        $merchant->update($validated);

        $user = $request->user();
        if ($user !== null) {
            $userFields = $request->validate([
                'user_name' => 'sometimes|string|max:150',
                'username' => 'sometimes|nullable|string|max:60|unique:users,username,'.$user->id,
                'user_phone' => 'sometimes|nullable|string|max:30',
                'user_email' => 'sometimes|nullable|email|max:150|unique:users,email,'.$user->id,
                'avatar' => 'sometimes|nullable|string',
            ]);

            $userUpdate = [];
            if (isset($userFields['user_name'])) {
                $userUpdate['name'] = $userFields['user_name'];
            }
            if (array_key_exists('username', $userFields)) {
                $userUpdate['username'] = $userFields['username'];
            }
            if (array_key_exists('user_phone', $userFields)) {
                $userUpdate['phone'] = $userFields['user_phone'];
            }
            if (array_key_exists('user_email', $userFields)) {
                $userUpdate['email'] = $userFields['user_email'];
            }

            if (! empty($userFields['avatar'])) {
                $stored = $this->avatars->storeBase64($userFields['avatar'], 'users');
                if ($stored !== null) {
                    $this->avatars->delete($user->avatar_path);
                    $userUpdate['avatar_path'] = $stored;
                }
            }

            if ($userUpdate !== []) {
                $user->update($userUpdate);
            }
        }

        return response()->json([
            'message' => 'Profil merchant berhasil diperbarui.',
            'merchant' => array_merge($this->merchantPayload($merchant->fresh()), [
                'balance' => (float) $merchant->refresh()->balance,
            ]),
            'user' => $request->user()?->fresh() ? [
                'id' => $request->user()->id,
                'name' => $request->user()->name,
                'username' => $request->user()->username,
                'email' => $request->user()->email,
                'phone' => $request->user()->phone,
                'avatar_url' => $request->user()->avatarUrl(),
            ] : null,
        ]);
    }

    /**
     * Kas keluar: merchant menyerahkan uang tunai ke kartu santri.
     */
    public function cashOut(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user === null || ! $user->hasAnyRole(self::MERCHANT_ROLES)) {
            throw new AuthorizationException('Akses ditolak.');
        }

        $data = $request->validate([
            'card_uid' => 'required|string',
            'amount' => 'required|numeric|min:1',
            'pin' => 'nullable|string',
            'note' => 'nullable|string|max:255',
            'idempotency_key' => 'nullable|string|max:64',
            'outlet_code' => 'nullable|string|max:30',
        ]);

        $merchant = $this->resolveMerchant($request);

        if ($merchant === null) {
            return response()->json([
                'message' => 'Merchant belum tersedia.',
                'code' => 'MERCHANT_NOT_FOUND',
            ], 404);
        }

        $outlet = $this->resolveOutlet($merchant, $data['outlet_code'] ?? null);

        if ($outlet === null) {
            return response()->json([
                'message' => 'Outlet merchant belum tersedia.',
                'code' => 'OUTLET_NOT_FOUND',
            ], 404);
        }

        $student = Student::where('card_uid', $data['card_uid'])->first();

        if ($student === null) {
            return response()->json([
                'message' => 'Kartu tidak dikenal.',
                'code' => 'CARD_NOT_FOUND',
            ], 404);
        }

        if ($student->card_status !== CardStatus::Active->value) {
            throw new CardNotUsableException('Kartu tidak aktif.');
        }

        if ($student->status !== StudentStatus::Active->value) {
            throw new StudentNotActiveException('Santri tidak aktif.');
        }

        if ($student->hasPin()) {
            if (blank($data['pin'] ?? null)) {
                throw ValidationException::withMessages(['pin' => 'PIN wajib diisi.']);
            }

            if (! $student->verifyPin($data['pin'])) {
                throw ValidationException::withMessages(['pin' => 'PIN salah.']);
            }
        }

        $shift = $this->shifts->current($outlet);

        $tx = $this->wallets->cashOut(
            student: $student,
            amount: (float) $data['amount'],
            outlet: $outlet,
            actor: $user,
            note: $data['note'] ?? 'Kas keluar merchant',
            idempotencyKey: $data['idempotency_key'] ?? null,
            shift: $shift,
        );

        $merchant->refresh();

        return response()->json([
            'transaction_id' => $tx->id,
            'card_uid' => $student->card_uid,
            'student' => [
                'id' => $student->id,
                'name' => $student->name,
                'nis' => $student->nis,
            ],
            'merchant' => $merchant->name,
            'outlet' => $outlet->name,
            'amount' => (float) $tx->amount,
            'balance_after' => (float) $tx->balance_after,
            'merchant_balance_after' => (float) $merchant->balance,
            'created_at' => $tx->created_at,
        ], 201);
    }

    /**
     * Laporan transaksi merchant dengan filter harian/bulanan/rentang.
     */
    public function reports(Request $request): JsonResponse
    {
        $merchant = $this->resolveMerchant($request);

        if ($merchant === null) {
            return response()->json([
                'message' => 'Merchant belum tersedia.',
                'code' => 'MERCHANT_NOT_FOUND',
            ], 404);
        }

        $period = $request->query('period', 'day');

        try {
            [$start, $end] = match ($period) {
                'month' => $this->monthRange($request->query('month')),
                'range' => $this->rangeBounds($request->query('start'), $request->query('end')),
                default => $this->dayRange($request->query('date')),
            };
        } catch (\Throwable) {
            return response()->json([
                'message' => 'Format tanggal tidak valid.',
                'code' => 'INVALID_DATE',
            ], 422);
        }

        $transactions = Transaction::with(['student', 'outlet'])
            ->where('merchant_id', $merchant->id)
            ->whereIn('type', [TransactionType::Payment->value, TransactionType::CashOut->value])
            ->where('status', 'posted')
            ->whereBetween('created_at', [$start->copy()->startOfDay(), $end->copy()->endOfDay()])
            ->orderBy('created_at')
            ->get();

        $totalIncome = (float) $transactions
            ->where('type', TransactionType::Payment->value)
            ->sum('amount');
        $totalCashOut = (float) $transactions
            ->where('type', TransactionType::CashOut->value)
            ->sum('amount');

        $series = [];

        foreach ($transactions as $tx) {
            $key = $tx->created_at->toDateString();
            $series[$key] ??= [
                'date' => $key,
                'income' => 0.0,
                'cash_out' => 0.0,
                'count' => 0,
            ];
            $series[$key]['count']++;
            if ($tx->type === TransactionType::Payment->value) {
                $series[$key]['income'] += (float) $tx->amount;
            } else {
                $series[$key]['cash_out'] += (float) $tx->amount;
            }
        }

        ksort($series);

        return response()->json([
            'merchant' => [
                'id' => $merchant->id,
                'name' => $merchant->name,
                'balance' => (float) $merchant->balance,
            ],
            'period' => $period,
            'start' => $start->toDateString(),
            'end' => $end->toDateString(),
            'summary' => [
                'income' => $totalIncome,
                'cash_out' => $totalCashOut,
                'net' => $totalIncome - $totalCashOut,
                'transaction_count' => $transactions->count(),
            ],
            'series' => array_values($series),
            'transactions' => $transactions->map(fn (Transaction $tx) => [
                'id' => $tx->id,
                'created_at' => $tx->created_at->toISOString(),
                'type' => $tx->type,
                'amount' => (float) $tx->amount,
                'status' => $tx->status,
                'student_name' => $tx->student?->name ?? 'Pelanggan',
                'student_nis' => $tx->student?->nis,
                'outlet' => $tx->outlet?->name,
                'note' => $tx->note,
            ]),
        ]);
    }

    public function index(): JsonResponse
    {
        $merchants = Merchant::withCount(['items', 'outlets'])->get();

        return response()->json([
            'data' => $merchants->map(fn (Merchant $m) => [
                'id' => $m->id,
                'name' => $m->name,
                'type' => $m->type,
                'status' => $m->status,
                'owner_name' => $m->owner_name,
                'phone' => $m->phone,
                'email' => $m->email,
                'address' => $m->address,
                'balance' => (float) $m->balance,
                'logo_url' => $m->logoUrl(),
                'items_count' => $m->items_count,
                'outlets_count' => $m->outlets_count,
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:150',
            'type' => 'nullable|string|max:50',
            'status' => 'nullable|string|max:20',
            'owner_name' => 'nullable|string|max:150',
            'phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:150',
            'address' => 'nullable|string',
            'description' => 'nullable|string',
            'balance' => 'nullable|numeric|min:0',
        ]);

        $merchant = Merchant::create([
            'name' => $validated['name'],
            'type' => $validated['type'] ?? 'canteen',
            'status' => $validated['status'] ?? 'active',
            'owner_name' => $validated['owner_name'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'email' => $validated['email'] ?? null,
            'address' => $validated['address'] ?? null,
            'description' => $validated['description'] ?? null,
            'balance' => $validated['balance'] ?? 0,
        ]);

        return response()->json([
            'message' => 'Merchant berhasil didaftarkan.',
            'data' => $merchant,
        ], 201);
    }

    private function resolveMerchant(Request $request): ?Merchant
    {
        $user = $request->user();
        $merchant = null;

        if ($request->filled('merchant_id')) {
            $merchant = Merchant::with('outlets')->find($request->integer('merchant_id'));
        }

        if ($merchant === null && $user !== null) {
            if ($user->merchant_id) {
                $merchant = Merchant::with('outlets')->find($user->merchant_id);
            }

            if ($merchant === null) {
                $cashier = $user->cashiers()->with('outlet.merchant')->first();
                $merchant = $cashier?->outlet?->merchant;
            }
        }

        return $merchant ?? Merchant::with('outlets')->first();
    }

    private function resolveOutlet(Merchant $merchant, ?string $code): ?Outlet
    {
        $query = $merchant->outlets();

        if ($code !== null && $code !== '') {
            $outlet = (clone $query)->where('code', $code)->first();
            if ($outlet !== null) {
                return $outlet;
            }
        }

        return $merchant->outlets()->where('status', 'active')->first()
            ?? $merchant->outlets()->first();
    }

    /**
     * @return array<string, mixed>
     */
    private function merchantPayload(Merchant $merchant): array
    {
        return [
            'id' => $merchant->id,
            'code' => 'MRC-'.str_pad((string) $merchant->id, 4, '0', STR_PAD_LEFT),
            'name' => $merchant->name,
            'type' => $merchant->type,
            'owner_name' => $merchant->owner_name,
            'phone' => $merchant->phone,
            'email' => $merchant->email,
            'address' => $merchant->address,
            'description' => $merchant->description,
            'logo_url' => $merchant->logoUrl(),
            'status' => $merchant->status,
        ];
    }

    /**
     * @return array{0: Carbon, 1: Carbon}
     */
    private function dayRange(?string $date): array
    {
        $day = $date ? Carbon::parse($date) : now();

        return [$day->copy()->startOfDay(), $day->copy()->endOfDay()];
    }

    /**
     * @return array{0: Carbon, 1: Carbon}
     */
    private function monthRange(?string $month): array
    {
        $value = $month ? Carbon::createFromFormat('Y-m', $month) : now();

        return [$value->copy()->startOfMonth(), $value->copy()->endOfMonth()];
    }

    /**
     * @return array{0: Carbon, 1: Carbon}
     */
    private function rangeBounds(?string $start, ?string $end): array
    {
        $from = $start ? Carbon::parse($start) : now()->startOfMonth();
        $to = $end ? Carbon::parse($end) : now();

        if ($from->greaterThan($to)) {
            [$from, $to] = [$to, $from];
        }

        return [$from->copy()->startOfDay(), $to->copy()->endOfDay()];
    }
}
