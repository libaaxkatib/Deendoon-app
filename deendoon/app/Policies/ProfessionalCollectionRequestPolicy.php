<?php

namespace App\Policies;

use App\Models\ProfessionalCollectionRequest;
use App\Models\User;
use App\Services\ProfessionalCollectionRequestService;

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

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): Supporting Documents — both the auto-linked existing
     * Customer/Debt documents and newly uploaded attachments are visible
     * to the same two parties as everything else on this Request.
     */
    public function viewDocuments(User $user, ProfessionalCollectionRequest $request): bool
    {
        return $this->isPlatformAdmin($user) || $this->isTenantActor($user);
    }

    /**
     * Transfer Case to Deendoon Recovery Team — Attachment Authorization
     * (Product Owner-approved staged decision, refined by a follow-up
     * clarification): a clean, three-phase hand-off, not a dual-actor
     * window like postMessage()/viewDocuments().
     *
     *  1. Pre-Assigned (`submitted`, `under_review`,
     *     `need_more_information`, `accepted`) — only the submitting
     *     tenant may upload.
     *  2. Assigned / active recovery (`assigned`, `in_progress`) — only
     *     the Deendoon Platform Administrator may upload.
     *  3. Terminal (`recovered`, `closed`) — nobody may upload. The
     *     follow-up clarification is explicit: "A closed Professional
     *     Collection Request represents a finalized case. Evidence must
     *     remain immutable after closure to preserve auditability and
     *     legal integrity" — this reuses the exact TERMINAL_STATUSES
     *     concept {@see ProfessionalCollectionRequestService}
     *     already applies to every other closing action on this Request,
     *     rather than treating "Closed" as a fourth, novel state.
     *
     * Read/download access (viewDocuments()) is deliberately untouched by
     * any of this — the Business Owner keeps that throughout the
     * Request's entire lifecycle, including after closure, regardless of
     * upload rights ("Read and download remain available according to
     * existing permissions").
     *
     * Interpretation note (unchanged from the original staged decision):
     * "Pending Review"/"Documents Verified" have no corresponding value
     * in this Request's own `status` column (they are Professional
     * Collection Timeline event-type labels, a separate, more granular
     * log) — gating on the Timeline instead of `status` would itself be
     * a second, parallel authorization signal, which this decision's own
     * rule 6 forbids. Both phases are therefore read as the existing
     * pre-Assigned statuses in `status`'s own approved sequence.
     */
    public function uploadAttachment(User $user, ProfessionalCollectionRequest $request): bool
    {
        if (in_array($request->status, ['recovered', 'closed'], true)) {
            return false;
        }

        $isAssignedOrLater = in_array($request->status, ['assigned', 'in_progress'], true);

        if ($this->isPlatformAdmin($user)) {
            return $isAssignedOrLater;
        }

        return $this->isTenantActor($user) && ! $isAssignedOrLater;
    }

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): "Business Owners may view the timeline. Recovery Team
     * members may create/update timeline events according to
     * permissions." Viewing follows the same dual-actor rule as the rest
     * of the Request; creating/updating is Deendoon Platform
     * Administrator-only, matching transitionStatus()/close()'s existing
     * "only the Recovery Team acts" pattern exactly.
     */
    public function viewTimeline(User $user, ProfessionalCollectionRequest $request): bool
    {
        return $this->isPlatformAdmin($user) || $this->isTenantActor($user);
    }

    public function createTimelineEvent(User $user): bool
    {
        return $this->isPlatformAdmin($user);
    }

    public function updateTimelineEvent(User $user): bool
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
