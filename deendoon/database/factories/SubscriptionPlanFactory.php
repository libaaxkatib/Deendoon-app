<?php

namespace Database\Factories;

use App\Models\SubscriptionPlan;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SubscriptionPlan>
 */
class SubscriptionPlanFactory extends Factory
{
    protected $model = SubscriptionPlan::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => $this->faker->unique()->words(2, true),
            'customer_limit' => $this->faker->numberBetween(1, 500),
            'analytics_enabled' => true,
            'storage_limit' => $this->faker->numberBetween(1, 100),
            'monthly_price' => $this->faker->randomFloat(2, 0, 20),
            'active' => true,
        ];
    }

    public function unlimited(): static
    {
        return $this->state(fn (array $attributes) => [
            'customer_limit' => null,
        ]);
    }

    public function analyticsDisabled(): static
    {
        return $this->state(fn (array $attributes) => [
            'analytics_enabled' => false,
        ]);
    }
}
