<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-070. Each item either updates an existing value (`id` present) or
 * creates a new one (`id` absent). Deactivation is expressed by
 * `is_active: false` on an existing item (06 §6.8: "sets this rather than
 * deleting the row") — the Product Owner ruling on FR-070 E2 (block
 * removal of an in-use value) is enforced in ReferenceDataService, not
 * here, since it requires a database lookup.
 */
class UpdateReferenceDataRequest extends FormRequest
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
            'values' => ['required', 'array', 'min:1'],
            'values.*.id' => ['nullable', 'string'],
            'values.*.value_label' => ['required', 'string', 'max:100'],
            'values.*.sort_order' => ['nullable', 'integer'],
            'values.*.is_active' => ['nullable', 'boolean'],
        ];
    }
}
