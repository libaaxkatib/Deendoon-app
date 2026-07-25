<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-030: covers the WhatsApp and SMS manual reminder endpoints. Records
 * that the action was taken — actual message delivery via a real
 * WhatsApp/SMS provider is out of scope (Notifications Delivery).
 */
class SendManualReminderRequest extends FormRequest
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
            'details' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
