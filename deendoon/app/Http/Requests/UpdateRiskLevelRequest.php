<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-027: "System validates the value against the approved set" —
 * DD-010 (04_Business_Rules.md) leaves that set undefined, and
 * 06_Database_Design.md §3 is explicit that a value-set-pending-a-DD
 * column is validated against reference_data once a tenant configures
 * it, never a fixed constraint invented here. reference_data (Module 12)
 * doesn't exist yet, so only the column's own type/length constraint is
 * enforced. Tighten this once DD-010 resolves — see the report.
 */
class UpdateRiskLevelRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'risk_level' => trim((string) $this->input('risk_level')),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'risk_level' => ['required', 'string', 'max:50'],
        ];
    }
}
