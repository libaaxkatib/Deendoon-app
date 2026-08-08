<?php

namespace App\Http\Requests;

use App\Enums\ProfessionalCollectionTimelineEventType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfessionalCollectionTimelineEventRequest extends FormRequest
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
            'event_type' => ['sometimes', 'string', Rule::in(array_column(ProfessionalCollectionTimelineEventType::cases(), 'value'))],
            'occurred_at' => ['sometimes', 'date'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'outcome' => ['sometimes', 'nullable', 'string', 'max:50'],
        ];
    }
}
