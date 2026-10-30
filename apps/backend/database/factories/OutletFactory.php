<?php

namespace Database\Factories;

use App\Models\Merchant;
use App\Models\Outlet;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Outlet>
 */
class OutletFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'merchant_id' => Merchant::factory(),
            'name' => fake()->words(2, true),
            'code' => fake()->unique()->bothify('OUT-####'),
            'status' => 'active',
        ];
    }
}
