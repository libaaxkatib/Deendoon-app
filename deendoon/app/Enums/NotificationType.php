<?php

namespace App\Enums;

/**
 * Mirrors the notifications.type CHECK constraint (06_Database_Design.md
 * §6.7) exactly — FR-058's six enumerated event sources plus the reopened
 * Professional Collection Request-update event (06's own note: "FR-058's
 * enumerated event sources plus the reopened Request-update event";
 * 07_API_Design.md §11 confirms the same); 11_Development_Roadmap.md's
 * Phase 11 goal statement also names all seven.
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
}
