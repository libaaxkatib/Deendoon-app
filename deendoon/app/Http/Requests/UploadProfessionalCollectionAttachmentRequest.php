<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): "Additional Supporting Documents that are specific to the
 * Professional Collection Request." Mirrors UpdateCompanyProfileRequest's
 * existing file-validation convention (explicit allow-list, not a bare
 * "file" rule), broadened for document uploads rather than a logo image.
 */
class UploadProfessionalCollectionAttachmentRequest extends FormRequest
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
            'file' => ['required', 'file', 'mimes:pdf,jpg,jpeg,png,doc,docx', 'max:10240'],
            'timeline_event_id' => ['nullable', 'string', 'exists:professional_collection_timeline_events,id'],
        ];
    }
}
