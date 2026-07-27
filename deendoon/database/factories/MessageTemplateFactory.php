<?php

namespace Database\Factories;

use App\Enums\MessageChannel;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\MessageTemplate>
 */
class MessageTemplateFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => 'Payment Reminder',
            'channel' => MessageChannel::WhatsApp,
            'body' => "Hi {customer_name},\n\nThis is a friendly reminder that your scheduled payment of {amount_due} is due {due_date}.\n\nPlease complete your payment to avoid any delays.\n\nThank you for your cooperation.\n\n— {company_name}",
        ];
    }

    public function sms(): static
    {
        return $this->state(fn (array $attributes) => ['channel' => MessageChannel::Sms]);
    }
}
