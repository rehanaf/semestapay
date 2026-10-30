<?php

namespace App\Http\Controllers\Api\v1;

use App\Enums\CardStatus;
use App\Exceptions\Domain\CardNotUsableException;
use App\Exceptions\Domain\ShiftNotOpenException;
use App\Exceptions\Domain\StudentNotActiveException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\v1\ReverseRequest;
use App\Http\Requests\Api\v1\TapPaymentRequest;
use App\Models\Item;
use App\Models\Outlet;
use App\Models\Student;
use App\Models\Transaction;
use App\Services\CashierShiftService;
use App\Services\WalletService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class PaymentController extends Controller
{
    private const MERCHANT_ROLES = ['super-admin', 'admin', 'finance', 'operator', 'cashier'];

    public function __construct(
        private readonly WalletService $wallets,
        private readonly CashierShiftService $shifts,
    ) {}

    /**
     * POST /api/v1/payments/tap — pembayaran gesek di outlet.
     */
    public function tap(TapPaymentRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->hasAnyRole(self::MERCHANT_ROLES)) {
            throw new AuthorizationException('Akses ditolak.');
        }

        $data = $request->validated();

        $student = Student::where('card_uid', $data['card_uid'])->firstOrFail();
        $outlet = Outlet::where('code', $data['outlet_code'])->firstOrFail();

        if ($student->card_status !== CardStatus::Active->value) {
            throw new CardNotUsableException('Kartu tidak aktif.');
        }

        if ($student->status !== 'active') {
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

        if ($shift === null) {
            throw new ShiftNotOpenException('Shift kasir outlet belum dibuka.');
        }

        [$total, $basket] = $this->resolveBasket($outlet, $data, (float) $data['amount']);

        $note = $data['note'] ?? null;

        if ($note === null && $basket !== []) {
            $note = collect($basket)->map(fn (array $row) => $row['quantity'] > 1
                ? "{$row['item']->name} x{$row['quantity']}"
                : $row['item']->name)->join(', ');
        }

        $tx = $this->wallets->pay(
            student: $student,
            amount: $total,
            outlet: $outlet,
            shift: $shift,
            actor: $user,
            note: $note,
            idempotencyKey: $data['idempotency_key'],
        );

        if ($basket !== []) {
            $tx->items()->attach(collect($basket)->mapWithKeys(fn (array $row) => [
                $row['item']->id => ['quantity' => $row['quantity'], 'price' => $row['price']],
            ])->all());
        }

        return response()->json([
            'transaction_id' => $tx->id,
            'card_uid' => $student->card_uid,
            'student' => [
                'id' => $student->id,
                'name' => $student->name,
                'nis' => $student->nis,
            ],
            'merchant' => $outlet->merchant->name,
            'outlet' => $outlet->name,
            'amount' => (float) $tx->amount,
            'balance_after' => (float) $tx->balance_after,
            'items' => array_map(fn (array $row) => [
                'item_id' => $row['item']->id,
                'name' => $row['item']->name,
                'quantity' => $row['quantity'],
                'price' => $row['price'],
            ], $basket),
            'created_at' => $tx->created_at,
        ], 201);
    }

    /**
     * Hitung total dari item yang valid (harga diambil dari DB) dan pastikan
     * cocok dengan nominal kiriman. Tanpa item, total = nominal yang dikirim.
     *
     * @return array{0: float, 1: array<int, array{item: Item, quantity: int, price: float}>}
     */
    private function resolveBasket(Outlet $outlet, array $data, float $amount): array
    {
        if (empty($data['items'])) {
            return [$amount, []];
        }

        $requested = [];

        foreach ($data['items'] as $line) {
            $id = (int) $line['item_id'];
            $requested[$id] = ($requested[$id] ?? 0) + (int) $line['quantity'];
        }

        $catalog = Item::whereIn('id', array_keys($requested))
            ->where('merchant_id', $outlet->merchant_id)
            ->where('status', 'active')
            ->get()
            ->keyBy('id');

        $total = 0.0;
        $basket = [];

        foreach ($requested as $id => $quantity) {
            $item = $catalog->get($id);

            if ($item === null) {
                throw ValidationException::withMessages(['items' => 'Item tidak tersedia di outlet ini.']);
            }

            $total += (float) $item->price * $quantity;
            $basket[] = ['item' => $item, 'quantity' => $quantity, 'price' => (float) $item->price];
        }

        if (abs($total - $amount) > 0.01) {
            throw ValidationException::withMessages(['amount' => 'Jumlah tidak sesuai dengan item.']);
        }

        return [$total, $basket];
    }

    /**
     * POST /api/v1/payments/{id}/reverse — balikkan transaksi.
     */
    public function reverse(Transaction $transaction, ReverseRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->hasAnyRole(self::MERCHANT_ROLES)) {
            throw new AuthorizationException('Akses ditolak.');
        }

        $tx = $this->wallets->reverse(
            original: $transaction,
            by: $user,
            reason: $request->validated('reason'),
            idempotencyKey: $request->validated('idempotency_key'),
        );

        return response()->json([
            'transaction_id' => $tx->id,
            'type' => 'reversal',
            'reversed_transaction_id' => $transaction->id,
            'amount' => (float) $tx->amount,
            'balance_after' => (float) $tx->balance_after,
        ]);
    }
}
