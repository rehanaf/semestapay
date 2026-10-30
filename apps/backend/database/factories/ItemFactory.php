<?php

namespace Database\Factories;

use App\Models\Item;
use App\Models\Merchant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Item>
 */
class ItemFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'merchant_id' => Merchant::factory(),
            'name' => fake()->words(2, true),
            'price' => fake()->randomElement([3000, 5000, 7000, 10000, 15000]),
            'status' => 'active',
        ];
    }
}
