<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SchoolClass>
 */
class SchoolClassFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => 'Kelas '.strtoupper(fake()->unique()->randomLetter()).fake()->numberBetween(1, 3),
            'level' => (string) fake()->numberBetween(7, 3),
        ];
    }
}
