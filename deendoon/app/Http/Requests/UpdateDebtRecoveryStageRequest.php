<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-025 E1 / 07_API_Design.md §15: reason is mandatory at the API layer,
 * not just the UI, so the requirement can't be bypassed by calling the
 * API directly (BR-015).
 */
class UpdateDebtRecoveryStageRequest extends FormRequest
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
            'recovery_stage' => ['required', 'integer', 'between:1,6'],
            'reason' => ['required', 'string', 'max:500'],
        ];
    }
}
