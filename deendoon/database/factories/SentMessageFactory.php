<?php

namespace Database\Factories;

use App\Enums\MessageChannel;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\SentMessage>
 */
class SentMessageFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'channel' => MessageChannel::WhatsApp,
            'recipient_phone' => $this->faker->numerify('2547########'),
            'rendered_text' => 'This is a friendly reminder.',
            'status' => 'sent',
            'sent_by_user_id' => (string) $this->faker->numberBetween(1, 999999),
            'sent_at' => now(),
        ];
    }
}
