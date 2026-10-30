<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Student>
 */
class StudentFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nis' => fake()->unique()->numerify('2026####'),
            'name' => fake()->name(),
            'class_id' => SchoolClass::factory(),
            'phone_parent' => '08'.fake()->numerify('##########'),
            'status' => 'active',
            'card_uid' => 'UID-'.fake()->unique()->numerify('########'),
            'card_status' => 'active',
            'card_assigned_at' => now(),
            'balance' => 0,
            'currency' => 'IDR',
            'wallet_status' => 'active',
            'daily_limit' => 0,
            'version' => 0,
        ];
    }
}
