<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-020: only non-financial fields (due date, notes). amount is
 * deliberately absent — no approved FR permits changing it after
 * creation; Debt Status is governed separately by FR-021.
 */
class UpdateDebtRequest extends FormRequest
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
            'due_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
