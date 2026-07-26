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
}
