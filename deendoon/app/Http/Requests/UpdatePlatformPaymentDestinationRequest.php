<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Manual Mobile-Money Subscription Payment Flow (Product Owner decision):
 * the Platform Administrator sets the platform-level destination
 * mobile-money number shown to Business Owners on the "Send Money" step.
 */
class UpdatePlatformPaymentDestinationRequest extends FormRequest
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
            'destination_mobile_money_number' => ['required', 'string', 'max:20'],
        ];
    }
}
