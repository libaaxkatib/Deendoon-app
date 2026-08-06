<?php

namespace App\Services;

use App\Models\StorageAddon;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Collection;

/**
 * Backend Completion Roadmap, Phase 3.2. Read-only Storage Add-on domain
 * queries only — no writes, no approval/rejection, no enforcement.
 *
 * `activeAddons()` returns a collection rather than a single add-on: the
 * Phase 3.1 schema deliberately allows a tenant to accumulate multiple
 * `storage_addons` rows over time with no "at most one active" constraint
 * (no such rule has been approved), and `totalStorageAllowance()`
 * explicitly needs to sum across however many are currently active — a
 * singular "the active add-on" wouldn't be consistent with that.
 *
 * Explicitly filters by `tenant_id` in addition to relying on
 * {@see StorageAddon}'s automatic BelongsToTenantOrPlatformAdmin scope,
 * for the same complementary reason documented on SubscriptionService.
 */
class StorageAddonService
{
    public function __construct(
        private readonly SubscriptionService $subscriptions,
    ) {}

    /**
     * @return Collection<int, StorageAddon>
     */
    public function activeAddons(Tenant $tenant): Collection
    {
        return StorageAddon::where('tenant_id', $tenant->id)->where('status', 'active')->get();
    }

    /**
     * Plan's base storage_limit plus every currently-active add-on's
     * storage_size. Null when the tenant has no subscription/plan at all
     * (see SubscriptionService::storageLimit()'s docblock) — never
     * silently treated as zero.
     */
    public function totalStorageAllowance(Tenant $tenant): ?int
    {
        $planLimit = $this->subscriptions->storageLimit($tenant);

        if ($planLimit === null) {
            return null;
        }

        return $planLimit + $this->activeAddons($tenant)->sum('storage_size');
    }

    public function addonStatus(StorageAddon $addon): string
    {
        return $addon->status;
    }
}
