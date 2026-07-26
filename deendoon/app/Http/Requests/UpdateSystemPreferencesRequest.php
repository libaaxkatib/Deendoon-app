<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * FR-069. Product Owner ruling on the FR-069 E2 open item ("reasonable
 * bounds"): day-based intervals and thresholds are constrained to a sane
 * 1-365 range; monetary/percentage fields are non-negative with an upper
 * sanity bound. `whatsapp_reminder_days`/`sms_reminder_days`/
 * `call_reminder_days`/`notification_settings` remain structurally
 * flexible JSON, per 06 §6.8's own note that their exact shape was never
 * approved — only element-level day bounds are enforced where the shape
 * (a list of day offsets) is unambiguous. `document_templates` is the
 * fourth System Preferences category FR-069's Main Flow names, stored
 * separately (06 §6.8's `document_templates` table) but submitted here
 * since FR-069 treats it as one preferences screen.
 */
class UpdateSystemPreferencesRequest extends FormRequest
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
            'default_credit_limit' => ['required', 'numeric', 'min:0', 'max:9999999999.99'],
            'credit_limit_reminder_enabled' => ['required', 'boolean'],
            'soft_limit_warning_threshold' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'whatsapp_reminder_days' => ['nullable', 'array'],
            'whatsapp_reminder_days.*' => ['integer', 'min:1', 'max:365'],
            'sms_reminder_days' => ['nullable', 'array'],
            'sms_reminder_days.*' => ['integer', 'min:1', 'max:365'],
            'call_reminder_days' => ['nullable', 'array'],
            'call_reminder_days.*' => ['integer', 'min:1', 'max:365'],
            'professional_collection_threshold_days' => ['nullable', 'integer', 'min:1', 'max:365'],
            'notification_settings' => ['nullable', 'array'],
            'document_templates' => ['nullable', 'array'],
            'document_templates.*.template_type' => ['required_with:document_templates', 'string', Rule::in(['first_reminder', 'second_reminder', 'final_demand', 'legal_notice'])],
            'document_templates.*.content' => ['required_with:document_templates', 'string'],
        ];
    }
}
