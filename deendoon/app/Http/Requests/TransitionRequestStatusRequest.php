<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validates only that the submitted value is one of BRL-079's 8 approved
 * status values (a genuine, syntactically valid status). Whether THIS
 * specific transition is currently allowed (the sequence/cycle matrix) is
 * a business-state concern, enforced by ProfessionalCollectionRequestService
 * with a 409 CONFLICT — not a 422 field-validation concern.
 */
class TransitionRequestStatusRequest extends FormRequest
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
            'status' => ['required', 'string', Rule::in([
                'submitted', 'under_review', 'need_more_information', 'accepted',
                'assigned', 'in_progress', 'recovered', 'closed',
            ])],
        ];
    }
}
