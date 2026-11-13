<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'name', 'type', 'owner_name', 'phone', 'email', 'address', 'description',
    'logo_path', 'status', 'balance', 'daily_limit',
])]
class Merchant extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'balance' => 'decimal:2',
        ];
    }

    public function logoUrl(): ?string
    {
        return $this->logo_path ? asset($this->logo_path) : null;
    }

    /**
     * @return HasMany<Outlet, $this>
     */
    public function outlets(): HasMany
    {
        return $this->hasMany(Outlet::class);
    }

    /**
     * @return HasMany<Item, $this>
     */
    public function items(): HasMany
    {
        return $this->hasMany(Item::class);
    }
}
