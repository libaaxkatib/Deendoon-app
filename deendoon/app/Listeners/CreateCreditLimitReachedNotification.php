<?php

namespace App\Listeners;

use App\Enums\NotificationType;
use App\Events\CreditLimitReached;
use App\Models\User;
use App\Services\NotificationService;

/**
 * FR-058/BR-007. `CreditLimitReached` carries only the affected Customer —
 * no acting user, since it can fire from several different contexts
 * (Debt creation, status change) that may not always have one in scope.
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): the tenant's single Business Owner account
 * (`admin`) is the only tenant-side recipient, consistent with BR-007's
 * "the business must be notified" framing.
 */
class CreateCreditLimitReachedNotification
{
    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(CreditLimitReached $event): void
    {
        $customer = $event->customer;

        $recipients = User::role('admin')
            ->where('tenant_id', $customer->tenant_id)
            ->get();

        $this->notifications->notifyMany(
            $customer->tenant_id,
            $recipients,
            NotificationType::CreditLimitReached,
            'customer',
            $customer->id,
        );
    }
}
