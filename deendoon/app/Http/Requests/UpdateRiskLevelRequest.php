<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * FR-027: "System validates the value against the approved set" —
 * DD-010 (04_Business_Rules.md) previously left that set undefined, so
 * this request validated only the column's own type/length constraint.
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §2.9, §5.6, §6.2) now resolves
 * DD-010: Risk Level is a fixed three-value classification (High/Medium/
 * Low), used identically for status coloring, Risk Distribution, and Case
 * filtering throughout the approved UI. This does not read from
 * `reference_data` — that table's `risk_level` category remains a
 * display/configuration list only (see ReferenceDataService's own
 * docblock: "this module does not wire consuming-module validation
 * against it"), and Backend v2.1 does not ask for that wiring; it asks
 * for exactly this fixed set, matching every other categorical field in
 * this project (customer_status, debt_status, etc.), which validate
 * against an inline `Rule::in()` rather than a tenant-configurable table.
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
            'risk_level' => ['required', 'string', Rule::in(['high', 'medium', 'low'])],
        ];
    }
}
