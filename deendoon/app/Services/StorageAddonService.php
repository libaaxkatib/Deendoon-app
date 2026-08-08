<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\NotificationType;
use App\Models\StorageAddon;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

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
 *
 * Phase 3.4 adds exactly one write: {@see requestAddon()}, the Manual
 * Payment Workflow's request-creation step. Creates a pending
 * StorageAddon only — no approval or activation.
 */
class StorageAddonService
{
    /**
     * Approved Storage Add-on pricing (Product Owner decision) — the
     * sole server-side source of truth for storage_size/monthly_price.
     * Moved here from SubscriptionController in Phase 3.4: pricing
     * derivation is business logic and belongs in the service that owns
     * the write, not the controller.
     *
     * @var array<string, array{size: int, price: float}>
     */
    private const PACKAGES = [
        '10gb' => ['size' => 10, 'price' => 2],
        '25gb' => ['size' => 25, 'price' => 4],
        '50gb' => ['size' => 50, 'price' => 7],
        '100gb' => ['size' => 100, 'price' => 12],
    ];

    public function __construct(
        private readonly SubscriptionService $subscriptions,
        private readonly AuditLogService $auditLog,
        private readonly NotificationService $notifications,
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

    /**
     * Manual Payment Workflow, step 3-4: Business Owner submits
     * storage_package + payment_reference; system creates a pending
     * StorageAddon. `storage_size`/`monthly_price` are always derived
     * from {@see PACKAGES}, never trusted from client input. No
     * approval, no activation.
     *
     * Rejects (409) only when a *pending* request already exists for
     * this tenant (Product Owner confirmation: approved and rejected
     * requests never block a new one) — any pending storage_addons row,
     * regardless of package, matching the approved rule's generic "a
     * pending Storage request exists" phrasing rather than a per-package
     * check.
     *
     * The audit entry's `reason` carries `storage_package` and
     * `payment_reference` (tenant_id is already the audit_log row's own
     * dedicated column) — same reasoning as
     * SubscriptionService::requestUpgrade()'s identical choice.
     *
     * The `exists()` check alone cannot prevent a concurrent-request race
     * (see SubscriptionService::requestUpgrade()'s identical note) — the
     * database-level partial unique index
     * `storage_addons_one_pending_per_tenant` (Phase 3.5 mandatory fix)
     * is the actual safety net; a race that slips past the check is
     * caught here and converted to the identical 409 response.
     */
    public function requestAddon(Tenant $tenant, string $storagePackage, string $paymentReference, User $actor): StorageAddon
    {
        return DB::transaction(function () use ($tenant, $storagePackage, $paymentReference, $actor) {
            if (StorageAddon::where('tenant_id', $tenant->id)->where('status', 'pending')->exists()) {
                $this->conflict('A pending Storage Add-on Request already exists for this tenant.');
            }

            $package = self::PACKAGES[$storagePackage];

            $addon = new StorageAddon([
                'storage_package' => $storagePackage,
                'storage_size' => $package['size'],
                'monthly_price' => $package['price'],
                'payment_reference' => $paymentReference,
                'status' => 'pending',
            ]);
            $addon->tenant_id = $tenant->id;

            try {
                $addon->save();
            } catch (UniqueConstraintViolationException) {
                $this->conflict('A pending Storage Add-on Request already exists for this tenant.');
            }

            $this->auditLog->record(
                AuditAction::StorageAddonRequested,
                'storage_addon',
                $addon->id,
                $actor,
                "storage_package={$storagePackage}; payment_reference={$paymentReference}",
                $tenant->id,
            );

            return $addon->refresh();
        });
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record): the Deendoon Platform
     * Administrator approves a pending Storage Add-on request — same
     * manual-payment activation pattern as
     * {@see SubscriptionService::approve()}. 1-month billing cycle
     * (confirmed by the Product Owner, applied symmetrically here since
     * Storage Add-ons are billed the same way — `monthly_price`):
     * `started_at` = now, `expires_at` = now + 1 month. No plan-equality
     * guard here — unlike Subscription Change Requests, a tenant may
     * legitimately stack multiple active add-ons of the same or different
     * package (Phase 3.1: no "at most one active add-on" constraint).
     */
    public function approve(StorageAddon $addon, User $actor): StorageAddon
    {
        return DB::transaction(function () use ($addon, $actor) {
            $addon = StorageAddon::where('id', $addon->id)->lockForUpdate()->first();

            if ($addon === null || $addon->status !== 'pending') {
                $this->conflict('Only a pending Storage Add-on request may be approved.');
            }

            $addon->update([
                'status' => 'active',
                'started_at' => now(),
                'expires_at' => now()->addMonth(),
                'approved_by' => $actor->id,
                'approved_at' => now(),
            ]);

            $this->auditLog->record(
                AuditAction::StorageAddonStatusChanged,
                'storage_addon',
                $addon->id,
                $actor,
                'status changed from pending to active',
                $addon->tenant_id,
            );

            $this->notifyTenantOwner($addon);

            return $addon->refresh();
        });
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record): the Deendoon Platform
     * Administrator rejects a pending Storage Add-on request. Same
     * predefined multi-select Rejection Reasons + optional free-text notes
     * pattern as {@see SubscriptionService::reject()}.
     *
     * @param  array<int, string>  $reasonLabels
     */
    public function reject(StorageAddon $addon, array $reasonLabels, ?string $notes, User $actor): StorageAddon
    {
        return DB::transaction(function () use ($addon, $reasonLabels, $notes, $actor) {
            $addon = StorageAddon::where('id', $addon->id)->lockForUpdate()->first();

            if ($addon === null || $addon->status !== 'pending') {
                $this->conflict('Only a pending Storage Add-on request may be rejected.');
            }

            $addon->update([
                'status' => 'rejected',
                'rejection_reason' => $notes,
            ]);

            foreach (array_unique($reasonLabels) as $label) {
                $addon->reasons()->create(['reason_label' => $label]);
            }

            $this->auditLog->record(
                AuditAction::StorageAddonStatusChanged,
                'storage_addon',
                $addon->id,
                $actor,
                'status changed from pending to rejected',
                $addon->tenant_id,
            );

            $this->notifyTenantOwner($addon);

            return $addon->refresh();
        });
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record): the Business Owner cancels their
     * own still-pending Storage Add-on request before it has been
     * reviewed.
     */
    public function cancel(StorageAddon $addon, User $actor): StorageAddon
    {
        return DB::transaction(function () use ($addon, $actor) {
            $addon = StorageAddon::where('id', $addon->id)->lockForUpdate()->first();

            if ($addon === null || $addon->status !== 'pending') {
                $this->conflict('Only a pending Storage Add-on request may be cancelled.');
            }

            $addon->update(['status' => 'cancelled']);

            $this->auditLog->record(
                AuditAction::StorageAddonStatusChanged,
                'storage_addon',
                $addon->id,
                $actor,
                'status changed from pending to cancelled',
                $addon->tenant_id,
            );

            return $addon->refresh();
        });
    }

    /**
     * Same reasoning as {@see SubscriptionService::notifyTenantOwner()} —
     * StorageAddon carries no `submitted_by_user_id` of its own; Version 1
     * has exactly one account per tenant.
     */
    private function notifyTenantOwner(StorageAddon $addon): void
    {
        $recipientId = User::where('tenant_id', $addon->tenant_id)->value('id');

        if ($recipientId !== null) {
            $this->notifications->notify(
                $addon->tenant_id,
                (string) $recipientId,
                NotificationType::StorageRequestUpdate,
                'storage_addon',
                $addon->id,
            );
        }
    }

    private function conflict(string $message): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
            'errors' => null,
        ], 409));
    }
}
