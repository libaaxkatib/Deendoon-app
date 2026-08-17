<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * docs/Backend_v2.1_REST_API_Specification.md §8 — Render Message, scoped
 * to Reminder-sourced rendering this sprint (see MessageRenderingService).
 */
class RenderMessageRequest extends FormRequest
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
            'template_id' => ['required', 'string'],
            'reminder_id' => ['required', 'string'],
            // Fix #23 Decision 8 — optional; when omitted, the customer's
            // primary phone is used (Decision 7). This is the endpoint the
            // mobile Message Preview screen actually calls for both
            // WhatsApp and SMS — resolved and ownership-verified
            // server-side in the controller, never trusted as a raw
            // phone string.
            'phone_number_id' => ['nullable', 'string'],
        ];
    }
}
