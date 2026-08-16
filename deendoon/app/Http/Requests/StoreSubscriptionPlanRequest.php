<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Module 11 — Settings, Subscription Plan management. `authorize()`
 * returns true because access is already restricted at the route level
 * by the `can:platform-admin-only` middleware, matching every other
 * Admin FormRequest in this codebase. `customer_limit` is deliberately
 * nullable — null represents the approved "Unlimited customers" plan
 * tier (see SubscriptionPlan's own docblock), not a missing value.
 */
class StoreSubscriptionPlanRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:50', Rule::unique('subscription_plans', 'name')],
            'monthly_price' => ['required', 'numeric', 'min:0', 'max:999999.99'],
            'customer_limit' => ['nullable', 'integer', 'min:1'],
            'storage_limit' => ['required', 'integer', 'min:1'],
            'analytics_enabled' => ['sometimes', 'boolean'],
        ];
    }
}
