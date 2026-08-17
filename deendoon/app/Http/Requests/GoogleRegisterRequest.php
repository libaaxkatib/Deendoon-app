<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Mobile Fix #22 — Google Login, new-account path. `id_token` is
 * re-verified here exactly as it was in the initial `google-login` call —
 * verification is idempotent (re-checking the same token twice is safe
 * and normal), so this endpoint never trusts `business_name`/`phone`
 * without also independently re-confirming the caller's Google identity.
 * `business_name`/`phone` mirror RegisterRequest's own rules exactly —
 * this is the same Tenant + Business Owner creation, just reached from a
 * different first step.
 */
class GoogleRegisterRequest extends FormRequest
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
            'id_token' => ['required', 'string'],
            'business_name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
        ];
    }
}
