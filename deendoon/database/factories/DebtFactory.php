<?php

namespace Database\Factories;

use App\Models\Debt;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Debt>
 */
class DebtFactory extends Factory
{
    protected $model = Debt::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $amount = $this->faker->randomFloat(2, 100, 5000);

        return [
            'reference_number' => 'DBT-'.str_pad((string) $this->faker->unique()->numberBetween(1, 999999), 6, '0', STR_PAD_LEFT),
            'amount' => $amount,
            'due_date' => now()->addDays(30)->toDateString(),
            'debt_status' => 'pending',
            'remaining_balance' => $amount,
            'recovery_stage' => 1,
        ];
    }

    public function archived(): static
    {
        return $this->state(fn (array $attributes) => [
            'archived_at' => now(),
        ]);
    }

    public function overdue(): static
    {
        return $this->state(fn (array $attributes) => [
            'due_date' => now()->subDays(5)->toDateString(),
        ]);
    }
}
