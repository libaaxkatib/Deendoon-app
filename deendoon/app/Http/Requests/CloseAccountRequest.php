<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Mobile Play Store Readiness (Fix #3, Part B). `password` re-proves
 * ownership before this destructive-sounding-but-reversible action —
 * same shape as `ChangePasswordRequest`'s `current_password` (just a
 * presence check; the actual verification happens in
 * `AccountClosureService::close()`, not here).
 */
class CloseAccountRequest extends FormRequest
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
            'password' => ['required', 'string'],
        ];
    }
}
