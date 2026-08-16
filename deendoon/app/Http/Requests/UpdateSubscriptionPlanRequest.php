<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Module 11 — Settings, Subscription Plan management. Same rules as
 * StoreSubscriptionPlanRequest, except the uniqueness check ignores the
 * plan being edited.
 */
class UpdateSubscriptionPlanRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:50', Rule::unique('subscription_plans', 'name')->ignore($this->route('subscriptionPlan'))],
            'monthly_price' => ['required', 'numeric', 'min:0', 'max:999999.99'],
            'customer_limit' => ['nullable', 'integer', 'min:1'],
            'storage_limit' => ['required', 'integer', 'min:1'],
            'analytics_enabled' => ['sometimes', 'boolean'],
        ];
    }
}
