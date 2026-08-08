<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-043 ("Update a Collection Case's non-financial details"),
 * PUT /collection-cases/{id} (07_API_Design.md §5.4). Business Owner
 * Backend Completion (pre-Phase 5): `notes` is the one editable field —
 * a free-text case annotation distinct from the chronological
 * follow_up_history activity log recordActivity() writes. Assignment
 * (FR-041) is retired and Closure (FR-045) owns its own dedicated
 * endpoint, so neither belongs here.
 */
class UpdateCollectionCaseRequest extends FormRequest
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
            'notes' => ['nullable', 'string'],
        ];
    }
}
