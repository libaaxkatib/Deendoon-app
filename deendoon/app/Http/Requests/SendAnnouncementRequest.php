<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Module 9 — Admin Announcements. `authorize()` returns true because
 * access is already restricted at the route level by the
 * `can:platform-admin-only` middleware, matching every other Admin
 * FormRequest in this codebase.
 */
class SendAnnouncementRequest extends FormRequest
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
            'scope' => ['required', 'string', Rule::in(['all', 'selected'])],
            'tenant_ids' => ['required_if:scope,selected', 'array'],
            'tenant_ids.*' => ['string', 'exists:tenants,id'],
            'title' => ['required', 'string', 'max:255'],
            'message' => ['required', 'string', 'max:2000'],
        ];
    }
}
