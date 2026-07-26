<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * FR-068. Company Profile & Branding — these ARE the fields already on
 * the `tenants` table (business_name, logo_path, address, contact_email,
 * contact_phone), per 06 §3's confirmation reused since Module 8. Product
 * Owner ruling on the FR-068 E2 open item: logo is JPEG/PNG, 2MB max.
 */
class UpdateCompanyProfileRequest extends FormRequest
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
            'business_name' => ['required', 'string', 'max:255'],
            'logo' => ['nullable', 'file', 'mimes:jpeg,jpg,png', 'max:2048'],
            'address' => ['nullable', 'string', 'max:500'],
            'contact_email' => ['nullable', 'string', 'email', 'max:255'],
            'contact_phone' => ['nullable', 'string', 'max:30'],
        ];
    }
}
