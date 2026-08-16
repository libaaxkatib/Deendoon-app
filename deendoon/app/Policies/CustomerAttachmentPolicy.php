<?php

namespace App\Policies;

use App\Models\CustomerAttachment;
use App\Models\User;

/**
 * Mobile Fix #4A (Attachment Delete): a Business Owner may delete only an
 * attachment they uploaded themselves, and only while its Customer is not
 * read-only (FR-083) — the same gate `CustomerPolicy::update`/`archive`
 * already apply to every other write on a read-only Customer. An archived
 * (soft-deleted) Customer is already unreachable here — `customers/
 * {customer}/attachments*` is not `->withTrashed()` — so no separate
 * archived check is needed.
 */
class CustomerAttachmentPolicy
{
    public function delete(User $user, CustomerAttachment $attachment): bool
    {
        if (! $user->hasRole('admin')) {
            return false;
        }

        if (trim((string) $attachment->uploaded_by_user_id) !== trim((string) $user->id)) {
            return false;
        }

        return ! $attachment->customer->is_read_only;
    }
}
