<?php

namespace App\Http\Requests;

use App\Enums\MessageChannel;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * docs/Backend_v2.1_REST_API_Specification.md §6 — Send Reminder
 * (POST /reminders/{reminder_id}/send), the Reminder List/Details inline
 * quick-send action. Distinct from the shared Send via WhatsApp/SMS
 * endpoints (§8), which SendMessageRequest covers.
 */
class SendReminderRequest extends FormRequest
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
            'channel' => ['required', 'string', Rule::in(array_column(MessageChannel::cases(), 'value'))],
            'template_id' => ['required', 'string'],
        ];
    }
}
