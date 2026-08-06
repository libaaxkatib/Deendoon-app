<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenantOrPlatformAdmin;
use Database\Factories\TenantSubscriptionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Backend Completion Roadmap, Phase 3.2 (Product Owner Decision: Option B
 * — Conditional Global Scope). Uses BelongsToTenantOrPlatformAdmin rather
 * than BelongsToTenant: the approved Manual Payment workflow requires the
 * Deendoon Platform Administrator to review any tenant's current plan/
 * status while approving that tenant's SubscriptionChangeRequest, which
 * BelongsToTenant's fail-closed, always-scope-to-the-actor's-own-tenant
 * behavior cannot provide. See that trait's docblock for the full
 * behavior (auto-restrict for tenant users, auto-bypass for the Platform
 * Administrator, structural rather than reliant on every caller
 * remembering to filter).
 *
 * `tenant_id` is excluded from Fillable (matching every other tenant-
 * scoped model in this codebase) and must be set via direct property
 * assignment, never mass assignment — see
 * ProfessionalCollectionRequestService::submit() for the established
 * pattern this follows.
 */
#[Fillable(['plan_id', 'status', 'started_at', 'expires_at', 'trial_started_at', 'trial_ends_at', 'approved_by', 'approved_at'])]
class TenantSubscription extends Model
{
    /** @use HasFactory<TenantSubscriptionFactory> */
    use BelongsToTenantOrPlatformAdmin, HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'expires_at' => 'datetime',
            'trial_started_at' => 'datetime',
            'trial_ends_at' => 'datetime',
            'approved_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'plan_id');
    }
}
