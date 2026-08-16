<?php

namespace App\Policies;

use App\Models\DebtAttachment;
use App\Models\User;

/**
 * Mobile Fix #4A (Attachment Delete): a Business Owner may delete only an
 * attachment they uploaded themselves, only while its Debt's Customer is
 * not read-only (same gate `DebtPolicy::update`/`archive` already apply),
 * and never once the Debt itself is in a terminal status (paid/cancelled/
 * written_off) — those Debts are immutable financial records, matching
 * `DebtController::updateStatus`'s own terminal-status guard. An archived
 * (soft-deleted) Debt is already unreachable here — `debts/{debt}/
 * attachments*` is not `->withTrashed()` — so no separate archived check
 * is needed.
 */
class DebtAttachmentPolicy
{
    private const TERMINAL_STATUSES = ['paid', 'cancelled', 'written_off'];

    public function delete(User $user, DebtAttachment $attachment): bool
    {
        if (! $user->hasRole('admin')) {
            return false;
        }

        if (trim((string) $attachment->uploaded_by_user_id) !== trim((string) $user->id)) {
            return false;
        }

        $debt = $attachment->debt;

        if ($debt->customer->is_read_only) {
            return false;
        }

        return ! in_array($debt->debt_status, self::TERMINAL_STATUSES, true);
    }
}
