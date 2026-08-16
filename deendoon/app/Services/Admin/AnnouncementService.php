<?php

namespace App\Services\Admin;

use App\Enums\AuditAction;
use App\Enums\NotificationType;
use App\Models\Announcement;
use App\Models\Tenant;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\NotificationService;
use Illuminate\Support\Str;

/**
 * Module 9 — Admin Announcements. Reuses the existing NotificationService
 * write path rather than creating a parallel one — an announcement is a
 * Notification of type `admin_announcement` with admin-authored
 * title/message, fanned out via notifyMany() to every recipient tenant's
 * Business Owner(s). One AuditLog entry per tenant is recorded, matching
 * the convention every other admin status-changing action already
 * follows (e.g. AdminTenantController::suspend()/activate()).
 *
 * Module 9 follow-up — Announcement History: one Announcement row is also
 * written per successful send (see that model's docblock for why this
 * table exists separately from Notification/AuditLog). Only written when
 * at least one recipient was actually notified — a send that reaches
 * nobody (e.g. every selected tenant has no users) leaves no Notification
 * or AuditLog rows either, and History must represent announcements that
 * were actually sent, not merely attempted.
 */
class AnnouncementService
{
    public function __construct(
        private readonly NotificationService $notifications,
        private readonly AuditLogService $auditLog,
    ) {}

    /**
     * @param  array<int, string>  $tenantIds  ignored when $scope === 'all'
     * @return int total recipients notified
     */
    public function send(string $scope, array $tenantIds, string $title, string $message, User $actor): int
    {
        $tenants = $scope === 'all'
            ? Tenant::with('users')->get()
            : Tenant::with('users')->whereIn('id', $tenantIds)->get();

        $batchId = (string) Str::ulid();
        $recipientCount = 0;

        foreach ($tenants as $tenant) {
            if ($tenant->users->isEmpty()) {
                continue;
            }

            $this->notifications->notifyMany(
                $tenant->id,
                $tenant->users,
                NotificationType::AdminAnnouncement,
                'announcement',
                $batchId,
                $title,
                $message,
            );

            $this->auditLog->record(
                AuditAction::Created,
                'announcement',
                $batchId,
                $actor,
                $title,
                $tenant->id,
            );

            $recipientCount += $tenant->users->count();
        }

        if ($recipientCount > 0) {
            $announcement = new Announcement([
                'title' => $title,
                'message' => $message,
                'scope' => $scope,
                'recipient_count' => $recipientCount,
                'sent_by_user_id' => (string) $actor->id,
                'sent_at' => now(),
            ]);
            $announcement->id = $batchId;
            $announcement->save();
        }

        return $recipientCount;
    }
}
