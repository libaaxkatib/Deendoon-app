<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * closure_outcome's value set is pending DD-024 — accepted as free text,
 * matching 06/07's own posture (application-validated against
 * reference_data once configured; not yet configured, so not enforced
 * here as a fixed enum).
 */
class CloseCollectionCaseRequest extends FormRequest
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
            'closure_outcome' => ['required', 'string', 'max:50'],
        ];
    }
}
