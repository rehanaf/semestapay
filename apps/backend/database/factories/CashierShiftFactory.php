<?php

namespace Database\Factories;

use App\Models\CashierShift;
use App\Models\Outlet;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CashierShift>
 */
class CashierShiftFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'outlet_id' => Outlet::factory(),
            'opened_by' => User::factory(),
            'opened_at' => now(),
            'opening_cash' => 0,
            'status' => 'open',
        ];
    }
}
