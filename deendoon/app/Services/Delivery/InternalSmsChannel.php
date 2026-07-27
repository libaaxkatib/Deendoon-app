<?php

namespace App\Services\Delivery;

use App\Contracts\MessageDeliveryChannel;

/**
 * External Integrations Policy (Sprint 3): no SMS gateway (Twilio,
 * MessageBird, Vonage, AWS SNS, or any other) may be selected or
 * implemented. This class satisfies the MessageDeliveryChannel contract
 * internally — it always reports "sent" without making any external
 * call. Replace this implementation, not the contract, once the Product
 * Owner approves a specific provider.
 */
class InternalSmsChannel implements MessageDeliveryChannel
{
    public function deliver(string $recipientPhone, string $renderedText): string
    {
        return 'sent';
    }
}
