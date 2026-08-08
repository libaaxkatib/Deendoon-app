<?php

namespace App\Enums;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): the Deendoon Recovery Team's operational recovery activity
 * types, recorded on the Professional Collection Timeline — independent
 * of the Audit Log (system/data changes) and the existing, unchanged
 * Customer Collection Timeline (DebtController::timeline()). Mirrors the
 * professional_collection_timeline_events.event_type CHECK constraint
 * exactly.
 */
enum ProfessionalCollectionTimelineEventType: string
{
    case PendingReview = 'pending_review';
    case DocumentsVerified = 'documents_verified';
    case Assigned = 'assigned';
    case InitialContact = 'initial_contact';
    case TelephoneCollection = 'telephone_collection';
    case WhatsappFollowUp = 'whatsapp_follow_up';
    case SmsFollowUp = 'sms_follow_up';
    case EmailCollection = 'email_collection';
    case Meeting = 'meeting';
    case FieldVisit = 'field_visit';
    case PaymentNegotiation = 'payment_negotiation';
    case SettlementNegotiation = 'settlement_negotiation';
    case InstallmentArrangement = 'installment_arrangement';
    case OfficialDemandLetter = 'official_demand_letter';
    case SkipTracing = 'skip_tracing';
    case LegalReview = 'legal_review';
    case CourtPreparation = 'court_preparation';
    case PartialRecovery = 'partial_recovery';
    case FullyRecovered = 'fully_recovered';
    case Closed = 'closed';
}
