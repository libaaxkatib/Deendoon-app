<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class GenerateDemandLetterRequest extends FormRequest
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
            'template_type' => ['required', 'string', Rule::in([
                'first_reminder', 'second_reminder', 'final_demand', 'legal_notice',
            ])],
        ];
    }
}
