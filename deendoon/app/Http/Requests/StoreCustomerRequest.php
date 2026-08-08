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
            // FR-007/BR-034 (Business Owner Backend Completion): when
            // omitted, CustomerController::store() applies the tenant's
            // configured SystemSetting::default_credit_limit instead.
            'credit_limit' => ['sometimes', 'numeric', 'min:0', 'max:9999999999.99'],
        ];
    }
}
