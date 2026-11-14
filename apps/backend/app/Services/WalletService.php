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
use App\Models\Merchant;
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
     * Transfer saldo antar-wallet santri secara atomik.
     *
     * @return array{sender: Transaction, recipient: Transaction}
     */
    public function transferBetweenStudents(
        Student $sender,
        Student $recipient,
        float $amount,
        ?string $note = null,
        ?string $idempotencyKey = null,
    ): array {
        if ($sender->is($recipient)) {
            throw new IdempotencyConflictException('Tidak dapat transfer ke akun sendiri.');
        }

        if ($amount <= 0) {
            throw new InsufficientBalanceException('Nominal harus lebih dari 0.');
        }

        $amount = round($amount, 2);
        $idempotencyKey ??= (string) Str::uuid();

        return DB::transaction(function () use ($sender, $recipient, $amount, $note, $idempotencyKey): array {
            $lockedStudents = Student::query()
                ->whereIn('id', [$sender->id, $recipient->id])
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');
            $lockedSender = $lockedStudents->get($sender->id);
            $lockedRecipient = $lockedStudents->get($recipient->id);

            if ($lockedSender === null || $lockedRecipient === null) {
                throw new IdempotencyConflictException('Akun transfer tidak ditemukan.');
            }

            $existingSenderTransfer = Transaction::query()
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existingSenderTransfer !== null) {
                if (
                    $existingSenderTransfer->type !== TransactionType::TransferOut->value
                    || $existingSenderTransfer->student_id !== $lockedSender->id
                    || (int) $existingSenderTransfer->reference_id !== $lockedRecipient->id
                    || abs((float) $existingSenderTransfer->amount - $amount) >= 0.01
                ) {
                    throw new IdempotencyConflictException('Kunci idempotensi sudah digunakan.');
                }

                $existingRecipientTransfer = Transaction::query()
                    ->where('type', TransactionType::TransferIn->value)
                    ->where('reference_type', 'student_transfer')
                    ->where('reference_id', $existingSenderTransfer->id)
                    ->first();

                if ($existingRecipientTransfer === null) {
                    throw new IdempotencyConflictException('Data transfer tidak lengkap.');
                }

                return [
                    'sender' => $existingSenderTransfer,
                    'recipient' => $existingRecipientTransfer,
                ];
            }

            foreach ([$lockedSender, $lockedRecipient] as $student) {
                if (
                    $student->status !== 'active'
                    || $student->wallet_status !== WalletStatus::Active->value
                ) {
                    throw new WalletNotActiveException('Wallet siswa tidak aktif.');
                }
            }

            if ((float) $lockedSender->balance < $amount) {
                throw new InsufficientBalanceException('Saldo tidak mencukupi.');
            }

            $lockedSender->balance = (float) $lockedSender->balance - $amount;
            $this->persistStudent($lockedSender);
            $lockedRecipient->balance = (float) $lockedRecipient->balance + $amount;
            $this->persistStudent($lockedRecipient);

            $senderTransaction = $this->newTransaction(
                TransactionType::TransferOut,
                $lockedSender,
                $amount,
                $idempotencyKey,
                [
                    'reference_type' => 'student_transfer',
                    'reference_id' => (string) $lockedRecipient->id,
                    'note' => $note === null ? 'Transfer ke '.$lockedRecipient->name : 'Transfer ke '.$lockedRecipient->name.' • '.$note,
                ],
            );
            $senderTransaction->save();

            $recipientTransaction = $this->newTransaction(
                TransactionType::TransferIn,
                $lockedRecipient,
                $amount,
                (string) Str::uuid(),
                [
                    'reference_type' => 'student_transfer',
                    'reference_id' => $senderTransaction->id,
                    'note' => $note === null ? 'Transfer dari '.$lockedSender->name : 'Transfer dari '.$lockedSender->name.' • '.$note,
                ],
            );
            $recipientTransaction->save();

            $this->ledger($senderTransaction, [
                ['account' => 'wallet', 'direction' => LedgerDirection::Credit, 'with_balance' => true],
                ['account' => 'student_transfer', 'direction' => LedgerDirection::Debit, 'with_balance' => false],
            ]);
            $this->ledger($recipientTransaction, [
                ['account' => 'student_transfer', 'direction' => LedgerDirection::Credit, 'with_balance' => false],
                ['account' => 'wallet', 'direction' => LedgerDirection::Debit, 'with_balance' => true],
            ]);

            return [
                'sender' => $senderTransaction,
                'recipient' => $recipientTransaction,
            ];
        }, attempts: 3);
    }

    /**
     * Pembayaran gesek di outlet (debit wallet, cek limit harian per merchant).
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

        $outlet->loadMissing('merchant');

        return $this->mutate($student, $idempotencyKey, function (Student $student) use (
            $amount, $outlet, $shift, $actor, $note, $idempotencyKey,
        ) {
            $this->charge($student, $amount, outlet: $outlet);

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
     * Kas keluar: merchant menyerahkan uang tunai, saldo merchant berkurang
     * dan saldo wallet santri bertambah.
     */
    public function cashOut(
        Student $student,
        float $amount,
        Outlet $outlet,
        ?User $actor = null,
        ?string $note = null,
        ?string $idempotencyKey = null,
        ?CashierShift $shift = null,
    ): Transaction {
        $idempotencyKey ??= (string) Str::uuid();

        if ($amount <= 0) {
            throw new InsufficientBalanceException('Nominal harus lebih dari 0.');
        }

        return $this->mutate($student, $idempotencyKey, function (Student $student) use (
            $amount, $outlet, $actor, $note, $idempotencyKey, $shift,
        ) {
            $merchant = Merchant::whereKey($outlet->merchant_id)->lockForUpdate()->first();

            if ($merchant === null) {
                throw new InsufficientBalanceException('Merchant tidak ditemukan.');
            }

            if ((float) $merchant->balance < $amount) {
                throw new InsufficientBalanceException('Saldo merchant tidak mencukupi untuk kas keluar.');
            }

            $this->credit($student, $amount);

            $tx = $this->newTransaction(TransactionType::CashOut, $student, $amount, $idempotencyKey, [
                'outlet_id' => $outlet->id,
                'cashier_shift_id' => $shift?->id,
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
     * Set saldo santri dari panel admin dan catat transaksi penyesuaian.
     */
    public function adjustStudentBalance(
        Student $student,
        float $newBalance,
        ?User $actor = null,
        ?string $note = null,
    ): ?Transaction {
        if ($newBalance < 0) {
            throw new InsufficientBalanceException('Saldo tidak boleh negatif.');
        }

        if (abs($newBalance - (float) $student->balance) < 0.01) {
            return null;
        }

        $idempotencyKey = (string) Str::uuid();

        return $this->mutate($student, $idempotencyKey, function (Student $student) use (
            $newBalance, $actor, $note, $idempotencyKey,
        ) {
            $difference = round($newBalance - (float) $student->balance, 2);

            if ($difference > 0) {
                $this->credit($student, $difference);
            } else {
                $this->charge($student, abs($difference));
            }

            $tx = $this->newTransaction(TransactionType::Adjustment, $student, abs($difference), $idempotencyKey, [
                'actor_user_id' => $actor?->id,
                'note' => $note ?? 'Penyesuaian saldo oleh admin',
            ]);
            $tx->save();

            $this->ledger($tx, [
                [
                    'account' => 'wallet',
                    'direction' => $difference > 0 ? LedgerDirection::Credit : LedgerDirection::Debit,
                    'with_balance' => true,
                ],
                [
                    'account' => 'adjustment',
                    'direction' => $difference > 0 ? LedgerDirection::Debit : LedgerDirection::Credit,
                    'with_balance' => false,
                ],
            ]);

            return $tx;
        });
    }

    public function setMerchantBalance(Merchant $merchant, float $newBalance): Merchant
    {
        $merchant->balance = max(0, $newBalance);
        $merchant->save();

        return $merchant;
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
            $this->charge($student, $remaining);

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
     * Balikkan transaksi dan tandai transaksi asal reversed.
     */
    public function reverse(
        Transaction $original,
        ?User $by = null,
        ?string $reason = null,
        ?string $idempotencyKey = null,
    ): Transaction {
        $idempotencyKey ??= (string) Str::uuid();

        $original->load(['student', 'outlet']);

        if ($original->status === TransactionStatus::Reversed->value) {
            throw new IdempotencyConflictException('Transaksi sudah pernah di-reverse.');
        }

        $isCashOut = $original->type === TransactionType::CashOut->value;

        return $this->mutate($original->student, $idempotencyKey, function (Student $student) use (
            $original, $by, $reason, $isCashOut, $idempotencyKey,
        ) {
            if ($isCashOut) {
                $this->charge($student, (float) $original->amount);
            } else {
                $this->credit($student, (float) $original->amount);
            }

            $tx = $this->newTransaction(TransactionType::Reversal, $student, (float) $original->amount, $idempotencyKey, [
                'reference_type' => 'transaction',
                'reference_id' => $original->id,
                'actor_user_id' => $by?->id,
                'note' => $reason,
            ]);
            $tx->save();

            $creditAccount = match ($original->type) {
                TransactionType::Payment->value => 'merchant_payable',
                TransactionType::BillPayment->value => 'receivable_cleared',
                TransactionType::CashOut->value => 'merchant_payable',
                default => 'cash',
            };

            if ($isCashOut) {
                $this->ledger($tx, [
                    ['account' => 'wallet', 'direction' => LedgerDirection::Debit, 'with_balance' => true],
                    ['account' => $creditAccount, 'direction' => LedgerDirection::Credit, 'with_balance' => false],
                ]);
            } else {
                $this->ledger($tx, [
                    ['account' => $creditAccount, 'direction' => LedgerDirection::Debit, 'with_balance' => false],
                    ['account' => 'wallet', 'direction' => LedgerDirection::Credit, 'with_balance' => true],
                ]);
            }

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
    /**
     * Kurangi saldo setelah cek limit harian per merchant (dan global student).
     *
     * @param  ?Outlet  $outlet  Outlet transaksi; null = tidak kena limit (topup, reversal, dll).
     */
    private function charge(Student $student, float $amount, ?Outlet $outlet = null): void
    {
        if ($amount <= 0) {
            throw new InsufficientBalanceException('Nominal harus lebih dari 0.');
        }

        if ($outlet !== null) {
            // Cek limit harian khusus merchant (mis. kantin Rp 20.000)
            $this->assertMerchantDailyLimit($student, $amount, $outlet);

            // Cek limit harian global student
            $this->assertDailyLimit($student, $amount);
        }

        if ((float) $student->balance < $amount) {
            throw new InsufficientBalanceException('Saldo tidak mencukupi.');
        }

        $student->balance = (float) $student->balance - $amount;
        $this->persistStudent($student);

        if ($outlet !== null) {
            $merchantId = $outlet->merchant_id;
            $this->incrementDailyUsage($student->id, $amount, $merchantId);
        }
    }

    private function credit(Student $student, float $amount): void
    {
        $student->balance = (float) $student->balance + $amount;
        $this->persistStudent($student);
    }

    /**
     * Cek limit harian global student (semua merchant digabung).
     */
    private function assertDailyLimit(Student $student, float $amount): void
    {
        $limit = (float) $student->daily_limit;

        if ($limit <= 0) {
            return;
        }

        $used = (float) DailyUsage::where('student_id', $student->id)
            ->whereNull('merchant_id')
            ->where('usage_date', today())
            ->sum('total_used');

        if ($used + $amount > $limit) {
            throw new DailyLimitExceededException('Melebihi batas belanja harian.');
        }
    }

    /**
     * Cek limit harian khusus merchant (mis. kantin Rp 20.000/hari).
     */
    private function assertMerchantDailyLimit(Student $student, float $amount, Outlet $outlet): void
    {
        $merchant = $outlet->merchant;
        $limit = $merchant?->daily_limit !== null ? (float) $merchant->daily_limit : 0;

        if ($limit <= 0) {
            return;
        }

        $used = (float) DailyUsage::where('student_id', $student->id)
            ->where('merchant_id', $outlet->merchant_id)
            ->where('usage_date', today())
            ->sum('total_used');

        if ($used + $amount > $limit) {
            throw new DailyLimitExceededException(
                'Melebihi batas belanja harian di '.$merchant->name
                .' (maks Rp '.number_format($limit, 0, ',', '.').'/hari).',
            );
        }
    }

    /**
     * Catat pemakaian harian per merchant dan global (merchant_id=NULL).
     */
    private function incrementDailyUsage(int $studentId, float $amount, int $merchantId): void
    {
        // Rekam per merchant
        DailyUsage::firstOrCreate(
            ['student_id' => $studentId, 'merchant_id' => $merchantId, 'usage_date' => today()],
            ['total_used' => 0],
        );
        DailyUsage::where('student_id', $studentId)
            ->where('merchant_id', $merchantId)
            ->where('usage_date', today())
            ->increment('total_used', $amount);

        // Rekam global (merchant_id = NULL) untuk cek daily_limit student
        DailyUsage::firstOrCreate(
            ['student_id' => $studentId, 'merchant_id' => null, 'usage_date' => today()],
            ['total_used' => 0],
        );
        DailyUsage::where('student_id', $studentId)
            ->whereNull('merchant_id')
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
