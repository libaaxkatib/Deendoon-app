<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecordPromiseToPayRequest extends FormRequest
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
            'promised_date' => ['required', 'date', 'after_or_equal:today'],
        ];
    }
}
