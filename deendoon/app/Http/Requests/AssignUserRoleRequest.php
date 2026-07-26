<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * FR-067. See CreateUserRequest's docblock for the tenant-scoped-role
 * whitelist rationale. FR-067 A1 (multi-role): Product Owner ruling —
 * single role only, matching every prior module's implementation.
 */
class AssignUserRoleRequest extends FormRequest
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
            'role' => ['required', 'string', Rule::in(['admin', 'sales_finance', 'customer', 'collection_officer'])],
        ];
    }
}
