<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['merchant_id', 'name', 'code', 'status'])]
class Outlet extends Model
{
    use HasFactory;

    /**
     * @return BelongsTo<Merchant, $this>
     */
    public function merchant(): BelongsTo
    {
        return $this->belongsTo(Merchant::class);
    }

    /**
     * @return HasMany<Cashier, $this>
     */
    public function cashiers(): HasMany
    {
        return $this->hasMany(Cashier::class);
    }

    /**
     * @return HasMany<CashierShift, $this>
     */
    public function shifts(): HasMany
    {
        return $this->hasMany(CashierShift::class);
    }

    /**
     * @return HasMany<Transaction, $this>
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
