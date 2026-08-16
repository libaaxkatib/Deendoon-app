<?php

namespace App\Policies;

use App\Models\SupportTicketAttachment;
use App\Models\User;

/**
 * Mobile Fix #4A (Attachment Delete): bimodal, matching
 * `SupportTicketPolicy::uploadAttachment` — either the tenant's Business
 * Owner or the Deendoon Platform Administrator may delete an attachment,
 * but only the one who uploaded it, and only while the Ticket is not
 * closed — a closed ticket's evidence stays immutable until it is
 * reopened, the same terminal-state reasoning
 * `SupportTicketService::uploadAttachment` already applies to new
 * uploads. Tenant-vs-cross-tenant visibility is already enforced by
 * `SupportTicketController::resolve()` before this policy ever runs.
 */
class SupportTicketAttachmentPolicy
{
    public function delete(User $user, SupportTicketAttachment $attachment): bool
    {
        if (! $user->isPlatformAdmin() && ! $user->hasRole('admin')) {
            return false;
        }

        if (trim((string) $attachment->uploaded_by_user_id) !== trim((string) $user->id)) {
            return false;
        }

        return $attachment->ticket->status !== 'closed';
    }
}
