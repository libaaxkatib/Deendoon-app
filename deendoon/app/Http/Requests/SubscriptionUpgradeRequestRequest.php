<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Backend Completion Roadmap, Phase 3.3 (Product Owner correction):
 * payment_reference is required — a Subscription Upgrade Request cannot
 * be created without one.
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
            'payment_reference' => ['required', 'string', 'max:100'],
        ];
    }
}
