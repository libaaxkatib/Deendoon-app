<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenantOrPlatformAdmin;
use Database\Factories\SubscriptionChangeRequestFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Backend Completion Roadmap, Phase 3.2 (Product Owner Decision: Option B
 * — Conditional Global Scope). Backs the approved Manual Payment workflow
 * (Request -> Pending -> Administrator Review -> Approve/Reject ->
 * Activate). Uses BelongsToTenantOrPlatformAdmin, for the same
 * Platform-Administrator cross-tenant review reason documented on
 * {@see TenantSubscription}. `tenant_id`/`reviewed_by` are excluded from
 * Fillable and must be set via direct property assignment, matching
 * ProfessionalCollectionRequest's established pattern.
 */
#[Fillable(['requested_plan_id', 'current_plan_id', 'payment_reference', 'status', 'requested_at', 'reviewed_by', 'reviewed_at', 'rejection_reason'])]
class SubscriptionChangeRequest extends Model
{
    /** @use HasFactory<SubscriptionChangeRequestFactory> */
    use BelongsToTenantOrPlatformAdmin, HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'requested_at' => 'datetime',
            'reviewed_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function requestedPlan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'requested_plan_id');
    }

    public function currentPlan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'current_plan_id');
    }
}
