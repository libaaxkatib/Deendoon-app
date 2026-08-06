<?php

namespace App\Enums;

/**
 * Mirrors the audit_log.action CHECK constraint (06_Database_Design.md §6.9)
 * exactly. Only a subset of these values is written by modules implemented
 * so far; the rest exist because the database constraint already allows
 * them for modules not yet built.
 */
enum AuditAction: string
{
    case Created = 'created';
    case Edited = 'edited';
    case Archived = 'archived';
    case Restored = 'restored';
    case StatusChanged = 'status_changed';
    case ReminderSent = 'reminder_sent';
    case PaymentAdded = 'payment_added';
    case CollectionRequested = 'collection_requested';
    case Login = 'login';
    case Logout = 'logout';
    case RoleChanged = 'role_changed';
    case CreditLimitChanged = 'credit_limit_changed';
    case CreditScoreRecalculated = 'credit_score_recalculated';
    case DemandLetterGenerated = 'demand_letter_generated';
    case ReceiptGenerated = 'receipt_generated';
    case StatementGenerated = 'statement_generated';
    case InvoiceGenerated = 'invoice_generated';
    case RecoveryStageOverride = 'recovery_stage_override';
    case ProfessionalCollectionRequestSubmitted = 'professional_collection_request_submitted';
    case ProfessionalCollectionRequestStatusChanged = 'professional_collection_request_status_changed';
    case RiskLevelRecalculated = 'risk_level_recalculated';
    case SubscriptionUpgradeRequested = 'subscription_upgrade_requested';
    case StorageAddonRequested = 'storage_addon_requested';
    case TrialExpired = 'trial_expired';
    case SubscriptionExpired = 'subscription_expired';
    case TrialProvisioned = 'trial_provisioned';
    case CustomerReadOnlyRecalculated = 'customer_read_only_recalculated';
}
