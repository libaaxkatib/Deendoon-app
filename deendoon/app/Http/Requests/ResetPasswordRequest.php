<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

/**
 * FR-004. `password` reuses the project-wide global default
 * (AppServiceProvider::boot(): Password::min(12)) — the same policy
 * RegisterRequest/CreateUserRequest/UpdateUserRequest already validate
 * against, not a new or different rule for this flow.
 */
class ResetPasswordRequest extends FormRequest
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
            'token' => ['required', 'string'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ];
    }
}
