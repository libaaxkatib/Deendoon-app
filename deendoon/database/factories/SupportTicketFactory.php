<?php

namespace Database\Factories;

use App\Models\SupportTicket;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SupportTicket>
 */
class SupportTicketFactory extends Factory
{
    protected $model = SupportTicket::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'subject' => $this->faker->sentence(6),
            'description' => $this->faker->paragraph(),
            'status' => 'open',
            'priority' => $this->faker->randomElement(['low', 'medium', 'high', 'urgent']),
            'category' => $this->faker->randomElement([
                'technical_issue', 'payment_billing', 'account', 'subscription',
                'debt_recovery', 'professional_collection', 'feature_request', 'other',
            ]),
            'submitted_by_user_id' => (string) $this->faker->numberBetween(1, 999999),
        ];
    }
}
