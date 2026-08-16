<?php

namespace App\Policies;

use App\Models\Tenant;
use App\Models\User;

/**
 * Admin Panel — Business Management (Product Owner decision): the Deendoon
 * Platform Administrator can view every tenant and suspend/reactivate one.
 * No Business Owner (tenant-scoped `admin`) capability is granted here —
 * a tenant never manages other tenants, matching every other cross-tenant
 * policy in this codebase (e.g. ProfessionalCollectionRequestPolicy).
 */
class TenantPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isPlatformAdmin();
    }

    public function view(User $user, Tenant $tenant): bool
    {
        return $user->isPlatformAdmin();
    }

    public function suspend(User $user, Tenant $tenant): bool
    {
        return $user->isPlatformAdmin();
    }

    public function activate(User $user, Tenant $tenant): bool
    {
        return $user->isPlatformAdmin();
    }
}
