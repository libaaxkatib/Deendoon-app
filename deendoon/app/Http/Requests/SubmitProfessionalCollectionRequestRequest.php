<?php

namespace App\Http\Requests;

use App\Enums\ReferenceDataCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): Reason for Transfer (multi-select, Reference Data-backed,
 * plus optional free-text notes) and Requested Services (multi-select,
 * Reference Data-backed) must both be selected from the tenant's own
 * active Reference Data values — never a hardcoded list — and the
 * Client Declaration must be accepted before submission.
 */
class SubmitProfessionalCollectionRequestRequest extends FormRequest
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
                    ->where('category', ReferenceDataCategory::TransferReason->value)
                    ->where('is_active', true)),
            ],
            'notes' => ['nullable', 'string', 'max:2000'],
            'services' => ['required', 'array', 'min:1'],
            'services.*' => [
                'string',
                'distinct',
                Rule::exists('reference_data', 'value_label')->where(fn ($query) => $query
                    ->where('tenant_id', $this->user()->tenant_id)
                    ->where('category', ReferenceDataCategory::RequestedService->value)
                    ->where('is_active', true)),
            ],
            'declaration_accepted' => ['required', 'accepted'],
        ];
    }
}
