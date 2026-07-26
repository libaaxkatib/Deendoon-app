<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

/**
 * FR-066/FR-067: Product Owner ruling — administrator sets the initial
 * password directly (no self-service invitation mechanism exists in this
 * project). `role` is required at creation, restricted to the four
 * tenant-scoped roles this project actually implements under the interim
 * RBAC model (Product Owner Decision 4) — `deendoon_platform_administrator`
 * is a distinct, non-tenant-scoped actor (08 §5) never assignable here.
 */
class CreateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'email' => Str::lower(trim((string) $this->input('email'))),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::defaults()],
            'role' => ['required', 'string', Rule::in(['admin', 'sales_finance', 'customer', 'collection_officer'])],
        ];
    }
}
