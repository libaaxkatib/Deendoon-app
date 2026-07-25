<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateCustomerStatusRequest extends FormRequest
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
            'customer_status' => ['required', 'string', Rule::in([
                'active', 'good_standing', 'late_payer', 'high_risk', 'in_collection', 'recovered', 'blocked',
            ])],
        ];
    }
}
