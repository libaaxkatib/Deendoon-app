<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

/**
 * FR-005. `password` reuses the project-wide global default
 * (AppServiceProvider::boot(): Password::min(12)) — the same policy
 * ResetPasswordRequest/RegisterRequest/CreateUserRequest/
 * UpdateUserRequest already validate against, not a new or different
 * rule for this flow.
 */
class ChangePasswordRequest extends FormRequest
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
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ];
    }
}
