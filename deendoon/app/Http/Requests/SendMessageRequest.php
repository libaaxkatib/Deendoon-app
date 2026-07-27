<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * docs/Mobile_UI_V1_Frozen.md §7.7, §7.8 — the channel itself is implied
 * by which route was called (send/whatsapp vs send/sms), not a body
 * field. Scoped to Reminder-sourced sends this sprint.
 */
class SendMessageRequest extends FormRequest
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
        ];
    }
}
