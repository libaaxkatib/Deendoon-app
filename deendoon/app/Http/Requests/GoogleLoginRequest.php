<?php

namespace App\Http\Requests;

use App\Services\GoogleIdTokenVerifier;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Mobile Fix #22 — Google Login. `id_token` is the only accepted field —
 * deliberately no `email`/`name` here, since trusting client-supplied
 * identity is exactly what this endpoint must never do (the verified
 * identity comes only from {@see GoogleIdTokenVerifier}).
 */
class GoogleLoginRequest extends FormRequest
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
        ];
    }
}
