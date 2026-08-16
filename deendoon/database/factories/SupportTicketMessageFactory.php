<?php

namespace Database\Factories;

use App\Models\SupportTicketMessage;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SupportTicketMessage>
 */
class SupportTicketMessageFactory extends Factory
{
    protected $model = SupportTicketMessage::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'sender_user_id' => (string) $this->faker->numberBetween(1, 999999),
            'content' => $this->faker->sentence(),
        ];
    }
}
