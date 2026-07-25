<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-043 ("Update a Collection Case's non-financial details") has a route
 * (PUT /collection-cases/{id}, 07_API_Design.md §5.4) but 06's approved
 * collection_cases schema has no additional editable field beyond what
 * FR-041 (assignment) and FR-045 (closure) already own via their own
 * dedicated endpoints — Notes & Attachments belong to Module 8, out of
 * scope. This is a genuine, flagged SRS/schema gap, not an omission: no
 * field is validated here because none is approved to exist yet.
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
        return [];
    }
}
