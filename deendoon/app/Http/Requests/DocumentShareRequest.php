<?php

namespace App\Http\Requests;

use App\Enums\MessageChannel;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * docs/Mobile_UI_V1_Frozen.md §8.8 — recipient phone is resolved from the
 * document's own customer (see MessageRenderingService::renderForDocument),
 * not accepted as a client-supplied field, consistent with how Reminder
 * sending (Sprint 3) already resolves the recipient rather than trusting
 * an arbitrary phone number from the request.
 */
class DocumentShareRequest extends FormRequest
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
