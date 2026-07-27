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
        ];
    }
}
