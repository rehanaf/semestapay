<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentGatewayConfig extends Model
{
    use HasFactory;

    public const DUITKU = 'duitku';

    protected $fillable = [
        'provider',
        'config',
        'is_active',
    ];

    protected $casts = [
        'config' => 'array',
        'is_active' => 'boolean',
    ];

    /**
     * Ambil konfigurasi gateway yang aktif untuk provider tertentu.
     */
    public static function active(string $provider): ?self
    {
        return static::query()
            ->where('provider', $provider)
            ->where('is_active', true)
            ->first();
    }

    /**
     * Baca satu nilai dari payload konfigurasi JSON.
     */
    public function value(string $key, mixed $default = null): mixed
    {
        return data_get($this->config, $key, $default);
    }

    public function hasValue(string $key): bool
    {
        $value = $this->value($key);

        return $value !== null && $value !== '' && $value !== 'YOUR_MERCHANT_CODE';
    }
}
