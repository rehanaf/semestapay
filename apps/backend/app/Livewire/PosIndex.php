<?php

namespace App\Livewire;

use App\Models\Cashier;
use App\Models\DailyUsage;
use App\Models\Item;
use App\Models\Outlet;
use App\Models\Student;
use App\Services\CashierShiftService;
use App\Services\WalletService;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;
use Livewire\Attributes\Computed;
use Livewire\Component;
use Throwable;

class PosIndex extends Component
{
    /** UID yang dibaca dari scanner / kartu. */
    public string $cardUid = '';

    public ?int $studentId = null;

    public ?int $outletId = null;

    public ?int $merchantId = null;

    public string $pin = '';

    public $manualAmount = 0;

    /** @var array<int, int> item_id => qty */
    public array $cart = [];

    public bool $shiftOpen = false;

    /** Modal profil siswa (saldo + PIN + konfirmasi). */
    public bool $showStudentModal = false;

    public ?string $error = null;

    public ?string $notice = null;

    public ?string $lastTransactionId = null;

    public ?float $lastBalanceAfter = null;

    public function mount(): void
    {
        $cashier = Cashier::with('outlet')->where('user_id', auth()->id())->first();

        if ($cashier?->outlet !== null) {
            $this->outletId = $cashier->outlet->id;
            $this->merchantId = $cashier->outlet->merchant_id;
            $this->refreshShift();
        } else {
            $this->notice = 'Akun ini belum terhubung ke outlet mana pun.';
        }
    }

    public function refreshShift(): void
    {
        $outlet = $this->outlet();

        $this->shiftOpen = $outlet !== null
            && app(CashierShiftService::class)->current($outlet) !== null;
    }

    public function openShift(): void
    {
        $outlet = $this->outlet();

        if ($outlet === null) {
            $this->error = 'Outlet tidak ditemukan.';

            return;
        }

        try {
            app(CashierShiftService::class)->open($outlet, auth()->user());
            $this->notice = null;
            $this->error = null;
            $this->refreshShift();
        } catch (Throwable $e) {
            $this->error = $e->getMessage();
        }
    }

    public function closeShift(): void
    {
        $shift = app(CashierShiftService::class)->current($this->outlet());

        if ($shift === null) {
            $this->error = 'Tidak ada shift yang terbuka.';

            return;
        }

        try {
            app(CashierShiftService::class)->close($shift, auth()->user());
            $this->refreshShift();
        } catch (Throwable $e) {
            $this->error = $e->getMessage();
        }
    }

    #[Computed]
    public function outlet(): ?Outlet
    {
        return $this->outletId === null ? null : Outlet::with('merchant')->find($this->outletId);
    }

    #[Computed]
    public function student(): ?Student
    {
        return $this->studentId === null ? null : Student::find($this->studentId);
    }

    #[Computed]
    public function items(): Collection
    {
        if ($this->merchantId === null) {
            return collect();
        }

        return Item::where('merchant_id', $this->merchantId)
            ->where('status', 'active')
            ->orderBy('name')
            ->get();
    }

    /** @return Collection<int, array{item: Item, quantity: int}> */
    #[Computed]
    public function cartLines(): Collection
    {
        $items = $this->items()->keyBy('id');

        return collect($this->cart)
            ->filter(fn (int $qty) => $qty > 0)
            ->map(fn (int $qty, $id) => ['item' => $items->get((int) $id), 'quantity' => $qty])
            ->values()
            ->filter(fn (array $row) => $row['item'] !== null);
    }

    #[Computed]
    public function dailyUsed(): float
    {
        if ($this->studentId === null) {
            return 0.0;
        }

        return (float) (DailyUsage::where('student_id', $this->studentId)
            ->where('usage_date', today())
            ->value('total_used') ?? 0);
    }

    public function total(): float
    {
        if ($this->cart !== []) {
            return (float) $this->cartLines()->sum(
                fn (array $row) => (float) $row['item']->price * $row['quantity'],
            );
        }

        $manual = (float) ($this->manualAmount ?? 0);

        return $manual;
    }

    public function scanCard(): void
    {
        $uid = trim($this->cardUid);

        if ($uid === '') {
            return;
        }

        $this->studentId = null;
        $this->pin = '';
        $this->error = null;
        $this->notice = null;
        $this->showStudentModal = false;
        $this->lastTransactionId = null;
        $this->lastBalanceAfter = null;

        $student = Student::where('card_uid', $uid)->first();

        if ($student === null) {
            $this->error = 'Kartu tidak dikenal.';
        } elseif ($student->card_status !== 'active') {
            $this->error = 'Kartu tidak aktif.';
        } elseif ($student->status !== 'active') {
            $this->error = 'Santri tidak aktif.';
        } elseif ($student->wallet_status !== 'active') {
            $this->error = 'Wallet tidak aktif.';
        } else {
            $this->studentId = $student->id;
            $this->showStudentModal = true;
        }

        $this->cardUid = '';
        $this->dispatch('pos-scanned');
    }

    public function closeStudentModal(): void
    {
        $this->showStudentModal = false;
        $this->pin = '';
        $this->error = null;
    }

    public function addItem(int $itemId): void
    {
        $this->cart[$itemId] = ($this->cart[$itemId] ?? 0) + 1;
    }

    public function incrementItem(int $itemId): void
    {
        $this->addItem($itemId);
    }

    public function decrementItem(int $itemId): void
    {
        $current = ($this->cart[$itemId] ?? 0) - 1;

        if ($current <= 0) {
            unset($this->cart[$itemId]);
        } else {
            $this->cart[$itemId] = $current;
        }
    }

    public function clearCart(): void
    {
        $this->cart = [];
    }

    public function addManual(int $amount): void
    {
        $this->manualAmount = max(0, ((int) ($this->manualAmount ?? 0)) + $amount);
    }

    public function pay(): void
    {
        $this->error = null;
        $this->notice = null;

        /** @var Student|null $student */
        $student = $this->student();

        if ($student === null) {
            $this->error = 'Scan kartu santri terlebih dahulu.';

            return;
        }

        $outlet = $this->outlet();

        if ($outlet === null) {
            $this->error = 'Outlet tidak ditemukan.';

            return;
        }

        $shift = app(CashierShiftService::class)->current($outlet);

        if ($shift === null) {
            $this->error = 'Shift belum dibuka.';

            return;
        }

        $total = $this->total();

        if ($total <= 0 || ! is_numeric($total)) {
            $this->error = 'Nominal harus lebih dari 0.';

            return;
        }

        if ($student->hasPin() && ! $this->verifyPin($student)) {
            return;
        }

        try {
            $tx = app(WalletService::class)->pay(
                student: $student,
                amount: $total,
                outlet: $outlet,
                shift: $shift,
                actor: auth()->user(),
                note: $this->noteFromCart(),
                idempotencyKey: (string) Str::uuid(),
            );
        } catch (Throwable $e) {
            $this->error = $e->getMessage();
            $this->dispatch('pos-error');

            return;
        }

        if ($this->cart !== []) {
            $tx->items()->attach($this->cartLines()->mapWithKeys(
                fn (array $row) => [
                    $row['item']->id => [
                        'quantity' => $row['quantity'],
                        'price' => (float) $row['item']->price,
                    ],
                ],
            )->all());
        }

        $transactionId = $tx->id;
        $balanceAfter = (float) $tx->balance_after;

        $this->resetOrder();
        $this->showStudentModal = false;
        $this->lastTransactionId = $transactionId;
        $this->lastBalanceAfter = $balanceAfter;
        $this->dispatch('pos-success', ['id' => $transactionId]);
    }

    private function verifyPin(Student $student): bool
    {
        if ($this->pin === '' || ! $student->verifyPin($this->pin)) {
            $this->error = 'PIN salah.';

            return false;
        }

        return true;
    }

    private function noteFromCart(): ?string
    {
        if ($this->cart === []) {
            return null;
        }

        $names = $this->cartLines()->map(
            fn (array $row) => $row['quantity'] > 1
                ? "{$row['item']->name} x{$row['quantity']}"
                : $row['item']->name,
        );

        return Str::limit($names->join(', '), 255);
    }

    private function resetOrder(): void
    {
        $this->pin = '';
        $this->cart = [];
        $this->manualAmount = 0;
        $this->lastTransactionId = null;
        $this->lastBalanceAfter = null;
    }

    public function render()
    {
        return view('livewire.pos-index');
    }
}
