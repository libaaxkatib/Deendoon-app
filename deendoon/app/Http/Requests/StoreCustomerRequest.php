<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'name' => trim((string) $this->input('name')),
            'phone' => trim((string) $this->input('phone')),
            'address' => $this->filled('address') ? trim((string) $this->input('address')) : null,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:30'],
            // Item 13 (mobile Client Visit Navigate): optional — most
            // existing customers won't have one, not required by FR-007.
            'address' => ['nullable', 'string', 'max:500'],
            // FR-007/BR-034 (Business Owner Backend Completion): when
            // omitted, CustomerController::store() applies the tenant's
            // configured SystemSetting::default_credit_limit instead.
            'credit_limit' => ['sometimes', 'numeric', 'min:0', 'max:9999999999.99'],
        ];
    }
}
