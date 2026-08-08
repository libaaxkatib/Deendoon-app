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
}
