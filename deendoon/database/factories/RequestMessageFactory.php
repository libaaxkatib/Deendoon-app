<?php

namespace Database\Factories;

use App\Models\RequestMessage;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<RequestMessage>
 */
class RequestMessageFactory extends Factory
{
    protected $model = RequestMessage::class;

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
