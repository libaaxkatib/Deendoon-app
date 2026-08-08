<?php

namespace App\Http\Requests;

use App\Enums\ReferenceDataCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record, Decision 4): predefined multi-select Rejection Reasons,
 * validated against the platform-owned (tenant_id NULL) Reference Data
 * category `subscription_rejection_reason` — same
 * Rule::exists()-against-Reference-Data pattern as
 * SubmitProfessionalCollectionRequestRequest's `reasons`/`services`, with
 * `tenant_id` matched to the actor's own (NULL for the Deendoon Platform
 * Administrator) rather than a tenant's, since these rows are
 * platform-owned. Optional free-text `notes` stored in the existing
 * `rejection_reason` column.
 */
class RejectSubscriptionChangeRequestRequest extends FormRequest
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
            'reasons' => ['required', 'array', 'min:1'],
            'reasons.*' => [
                'string',
                'distinct',
                Rule::exists('reference_data', 'value_label')->where(fn ($query) => $query
                    ->where('tenant_id', $this->user()->tenant_id)
                    ->where('category', ReferenceDataCategory::SubscriptionRejectionReason->value)
                    ->where('is_active', true)),
            ],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
