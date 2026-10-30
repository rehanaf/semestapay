<?php

namespace Database\Factories;

use App\Models\Bill;
use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Bill>
 */
class BillFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'student_id' => Student::factory(),
            'type' => fake()->randomElement(['spp', 'pondok', 'seragam']),
            'period' => fake()->bothify('2026-0#'),
            'description' => fake()->sentence(),
            'amount' => fake()->randomElement([300000, 250000, 150000]),
            'paid_amount' => 0,
            'due_date' => fake()->dateTimeBetween('now', '+30 days')->format('Y-m-d'),
            'status' => 'unpaid',
        ];
    }
}
