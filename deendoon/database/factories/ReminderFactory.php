<?php

namespace Database\Factories;

use App\Enums\ReminderTimingRule;
use App\Enums\ReminderType;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<\App\Models\Reminder>
 */
class ReminderFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'created_by_user_id' => (string) $this->faker->numberBetween(1, 999999),
            'type' => ReminderType::FollowUpCall,
            'related_entity_type' => 'debt',
            'related_entity_id' => (string) Str::ulid(),
            'due_date' => now()->addDay(),
            'timing_rule' => ReminderTimingRule::SameDay,
            'delivery_methods' => ['in_app'],
        ];
    }

    public function dueToday(): static
    {
        return $this->state(fn (array $attributes) => ['due_date' => now()->addHours(2)]);
    }

    public function overdue(): static
    {
        return $this->state(fn (array $attributes) => ['due_date' => now()->subDays(2)]);
    }

    public function completed(): static
    {
        return $this->state(fn (array $attributes) => ['completed_at' => now()]);
    }

    public function paymentDue(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => ReminderType::PaymentDue,
            'amount_due' => $this->faker->randomFloat(2, 100, 5000),
        ]);
    }
}
