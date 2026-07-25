<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecordPaymentRequest extends FormRequest
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
            'amount' => ['required', 'numeric', 'gt:0', 'max:9999999999.99'],
            'payment_date' => ['required', 'date'],
            'payment_method' => ['nullable', 'string', 'max:50'],
            'reference_notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}
