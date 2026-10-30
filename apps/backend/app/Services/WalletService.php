<?php

namespace App\Services;

use App\Enums\BillStatus;
use App\Enums\LedgerDirection;
use App\Enums\ShiftStatus;
use App\Enums\TransactionStatus;
use App\Enums\TransactionType;
use App\Enums\WalletStatus;
use App\Exceptions\Domain\DailyLimitExceededException;
use App\Exceptions\Domain\IdempotencyConflictException;
use App\Exceptions\Domain\InsufficientBalanceException;
use App\Exceptions\Domain\ShiftNotOpenException;
use App\Exceptions\Domain\WalletNotActiveException;
use App\Models\AuditLog;
use App\Models\Bill;
use App\Models\BillPayment;
use App\Models\CashierShift;
use App\Models\DailyUsage;
use App\Models\LedgerEntry;
use App\Models\Outlet;
use App\Models\Student;
use App\Models\Topup;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class WalletService
{
    /**
     * Top-up saldo siswa (credit wallet).
     */
    public function topup(
        Student $student,
        float $amount,
        string $method = 'cash',
        ?string $reference = null,
        ?User $receivedBy = null,
        ?string $idempotencyKey = null,
    ): Transaction {
        $idempotencyKey ??= (string) Str::uuid();

        return $this->mutate($student, $idempotencyKey, function (Student $student) use (
            $amount, $method, $reference, $receivedBy, $idempotencyKey,
        ) {
            $this->credit($student, $amount);

            $tx = $this->newTransaction(TransactionType::Topup, $student, $amount, $idempotencyKey, [
                'actor_user_id' => $receivedBy?->id,
                'note' => $method,
            ]);
            $tx->save();

            Topup::create([
                'transaction_id' => $tx->id,
                'method' => $method,
                'reference' => $reference,
                'received_by' => $receivedBy?->id,
            ]);

            $this->ledger($tx, [
                ['account' => 'cash', 'direction' => LedgerDirection::Debit, 'with_balance' => false],
                ['account' => 'wallet', 'direction' => LedgerDirection::Credit, 'with_balance' => true],
            ]);

            return $tx;
        });
    }

    /**
     * Pembayaran gesek di outlet (debit wallet, ken limit harian).
     */
    public function pay(
        Student $student,
        float $amount,
        Outlet $outlet,
        CashierShift $shift,
        ?User $actor = null,
        ?string $note = null,
        ?string $idempotencyKey = null,
    ): Transaction {
        $idempotencyKey ??= (string) Str::uuid();

        if ($shift->outlet_id !== $outlet->id || $shift->status !== ShiftStatus::Open->value) {
            throw new ShiftNotOpenException('Shift kasir outlet belum dibuka.');
        }

        return $this->mutate($student, $idempotencyKey, function (Student $student) use (
            $amount, $outlet, $shift, $actor, $note, $idempotencyKey,
        ) {
            $this->charge($student, $amount, countDailyUsage: true);

            $tx = $this->newTransaction(TransactionType::Payment, $student, $amount, $idempotencyKey, [
                'outlet_id' => $outlet->id,
                'cashier_shift_id' => $shift->id,
                'merchant_id' => $outlet->merchant_id,
                'actor_user_id' => $actor?->id,
                'note' => $note,
            ]);
            $tx->save();

            $this->ledger($tx, [
                ['account' => 'wallet', 'direction' => LedgerDirection::Credit, 'with_balance' => true],
                ['account' => 'merchant_payable', 'direction' => LedgerDirection::Debit, 'with_balance' => false],
            ]);

            return $tx;
        });
    }

    /**
     * Bayar tagihan (debit wallet, tidak kena limit harian).
     */
    public function payBill(
        Bill $bill,
        ?User $actor = null,
        ?string $idempotencyKey = null,
    ): Transaction {
        $idempotencyKey ??= (string) Str::uuid();

        if (in_array($bill->status, [BillStatus::Paid->value, BillStatus::Void->value], true)) {
            throw new IdempotencyConflictException('Tagihan sudah lunas/dibatalkan.');
        }

        $remaining = (float) $bill->amount - (float) $bill->paid_amount;

        return $this->mutate($bill->student, $idempotencyKey, function (Student $student) use (
            $bill, $remaining, $actor, $idempotencyKey,
        ) {
            $this->charge($student, $remaining, countDailyUsage: false);

            $tx = $this->newTransaction(TransactionType::BillPayment, $student, $remaining, $idempotencyKey, [
                'reference_type' => 'bill',
                'reference_id' => (string) $bill->id,
                'actor_user_id' => $actor?->id,
            ]);
            $tx->save();

            $this->ledger($tx, [
                ['account' => 'wallet', 'direction' => LedgerDirection::Credit, 'with_balance' => true],
                ['account' => 'receivable_cleared', 'direction' => LedgerDirection::Debit, 'with_balance' => false],
            ]);

            BillPayment::create([
                'bill_id' => $bill->id,
                'transaction_id' => $tx->id,
                'amount' => $remaining,
            ]);

            $bill->paid_amount = (float) $bill->paid_amount + $remaining;
            $bill->status = (float) $bill->paid_amount >= (float) $bill->amount
                ? BillStatus::Paid->value
                : BillStatus::Partial->value;
            $bill->save();

            return $tx;
        });
    }

    /**
     * Balikkan transaksi (credit wallet) dan tandai transaksi asal reversed.
     */
    public function reverse(
        Transaction $original,
        ?User $by = null,
        ?string $reason = null,
        ?string $idempotencyKey = null,
    ): Transaction {
        $idempotencyKey ??= (string) Str::uuid();

        $original->load('student');

        if ($original->status === TransactionStatus::Reversed->value) {
            throw new IdempotencyConflictException('Transaksi sudah pernah di-reverse.');
        }

        $debitAccount = match ($original->type) {
            TransactionType::Payment->value => 'merchant_payable',
            TransactionType::BillPayment->value => 'receivable_cleared',
            default => 'cash',
        };

        return $this->mutate($original->student, $idempotencyKey, function (Student $student) use (
            $original, $by, $reason, $debitAccount, $idempotencyKey,
        ) {
            $this->credit($student, (float) $original->amount);

            $tx = $this->newTransaction(TransactionType::Reversal, $student, (float) $original->amount, $idempotencyKey, [
                'reference_type' => 'transaction',
                'reference_id' => $original->id,
                'actor_user_id' => $by?->id,
                'note' => $reason,
            ]);
            $tx->save();

            $this->ledger($tx, [
                ['account' => $debitAccount, 'direction' => LedgerDirection::Debit, 'with_balance' => false],
                ['account' => 'wallet', 'direction' => LedgerDirection::Credit, 'with_balance' => true],
            ]);

            $original->status = TransactionStatus::Reversed->value;
            $original->reversed_by = $tx->id;
            $original->save();

            return $tx;
        });
    }

    /**
     * Saldo siswa (langsung dari kolom tersimpan).
     */
    public function balance(Student $student): float
    {
        return (float) $student->balance;
    }

    /**
     * Inti mutasi: satu DB::transaction, row-lock baris santri, idempotensi.
     *
     * @param  callable(Student): Transaction  $callback
     */
    private function mutate(Student $student, string $idempotencyKey, callable $callback): Transaction
    {
        return DB::transaction(function () use ($student, $idempotencyKey, $callback) {
            $existing = Transaction::where('idempotency_key', $idempotencyKey)->first();

            if ($existing) {
                return $existing;
            }

            $locked = Student::whereKey($student->id)->lockForUpdate()->first();

            if ($locked === null || $locked->wallet_status !== WalletStatus::Active->value) {
                throw new WalletNotActiveException('Wallet siswa tidak aktif.');
            }

            $tx = $callback($locked);

            AuditLog::create([
                'user_id' => $tx->actor_user_id,
                'action' => 'transaction.created',
                'auditable_type' => Transaction::class,
                'auditable_id' => $tx->id,
                'meta' => [
                    'type' => $tx->type,
                    'amount' => $tx->amount,
                    'balance_after' => $tx->balance_after,
                ],
            ]);

            return $tx;
        });
    }

    /**
     * Kurangi saldo setelah cek cukup & (opsional) limit harian.
     */
    private function charge(Student $student, float $amount, bool $countDailyUsage): void
    {
        if ($amount <= 0) {
            throw new InsufficientBalanceException('Nominal harus lebih dari 0.');
        }

        if ($countDailyUsage) {
            $this->assertDailyLimit($student, $amount);
        }

        if ((float) $student->balance < $amount) {
            throw new InsufficientBalanceException('Saldo tidak mencukupi.');
        }

        $student->balance = (float) $student->balance - $amount;
        $this->persistStudent($student);

        if ($countDailyUsage) {
            $this->incrementDailyUsage($student->id, $amount);
        }
    }

    private function credit(Student $student, float $amount): void
    {
        $student->balance = (float) $student->balance + $amount;
        $this->persistStudent($student);
    }

    private function assertDailyLimit(Student $student, float $amount): void
    {
        $limit = (float) $student->daily_limit;

        if ($limit <= 0) {
            return;
        }

        $usedValue = DailyUsage::where('student_id', $student->id)
            ->where('usage_date', today())
            ->value('total_used');
        $used = $usedValue === null ? 0 : (float) $usedValue;

        if ($used + $amount > $limit) {
            throw new DailyLimitExceededException('Melebihi batas belanja harian.');
        }
    }

    private function incrementDailyUsage(int $studentId, float $amount): void
    {
        DailyUsage::firstOrCreate(
            ['student_id' => $studentId, 'usage_date' => today()],
            ['total_used' => 0],
        );

        DailyUsage::where('student_id', $studentId)
            ->where('usage_date', today())
            ->increment('total_used', $amount);
    }

    private function persistStudent(Student $student): void
    {
        $student->balance_updated_at = now();
        $student->version = (int) $student->version + 1;
        $student->save();
    }

    /**
     * @param  array<int, array{account: string, direction: LedgerDirection, with_balance?: bool}>  $entries
     */
    private function ledger(Transaction $tx, array $entries): void
    {
        foreach ($entries as $entry) {
            LedgerEntry::create([
                'transaction_id' => $tx->id,
                'account' => $entry['account'],
                'direction' => $entry['direction']->value,
                'amount' => $tx->amount,
                'balance_after' => $entry['with_balance'] ?? false ? $tx->balance_after : null,
            ]);
        }
    }

    /**
     * @param  array<string, mixed>  $extra
     */
    private function newTransaction(TransactionType $type, Student $student, float $amount, string $idempotencyKey, array $extra = []): Transaction
    {
        $tx = new Transaction(array_merge([
            'idempotency_key' => $idempotencyKey,
            'type' => $type->value,
            'student_id' => $student->id,
            'amount' => $amount,
            'balance_after' => $student->balance,
            'status' => TransactionStatus::Posted->value,
        ], $extra));

        return $tx;
    }
}
