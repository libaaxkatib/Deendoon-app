<?php

namespace App\Http\Requests;

use App\Enums\ReminderDeliveryMethod;
use App\Enums\ReminderTimingRule;
use App\Enums\ReminderType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * docs/Mobile_UI_V1_Frozen.md §7.5 Validation Rules: exactly one timing
 * option; Custom requires both Date and Time, on or before the due date;
 * at least one delivery method.
 */
class StoreReminderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'type' => ['required', 'string', Rule::in(array_column(ReminderType::cases(), 'value'))],
            'related_entity_type' => ['required', 'string', Rule::in(['customer', 'debt', 'collection_case', 'promise_to_pay'])],
            'related_entity_id' => ['required', 'string'],
            'related_case_id' => ['nullable', 'string'],
            'due_date' => ['required', 'date'],
            'amount_due' => ['nullable', 'numeric', 'gt:0'],
            'timing_rule' => ['required', 'string', Rule::in(array_column(ReminderTimingRule::cases(), 'value'))],
            'custom_fire_at' => ['required_if:timing_rule,custom', 'nullable', 'date', 'before_or_equal:due_date'],
            'delivery_methods' => ['required', 'array', 'min:1'],
            'delivery_methods.*' => ['string', Rule::in(array_column(ReminderDeliveryMethod::cases(), 'value'))],
            'notes' => ['nullable', 'string'],
        ];
    }
}
