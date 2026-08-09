<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Final Product Completion Roadmap, P1.6 — mirrors
 * `UploadProfessionalCollectionAttachmentRequest`'s exact file-validation
 * convention. Also backs Scan Invoice/Upload Invoice (P2.6/P2.7), which
 * reuse this exact endpoint as pure storage.
 */
class UploadDebtAttachmentRequest extends FormRequest
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
            'description' => ['nullable', 'string', 'max:255'],
        ];
    }
}
