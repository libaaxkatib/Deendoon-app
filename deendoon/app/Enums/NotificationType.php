<?php

namespace App\Enums;

/**
 * Mirrors the notifications.type CHECK constraint (06_Database_Design.md
 * §6.7) exactly — FR-058's six enumerated event sources plus the reopened
 * Professional Collection Request-update event (06's own note: "FR-058's
 * enumerated event sources plus the reopened Request-update event";
 * 07_API_Design.md §11 confirms the same); 11_Development_Roadmap.md's
 * Phase 11 goal statement also names all seven.
 *
 * The 5 Support Ticket types (Module 7, Decision 12) are all Business
 * Owner-facing only: notifications.tenant_id is NOT NULL, and the
 * Deendoon Platform Administrator has no tenant to attribute a
 * notification to (the exact same schema constraint already documented on
 * ProfessionalCollectionRequestService::postMessage()), so there is no
 * "notify the Platform Administrator" direction for any of these.
 */
enum NotificationType: string
{
    case CreditLimitReached = 'credit_limit_reached';
    case PaymentReceived = 'payment_received';
    case DocumentAvailable = 'document_available';
    case CollectionAssignment = 'collection_assignment';
    case ReminderSent = 'reminder_sent';
    case PromiseToPayDue = 'promise_to_pay_due';
    case ProfessionalCollectionRequestUpdate = 'professional_collection_request_update';
    case SubscriptionRequestUpdate = 'subscription_request_update';
    case StorageRequestUpdate = 'storage_request_update';
    case SupportTicketCreated = 'support_ticket_created';
    case SupportTicketReplied = 'support_ticket_replied';
    case SupportTicketStatusChanged = 'support_ticket_status_changed';
    case SupportTicketClosed = 'support_ticket_closed';
    case SupportTicketReopened = 'support_ticket_reopened';
    case AdminAnnouncement = 'admin_announcement';

    /**
     * Module 9 — which SystemSetting.notification_settings toggle (if any)
     * gates creation of this type. Null means always-on/unfiltered.
     */
    public function preferenceKey(): ?string
    {
        return match ($this) {
            self::ReminderSent, self::PromiseToPayDue => 'reminder_enabled',
            self::PaymentReceived => 'payment_enabled',
            default => null,
        };
    }
}
