<?php

namespace Tests\Feature;

use App\Enums\ShiftStatus;
use App\Exceptions\Domain\DailyLimitExceededException;
use App\Exceptions\Domain\IdempotencyConflictException;
use App\Exceptions\Domain\InsufficientBalanceException;
use App\Exceptions\Domain\ShiftNotOpenException;
use App\Models\Bill;
use App\Models\CashierShift;
use App\Models\DailyUsage;
use App\Models\LedgerEntry;
use App\Models\Merchant;
use App\Models\Outlet;
use App\Models\Student;
use App\Models\Transaction;
use App\Models\User;
use App\Services\CashierShiftService;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class WalletServiceTest extends TestCase
{
    use RefreshDatabase;

    private WalletService $wallets;

    private CashierShiftService $shifts;

    protected function setUp(): void
    {
        parent::setUp();

        $this->wallets = app(WalletService::class);
        $this->shifts = app(CashierShiftService::class);
    }

    private function makeStudent(float $balance = 100000): Student
    {
        return Student::factory()->create([
            'balance' => $balance,
            'card_uid' => 'CARD-TEST-'.substr(uniqid(), -8),
        ]);
    }

    private function makeOpenOutlet(): array
    {
        $merchant = Merchant::factory()->create();
        $outlet = Outlet::factory()->create(['merchant_id' => $merchant->id]);
        $cashier = User::factory()->create();
        $shift = $this->shifts->open($outlet, $cashier);

        return [$outlet, $shift, $cashier];
    }

    public function test_topup_increases_balance_and_records_double_entry(): void
    {
        $student = $this->makeStudent(balance: 0);

        $tx = $this->wallets->topup($student, 50000, 'cash', null, null, (string) Str::uuid());

        $this->assertSame('topup', $tx->type);
        $this->assertSame(50000.0, (float) $student->refresh()->balance);
        $this->assertSame(2, LedgerEntry::where('transaction_id', $tx->id)->count());
        // debit == credit
        $net = LedgerEntry::where('transaction_id', $tx->id)->get()
            ->sum(fn (LedgerEntry $e) => $e->direction === 'debit' ? $e->amount : -$e->amount);
        $this->assertSame(0.0, (float) $net);
    }

    public function test_topup_is_idempotent_with_same_key(): void
    {
        $student = $this->makeStudent(balance: 0);
        $key = (string) Str::uuid();

        $first = $this->wallets->topup($student, 50000, 'cash', idempotencyKey: $key);
        $second = $this->wallets->topup($student, 50000, 'cash', idempotencyKey: $key);

        $this->assertSame($first->id, $second->id);
        $this->assertSame(50000.0, (float) $student->refresh()->balance);
        $this->assertSame(1, Transaction::where('idempotency_key', $key)->count());
    }

    public function test_payment_deducts_balance_and_increments_daily_usage(): void
    {
        $student = $this->makeStudent(balance: 100000);
        [$outlet, $shift, $cashier] = $this->makeOpenOutlet();

        $tx = $this->wallets->pay($student, 10000, $outlet, $shift, $cashier, 'nasi goreng');

        $this->assertSame('payment', $tx->type);
        $this->assertSame(90000.0, (float) $student->refresh()->balance);
        // Per-merchant usage
        $merchantUsage = DailyUsage::where('student_id', $student->id)
            ->where('merchant_id', $outlet->merchant_id)
            ->where('usage_date', today())
            ->first();
        $this->assertSame(10000.0, (float) $merchantUsage->total_used);
        // Global usage (merchant_id = NULL)
        $globalUsage = DailyUsage::where('student_id', $student->id)
            ->whereNull('merchant_id')
            ->where('usage_date', today())
            ->first();
        $this->assertSame(10000.0, (float) $globalUsage->total_used);
        $this->assertSame($shift->id, $tx->cashier_shift_id);
    }

    public function test_payment_rejects_when_shift_not_open(): void
    {
        $student = $this->makeStudent(balance: 100000);
        $merchant = Merchant::factory()->create();
        $outlet = Outlet::factory()->create(['merchant_id' => $merchant->id]);
        $shift = new CashierShift(['outlet_id' => $outlet->id, 'status' => ShiftStatus::Closed->value]);

        $this->expectException(ShiftNotOpenException::class);

        $this->wallets->pay($student, 10000, $outlet, $shift, null);
    }

    public function test_payment_rejects_insufficient_balance(): void
    {
        $student = $this->makeStudent(balance: 5000);
        [$outlet, $shift] = $this->makeOpenOutlet();

        $this->expectException(InsufficientBalanceException::class);

        try {
            $this->wallets->pay($student, 10000, $outlet, $shift);
        } finally {
            $this->assertSame(5000.0, (float) $student->refresh()->balance);
        }
    }

    public function test_payment_rejects_when_exceeding_daily_limit(): void
    {
        $student = $this->makeStudent(balance: 100000);
        $student->update(['daily_limit' => 15000]);
        [$outlet, $shift] = $this->makeOpenOutlet();

        $this->wallets->pay($student, 10000, $outlet, $shift);

        $this->expectException(DailyLimitExceededException::class);

        $this->wallets->pay($student, 10000, $outlet, $shift);
    }

    public function test_bill_payment_deducts_balance_and_marks_bill_paid(): void
    {
        $student = $this->makeStudent(balance: 500000);
        $bill = Bill::factory()->create(['student_id' => $student->id, 'amount' => 300000]);

        $tx = $this->wallets->payBill($bill);

        $this->assertSame('bill_payment', $tx->type);
        $this->assertSame(200000.0, (float) $student->refresh()->balance);
        $this->assertSame('paid', $bill->refresh()->status);
        $this->assertSame(300000.0, (float) $bill->paid_amount);
    }

    public function test_reversal_restores_balance_and_marks_original_reversed(): void
    {
        $student = $this->makeStudent(balance: 100000);
        [$outlet, $shift, $cashier] = $this->makeOpenOutlet();

        $payment = $this->wallets->pay($student, 20000, $outlet, $shift, $cashier);
        $this->assertSame(80000.0, (float) $student->refresh()->balance);

        $reversal = $this->wallets->reverse($payment, $cashier, 'salah harga');

        $this->assertSame('reversal', $reversal->type);
        $this->assertSame(100000.0, (float) $student->refresh()->balance);
        $this->assertSame('reversed', $payment->refresh()->status);

        $this->expectException(IdempotencyConflictException::class);
        $this->wallets->reverse($payment, $cashier);
    }
}
