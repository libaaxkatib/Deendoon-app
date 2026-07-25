<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-030 A1: a call logged with no answer/no outcome is still a valid,
 * recordable attempt — outcome/details is deliberately nullable, not
 * required.
 */
class LogCallRequest extends FormRequest
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
            'details' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
