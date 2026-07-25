<?php

namespace Database\Factories;

use App\Models\CollectionCase;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CollectionCase>
 */
class CollectionCaseFactory extends Factory
{
    protected $model = CollectionCase::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'reference_number' => 'COL-'.str_pad((string) $this->faker->unique()->numberBetween(1, 999999), 6, '0', STR_PAD_LEFT),
            'case_status' => 'open',
        ];
    }

    public function closed(): static
    {
        return $this->state(fn (array $attributes) => [
            'case_status' => 'closed',
            'closure_outcome' => 'recovered',
            'closed_at' => now(),
        ]);
    }
}
