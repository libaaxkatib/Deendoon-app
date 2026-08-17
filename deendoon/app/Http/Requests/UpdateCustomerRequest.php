<?php

namespace App\Http\Requests;

use App\Services\CustomerPhoneNumberService;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;

class UpdateCustomerRequest extends FormRequest
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
            'address' => ['nullable', 'string', 'max:500'],
            'credit_limit' => ['required', 'numeric', 'min:0', 'max:9999999999.99'],
            // Fix #23 — optional; when omitted entirely, `phone` above is
            // treated as the sole primary entry (an older mobile client
            // that has never heard of this field keeps working as-is).
            'phone_numbers' => ['sometimes', 'array'],
            'phone_numbers.*.id' => ['nullable', 'string'],
            'phone_numbers.*.phone' => ['required', 'string', 'max:30'],
            'phone_numbers.*.is_primary' => ['required', 'boolean'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            $service = app(CustomerPhoneNumberService::class);
            $entries = $service->normalizeEntries([
                'phone' => $this->input('phone'),
                'phone_numbers' => $this->input('phone_numbers'),
            ]);
            foreach ($service->validationErrors($entries) as $message) {
                $validator->errors()->add('phone_numbers', $message);
            }
        });
    }
}
