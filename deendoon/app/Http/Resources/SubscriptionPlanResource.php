<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Backend Completion Roadmap, Phase 3.3 (Product Owner corrections):
 *
 * `trial_eligible`: determined from tenant history, not plan identity.
 * `tenant_subscriptions.tenant_id` is unique (Phase 3.1 — one row per
 * tenant, ever), so "has this tenant ever started a Trial" reduces to a
 * single check of that one row's `trial_started_at`. False once they
 * have; true otherwise, including a tenant with no subscription record
 * at all (never started anything). Identical across every plan in a
 * given response, since it depends on the authenticated tenant, not the
 * individual plan row — kept as a per-plan field only because the
 * approved endpoint spec lists it there.
 *
 * `features`: no configured features data exists on subscription_plans.
 * Returns an empty array rather than inventing feature descriptions.
 */
class SubscriptionPlanResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $tenant = $request->user()?->tenant;
        $hasStartedTrialBefore = $tenant?->subscription?->trial_started_at !== null;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'monthly_price' => $this->monthly_price,
            'customer_limit' => $this->customer_limit,
            'storage_limit' => $this->storage_limit,
            'analytics_enabled' => $this->analytics_enabled,
            'trial_eligible' => ! $hasStartedTrialBefore,
            'features' => [],
        ];
    }
}
