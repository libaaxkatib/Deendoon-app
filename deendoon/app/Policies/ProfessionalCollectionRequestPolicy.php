<?php

namespace App\Policies;

use App\Models\ProfessionalCollectionRequest;
use App\Models\User;

/**
 * Bimodal by design (06 §2, BR-042; 08 §5): the tenant's Business Owner
 * (role `admin` — the only tenant-side account type in Version 1) may act
 * on their own tenant's Requests; the Deendoon Platform Administrator may
 * view any Request and holds the exclusive authority to transition its
 * status or close it. "Collection Officer" is not an authentication role
 * anywhere in this policy — it is Deendoon's own internal operational
 * responsibility, exercised by Platform Administrator staff only after a
 * Request has been accepted, and has no bearing on who may submit,
 * view, or message on a Request. Tenant-vs-platform-admin scoping itself
 * (which rows are visible at all) is enforced in the controller, since
 * ProfessionalCollectionRequest deliberately has no BelongsToTenant scope
 * to fall back on — this class only gates *actions* on a request the
 * controller has already resolved and confirmed the caller may see.
 */
class ProfessionalCollectionRequestPolicy
{
    public function submit(User $user): bool
    {
        return $this->isTenantActor($user);
    }

    public function view(User $user, ProfessionalCollectionRequest $request): bool
    {
        return $this->isPlatformAdmin($user) || $this->isTenantActor($user);
    }

    public function postMessage(User $user, ProfessionalCollectionRequest $request): bool
    {
        return $this->isPlatformAdmin($user) || $this->isTenantActor($user);
    }

    public function transitionStatus(User $user): bool
    {
        return $this->isPlatformAdmin($user);
    }

    public function close(User $user): bool
    {
        return $this->isPlatformAdmin($user);
    }

    public function isPlatformAdmin(User $user): bool
    {
        return $user->tenant_id === null && $user->hasRole('deendoon_platform_administrator');
    }

    private function isTenantActor(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
