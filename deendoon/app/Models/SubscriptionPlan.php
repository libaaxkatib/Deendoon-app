<?php

namespace App\Models;

use Database\Factories\SubscriptionPlanFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Backend Completion Roadmap, Phase 3.2. A global reference/catalog table
 * (Trial, Free, Small Business, Medium Business, Corporate) shared
 * platform-wide — deliberately NOT tenant-scoped; there is no `tenant_id`
 * column to scope by (see the Phase 3.1 migration).
 *
 * `customer_limit` is nullable: NULL represents Corporate's approved
 * "Unlimited customers," not a missing value.
 */
#[Fillable(['name', 'customer_limit', 'analytics_enabled', 'storage_limit', 'monthly_price', 'active'])]
class SubscriptionPlan extends Model
{
    /** @use HasFactory<SubscriptionPlanFactory> */
    use HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'customer_limit' => 'integer',
            'analytics_enabled' => 'boolean',
            'storage_limit' => 'integer',
            'monthly_price' => 'decimal:2',
            'active' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function tenantSubscriptions(): HasMany
    {
        return $this->hasMany(TenantSubscription::class, 'plan_id');
    }

    /**
     * Requests where this plan was the one being requested (upgrade/
     * downgrade target) — distinct from {@see currentInChangeRequests()},
     * since `subscription_change_requests` has two separate foreign keys
     * into this table.
     */
    public function requestedInChangeRequests(): HasMany
    {
        return $this->hasMany(SubscriptionChangeRequest::class, 'requested_plan_id');
    }

    /**
     * Requests where this plan was the tenant's plan at the time of the
     * request (the historical "current" snapshot), not the target.
     */
    public function currentInChangeRequests(): HasMany
    {
        return $this->hasMany(SubscriptionChangeRequest::class, 'current_plan_id');
    }
}
