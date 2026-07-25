<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CommitCustomerImportRequest extends FormRequest
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
            'resolutions' => ['sometimes', 'array'],
            'resolutions.*.row_number' => ['required_with:resolutions', 'integer', 'min:1'],
            'resolutions.*.resolution' => ['required_with:resolutions', 'string', Rule::in(['skip', 'update', 'new'])],
        ];
    }
}
