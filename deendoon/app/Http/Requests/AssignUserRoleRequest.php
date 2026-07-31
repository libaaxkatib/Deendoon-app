<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * @deprecated Serves the deprecated AdminUserController — no second
 * tenant role exists to assign under the Version 1 one-account-per-tenant
 * model (RBAC Architecture Amendment, Product Owner Decision,
 * 2026-07-30). Single role only, per that decision's explicit
 * "no multi-role support" instruction.
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
            'role' => ['required', 'string', Rule::in(['admin'])],
        ];
    }
}
