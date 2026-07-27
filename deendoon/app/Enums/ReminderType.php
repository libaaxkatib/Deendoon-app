<?php

namespace App\Enums;

/**
 * Mirrors the reminders.type CHECK constraint exactly.
 * docs/Mobile_UI_V1_Frozen.md §7.2 — the five defined Reminder Types.
 */
enum ReminderType: string
{
    case ClientVisit = 'client_visit';
    case FollowUpCall = 'follow_up_call';
    case PaymentDue = 'payment_due';
    case ContractRenewal = 'contract_renewal';
    case PromiseToPay = 'promise_to_pay';

    /**
     * §7.4: "Amount Due is displayed only for reminder types that carry a
     * monetary amount (Payment Due, Promise to Pay); it is omitted for
     * Client Visit, Follow-up Call, and Contract Renewal."
     */
    public function carriesAmountDue(): bool
    {
        return match ($this) {
            self::PaymentDue, self::PromiseToPay => true,
            self::ClientVisit, self::FollowUpCall, self::ContractRenewal => false,
        };
    }

    /**
     * Display label matching docs/Mobile_UI_V1_Frozen.md §7.2/§7.3's exact
     * wording ("Client Visit," "Follow-up Call," etc.).
     */
    public function label(): string
    {
        return match ($this) {
            self::ClientVisit => 'Client Visit',
            self::FollowUpCall => 'Follow-up Call',
            self::PaymentDue => 'Payment Due',
            self::ContractRenewal => 'Contract Renewal',
            self::PromiseToPay => 'Promise to Pay',
        };
    }
}
