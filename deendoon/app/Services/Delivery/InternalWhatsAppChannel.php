<?php

namespace App\Services\Delivery;

use App\Contracts\MessageDeliveryChannel;

/**
 * External Integrations Policy (Sprint 3): no WhatsApp Business API / Meta
 * Cloud API integration may be selected or implemented. This class
 * satisfies the MessageDeliveryChannel contract internally — it always
 * reports "sent" without making any external call — so the rest of the
 * Reminder Center (Sent Message recording, audit trail, UI response
 * shape) is fully built and testable ahead of a real provider being
 * chosen. Replace this implementation, not the contract, once the
 * Product Owner approves a specific provider.
 */
class InternalWhatsAppChannel implements MessageDeliveryChannel
{
    public function deliver(string $recipientPhone, string $renderedText): string
    {
        return 'sent';
    }
}
