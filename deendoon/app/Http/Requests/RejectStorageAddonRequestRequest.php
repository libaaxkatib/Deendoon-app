<?php

namespace App\Http\Requests;

use App\Enums\ReferenceDataCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record, Decision 4): same predefined multi-select Rejection
 * Reasons pattern as RejectSubscriptionChangeRequestRequest, validated
 * against Reference Data category `storage_rejection_reason`.
 */
class RejectStorageAddonRequestRequest extends FormRequest
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
                    ->where('category', ReferenceDataCategory::StorageRejectionReason->value)
                    ->where('is_active', true)),
            ],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
