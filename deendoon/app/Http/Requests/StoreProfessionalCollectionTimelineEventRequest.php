<?php

namespace App\Http\Requests;

use App\Enums\ProfessionalCollectionTimelineEventType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision). `officer` is never a client-supplied field — the recording
 * officer is always the authenticated actor (ProfessionalCollectionTimelineController
 * ::store() passes $request->user()), the same convention every other
 * actor-attributed record in this codebase already follows.
 */
class StoreProfessionalCollectionTimelineEventRequest extends FormRequest
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
            'event_type' => ['required', 'string', Rule::in(array_column(ProfessionalCollectionTimelineEventType::cases(), 'value'))],
            'occurred_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'outcome' => ['nullable', 'string', 'max:50'],
            'attachments' => ['nullable', 'array'],
            'attachments.*' => ['file', 'mimes:pdf,jpg,jpeg,png,doc,docx', 'max:10240'],
        ];
    }
}
