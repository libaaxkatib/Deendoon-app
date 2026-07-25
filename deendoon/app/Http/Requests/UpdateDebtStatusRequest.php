<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * FR-021 / 07_API_Design.md §5.3: manual transition is restricted to
 * Cancelled and Written Off only. Paid/Partial Paid are Payment-driven
 * (Module 6, not built) and Overdue is automatic (due date passage) — none
 * of the three are reachable through this endpoint.
 */
class UpdateDebtStatusRequest extends FormRequest
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
            'debt_status' => ['required', 'string', Rule::in(['cancelled', 'written_off'])],
        ];
    }
}
