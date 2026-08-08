<?php

namespace App\Enums;

/**
 * Mirrors the reference_data.category CHECK constraint (06 §6.8) exactly.
 */
enum ReferenceDataCategory: string
{
    case RiskLevel = 'risk_level';
    case PaymentMethod = 'payment_method';
    case CollectionOutcome = 'collection_outcome';
    // Transfer Case to Deendoon Recovery Team (Product Owner-approved
    // decision): Reason for Transfer and Requested Services must both
    // come from this architecture, not a hardcoded list.
    case TransferReason = 'transfer_reason';
    case RequestedService = 'requested_service';
    // Subscription Approval + Storage Add-on Approval (Product
    // Owner-approved decision record): predefined multi-select
    // Rejection Reasons, platform-owned (tenant_id NULL).
    case SubscriptionRejectionReason = 'subscription_rejection_reason';
    case StorageRejectionReason = 'storage_rejection_reason';
}
