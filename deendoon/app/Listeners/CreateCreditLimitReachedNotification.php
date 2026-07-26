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
 * With no single designated "owner" of a Customer (unlike a Collection
 * Case's assigned officer), this notifies every tenant user authorized to
 * manage Customers/Debts (admin/sales_finance, the interim RBAC model),
 * consistent with BR-007's "the business must be notified" framing rather
 * than inventing a single-recipient rule the SRS doesn't specify.
 */
class CreateCreditLimitReachedNotification
{
    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(CreditLimitReached $event): void
    {
        $customer = $event->customer;

        $recipients = User::role(['admin', 'sales_finance'])
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
