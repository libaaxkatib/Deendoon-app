<?php

namespace App\Policies;

use App\Models\CollectionCase;
use App\Models\User;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): Collection Case management is a Business
 * Owner capability (role `admin`). Collection Officer is not an
 * authentication role in Version 1 — it is an internal Deendoon
 * operational responsibility exercised only after a Professional
 * Collection Request has been accepted (see
 * ProfessionalCollectionRequestPolicy), never a tenant-side role.
 */
class CollectionCasePolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, CollectionCase $case): bool
    {
        return $this->isAuthorized($user);
    }

    public function manage(User $user, CollectionCase $case): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
