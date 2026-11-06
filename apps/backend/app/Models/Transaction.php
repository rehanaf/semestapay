<?php

namespace App\Models;

use App\Enums\TransactionStatus;
use App\Enums\TransactionType;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Support\Str;

#[Fillable([
    'id', 'idempotency_key', 'type', 'student_id', 'outlet_id', 'cashier_shift_id',
    'merchant_id', 'amount', 'balance_after', 'reference_type', 'reference_id',
    'actor_user_id', 'status', 'reversed_by', 'note',
])]
class Transaction extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'balance_after' => 'decimal:2',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Transaction $transaction) {
            $transaction->id = $transaction->id ?? (string) Str::uuid();
        });

        static::created(function (Transaction $transaction) {
            if ($transaction->status === TransactionStatus::Posted->value) {
                $transaction->applyMerchantBalance($transaction->merchantBalanceDelta());
            }
        });

        static::updated(function (Transaction $transaction) {
            if (! $transaction->wasChanged('status')) {
                return;
            }

            $wasPosted = $transaction->getOriginal('status') === TransactionStatus::Posted->value;
            $isPosted = $transaction->status === TransactionStatus::Posted->value;

            if ($wasPosted && ! $isPosted) {
                $transaction->applyMerchantBalance(-1 * $transaction->merchantBalanceDelta());
            } elseif (! $wasPosted && $isPosted) {
                $transaction->applyMerchantBalance($transaction->merchantBalanceDelta());
            }
        });

        static::deleted(function (Transaction $transaction) {
            if ($transaction->status === TransactionStatus::Posted->value) {
                $transaction->applyMerchantBalance(-1 * $transaction->merchantBalanceDelta());
            }
        });
    }

    /**
     * Dampak transaksi terhadap saldo merchant yang dipelihara.
     */
    public function merchantBalanceDelta(): float
    {
        return match ($this->type) {
            TransactionType::Payment->value => (float) $this->amount,
            TransactionType::CashOut->value => -1 * (float) $this->amount,
            default => 0.0,
        };
    }

    private function applyMerchantBalance(float $delta): void
    {
        if ($this->merchant_id === null || abs($delta) < 0.01) {
            return;
        }

        Merchant::whereKey($this->merchant_id)->increment('balance', $delta);
    }

    /**
     * @return BelongsTo<Student, $this>
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    /**
     * @return BelongsToMany<Item, $this>
     */
    public function items(): BelongsToMany
    {
        return $this->belongsToMany(Item::class, 'item_transaction')
            ->withPivot(['quantity', 'price']);
    }

    /**
     * @return BelongsTo<Outlet, $this>
     */
    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    /**
     * @return BelongsTo<Merchant, $this>
     */
    public function merchant(): BelongsTo
    {
        return $this->belongsTo(Merchant::class);
    }

    /**
     * @return BelongsTo<CashierShift, $this>
     */
    public function shift(): BelongsTo
    {
        return $this->belongsTo(CashierShift::class, 'cashier_shift_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }

    /**
     * @return BelongsTo<Transaction, $this>
     */
    public function reversedBy(): BelongsTo
    {
        return $this->belongsTo(Transaction::class, 'reversed_by');
    }
}
