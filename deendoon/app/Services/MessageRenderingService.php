<?php

namespace App\Services;

use App\Models\CollectionCase;
use App\Models\Customer;
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
 */
class MessageRenderingService
{
    /**
     * @return array{rendered_text: string, recipient_name: ?string, recipient_phone: ?string}
     */
    public function renderForReminder(MessageTemplate $template, Reminder $reminder): array
    {
        $customer = $this->resolveCustomer($reminder);

        $replacements = [
            '{customer_name}' => $customer?->name ?? '',
            '{amount_due}' => $reminder->amount_due !== null ? (string) $reminder->amount_due : '',
            '{due_date}' => $reminder->due_date->format('M j, Y'),
            '{company_name}' => $reminder->tenant?->business_name ?? '',
        ];

        return [
            'rendered_text' => strtr($template->body, $replacements),
            'recipient_name' => $customer?->name,
            'recipient_phone' => $customer?->phone,
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

    private function resolveCustomer(Reminder $reminder): ?Customer
    {
        return match ($reminder->related_entity_type) {
            'customer' => Customer::find($reminder->related_entity_id),
            'debt' => Debt::find($reminder->related_entity_id)?->customer,
            'collection_case' => CollectionCase::find($reminder->related_entity_id)?->debt?->customer,
            'promise_to_pay' => PromiseToPay::find($reminder->related_entity_id)?->debt?->customer,
            default => throw new RuntimeException("Unknown reminder related_entity_type: {$reminder->related_entity_type}"),
        };
    }
}
