<?php

namespace App\Models\Concerns;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Auth;

/**
 * Backend Completion Roadmap, Phase 3.2 (Product Owner Decision: Option B
 * — Conditional Global Scope). Structural tenant isolation for the
 * Subscription domain models (TenantSubscription, SubscriptionChangeRequest,
 * StorageAddon) that must remain visible to the Deendoon Platform
 * Administrator across every tenant for the approved Manual Payment
 * Review workflow — the one respect in which they can't simply use
 * {@see BelongsToTenant}, whose fail-closed behavior for a null-tenant
 * actor (`WHERE tenant_id IS NULL`, matching nothing) is exactly correct
 * for ordinary tenant-owned data but exactly wrong here.
 *
 * Unlike {@see BelongsToTenant}, this trait does NOT auto-assign
 * tenant_id on creation — these models are bimodal (a Platform
 * Administrator acting on a specific tenant's row is not "their own"
 * tenant), so tenant_id must always be set via explicit property
 * assignment in the writing service, matching
 * ProfessionalCollectionRequestService::submit()'s established pattern.
 * `tenant_id` is excluded from every one of these 3 models' Fillable
 * lists for the same reason.
 *
 * Behavior:
 * - No authenticated user (console/job/test context): no filter, matching
 *   BelongsToTenant's identical unauthenticated-context behavior.
 * - Ordinary tenant user: filtered to their own tenant_id — automatic,
 *   structural, cannot be forgotten by a future controller/service.
 * - Deendoon Platform Administrator ({@see User::isPlatformAdmin()}):
 *   no filter at all — sees every tenant's rows, as the approved Manual
 *   Payment Review workflow requires.
 */
trait BelongsToTenantOrPlatformAdmin
{
    protected static function bootBelongsToTenantOrPlatformAdmin(): void
    {
        static::addGlobalScope('tenant', function (Builder $builder) {
            $user = Auth::guard('sanctum')->user();

            if ($user === null || $user->isPlatformAdmin()) {
                return;
            }

            $builder->where($builder->getModel()->getTable().'.tenant_id', $user->tenant_id);
        });
    }
}
