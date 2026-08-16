<?php

namespace App\Policies;

use App\Models\SupportTicket;
use App\Models\User;

/**
 * Bimodal by design, matching ProfessionalCollectionRequestPolicy exactly:
 * the tenant's Business Owner (role `admin`) may create their own tenant's
 * tickets and reply to them; the Deendoon Platform Administrator may view
 * any ticket cross-tenant and holds the exclusive authority to change its
 * status, close it, or reopen it (Decisions 2/9). Tenant-vs-platform-admin
 * scoping itself (which rows are visible at all) is enforced in the
 * controller, since SupportTicket deliberately has no BelongsToTenant scope
 * to fall back on — this class only gates *actions* on a ticket the
 * controller has already resolved and confirmed the caller may see.
 */
class SupportTicketPolicy
{
    public function create(User $user): bool
    {
        return $this->isTenantActor($user);
    }

    public function view(User $user, SupportTicket $ticket): bool
    {
        return $this->isPlatformAdmin($user) || $this->isTenantActor($user);
    }

    public function reply(User $user, SupportTicket $ticket): bool
    {
        return $this->isPlatformAdmin($user) || $this->isTenantActor($user);
    }

    public function uploadAttachment(User $user, SupportTicket $ticket): bool
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

    public function reopen(User $user): bool
    {
        return $this->isPlatformAdmin($user);
    }

    public function isPlatformAdmin(User $user): bool
    {
        return $user->isPlatformAdmin();
    }

    private function isTenantActor(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
