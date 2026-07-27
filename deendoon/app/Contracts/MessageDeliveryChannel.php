<?php

namespace App\Contracts;

/**
 * External Integrations Policy (Sprint 3): no WhatsApp/SMS provider may be
 * selected, installed, or called in this sprint. This contract is the
 * seam a real provider integration will implement later, once the
 * Product Owner has evaluated and approved one — see the internal,
 * no-op-but-structurally-correct implementations in
 * App\Services\Delivery for what backs this contract today.
 */
interface MessageDeliveryChannel
{
    /**
     * Returns the delivery status ("sent" or "failed") to record on the
     * Sent Message row. Never performs an external network call in this
     * sprint's implementations.
     */
    public function deliver(string $recipientPhone, string $renderedText): string;
}
