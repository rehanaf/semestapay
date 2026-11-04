<?php

namespace App\Models;

use Illuminate\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\HasApiTokens;

#[Fillable([
    'nis', 'name', 'class_id', 'phone_parent', 'pin_hash', 'status',
    'card_uid', 'card_status', 'card_assigned_at',
    'balance', 'currency', 'wallet_status', 'balance_updated_at', 'version',
    'daily_limit',
])]
class Student extends Model implements AuthenticatableContract
{
    use Authenticatable, HasApiTokens, HasFactory;

    protected function casts(): array
    {
        return [
            'balance' => 'decimal:2',
            'balance_updated_at' => 'datetime',
            'card_assigned_at' => 'datetime',
            'daily_limit' => 'decimal:2',
            'version' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<SchoolClass, $this>
     */
    public function klass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    /**
     * @return HasMany<Bill, $this>
     */
    public function bills(): HasMany
    {
        return $this->hasMany(Bill::class);
    }

    /**
     * @return HasMany<DailyUsage, $this>
     */
    public function dailyUsages(): HasMany
    {
        return $this->hasMany(DailyUsage::class);
    }

    /**
     * @return HasMany<Transaction, $this>
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function hasPin(): bool
    {
        return $this->pin_hash !== null;
    }

    public function verifyPin(string $pin): bool
    {
        if (! $this->hasPin()) {
            return true;
        }

        return Hash::check($pin, $this->pin_hash);
    }
}
