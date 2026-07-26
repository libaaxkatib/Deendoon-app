<?php

namespace Database\Factories;

use App\Models\Notification;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Notification>
 */
class NotificationFactory extends Factory
{
    protected $model = Notification::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'recipient_user_id' => (string) $this->faker->numberBetween(1, 999999),
            'type' => 'payment_received',
            'related_entity_type' => 'payment',
            'related_entity_id' => (string) Str::ulid(),
            'created_at' => now(),
        ];
    }
}
