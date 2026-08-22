<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Backend Completion Roadmap, Phase 3.3 (Product Owner correction, later
 * revised by the Manual Mobile-Money Subscription Payment Flow decision):
 * `payment_phone` — the mobile-money number the payment was sent from —
 * is now required. `payment_reference` (the transaction reference) is
 * optional: the approved UX flow lets a Business Owner submit the request
 * before completing the external mobile-money transaction, so the
 * reference may not exist yet at submission time.
 */
class SubscriptionUpgradeRequestRequest extends FormRequest
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
            'requested_plan_id' => ['required', 'string', 'exists:subscription_plans,id'],
            'payment_phone' => ['required', 'string', 'max:20'],
            'payment_reference' => ['nullable', 'string', 'max:100'],
        ];
    }
}
