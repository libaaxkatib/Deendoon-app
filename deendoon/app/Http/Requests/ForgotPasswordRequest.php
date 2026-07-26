<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

/**
 * FR-004. Deliberately does NOT validate `exists:users,email` — that rule
 * would itself be a user-enumeration vector (a 422 "no such email" versus
 * a 200 "reset link sent" tells an attacker which emails are registered).
 * Format-only validation here; existence is checked silently inside
 * PasswordResetService, which always responds identically either way.
 */
class ForgotPasswordRequest extends FormRequest
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
            'email' => ['required', 'string', 'email', 'max:255'],
        ];
    }
}
