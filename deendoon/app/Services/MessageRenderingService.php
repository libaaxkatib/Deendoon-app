<?php

namespace App\Services;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\CustomerPhoneNumber;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\MessageTemplate;
use App\Models\PromiseToPay;
use App\Models\Receipt;
use App\Models\Reminder;
use App\Models\Statement;
use RuntimeException;

/**
 * docs/Mobile_UI_V1_Frozen.md §7.7, §7.8: "The message body is generated
 * by substituting live data — customer name, amount due, due date, and
 * sender/company name — into the selected template."
 *
 * Backend Completion Roadmap, Phase 4.1: `resolveCustomer()`'s match
 * expression moved to `Reminder::relatedCustomer()` — ReminderPolicy
 * needs the identical "which Customer does this Reminder belong to"
 * resolution for the Customer Limit Enforcement read-only cascade, so
 * this now delegates there instead of keeping its own copy.
 */
class MessageRenderingService
{
    /**
     * Fix #23 Decision 7/8: `$phoneNumber` is an already
     * ownership-verified selection (the caller resolved and authorized
     * it) — when omitted, the customer's primary phone
     * (`$customer->phone`, mirrored from the primary `customer_phone_numbers`
     * row) is used. This is the render call the mobile Message Preview
     * screen actually invokes for both WhatsApp and SMS.
     *
     * @return array{rendered_text: string, recipient_name: ?string, recipient_phone: ?string}
     */
    public function renderForReminder(MessageTemplate $template, Reminder $reminder, ?CustomerPhoneNumber $phoneNumber = null): array
    {
        $customer = $reminder->relatedCustomer();
        $amountDue = $reminder->amount_due ?? $this->resolveOutstandingAmount($reminder);

        $replacements = [
            '{customer_name}' => $customer?->name ?? '',
            '{amount_due}' => $amountDue !== null ? number_format((float) $amountDue, 2) : '',
            '{due_date}' => $reminder->due_date->format('M j, Y'),
            '{company_name}' => $reminder->tenant?->business_name ?? '',
        ];

        return [
            'rendered_text' => strtr($template->body, $replacements),
            'recipient_name' => $customer?->name,
            'recipient_phone' => $phoneNumber?->phone ?? $customer?->phone,
        ];
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §8.8 (Document Share). No amount_due or
     * due_date concept applies to a generated document the way it does to
     * a Reminder, so those placeholders resolve to empty — the same
     * `strtr` substitution is reused rather than a parallel implementation.
     *
     * @return array{rendered_text: string, recipient_name: ?string, recipient_phone: ?string}
     */
    public function renderForDocument(MessageTemplate $template, Receipt|DemandLetter|Statement|Invoice $document): array
    {
        $customer = match (true) {
            $document instanceof Receipt => $document->payment->debt->customer,
            $document instanceof DemandLetter => $document->debt->customer,
            $document instanceof Statement => $document->customer,
            $document instanceof Invoice => $document->debt->customer,
        };

        $replacements = [
            '{customer_name}' => $customer?->name ?? '',
            '{amount_due}' => '',
            '{due_date}' => '',
            '{company_name}' => $document->tenant?->business_name ?? '',
        ];

        return [
            'rendered_text' => strtr($template->body, $replacements),
            'recipient_name' => $customer?->name,
            'recipient_phone' => $customer?->phone,
        ];
    }

    /**
     * Fallback for reminder types that never carry their own `amount_due`
     * (e.g. Follow-up Call, Client Visit): resolve the outstanding balance
     * from the related Debt/Collection Case instead, mirroring
     * resolveCustomer()'s entity routing. `Debt::remaining_balance` is this
     * app's canonical outstanding-amount column (maintained by
     * PaymentService on every payment); `Customer::outstanding_balance` is
     * the equivalent customer-level rollup (CustomerBalanceService, BRL-022)
     * used when the reminder is tied directly to a Customer rather than one
     * specific Debt.
     */
    private function resolveOutstandingAmount(Reminder $reminder): ?string
    {
        return match ($reminder->related_entity_type) {
            'customer' => Customer::find($reminder->related_entity_id)?->outstanding_balance,
            'debt' => Debt::find($reminder->related_entity_id)?->remaining_balance,
            'collection_case' => CollectionCase::find($reminder->related_entity_id)?->debt?->remaining_balance,
            'promise_to_pay' => PromiseToPay::find($reminder->related_entity_id)?->debt?->remaining_balance,
            default => throw new RuntimeException("Unknown reminder related_entity_type: {$reminder->related_entity_type}"),
        };
    }
}
