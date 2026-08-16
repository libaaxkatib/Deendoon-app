<?php

namespace App\Policies;

use App\Models\CollectionCaseAttachment;
use App\Models\User;

/**
 * Mobile Fix #4A (Attachment Delete): a Business Owner may delete only an
 * attachment they uploaded themselves, only while the Case's Customer is
 * not read-only (same gate `CollectionCasePolicy::manage` already applies),
 * and never once the Case itself is closed — a closed Case is a terminal
 * workflow whose evidence must stay immutable. Uploading remains allowed
 * on a closed Case (`CollectionCaseController::attachmentsStore`'s own
 * docblock), but deleting is not — evidence may still be added to the
 * historical record, never removed from it.
 */
class CollectionCaseAttachmentPolicy
{
    public function delete(User $user, CollectionCaseAttachment $attachment): bool
    {
        if (! $user->hasRole('admin')) {
            return false;
        }

        if (trim((string) $attachment->uploaded_by_user_id) !== trim((string) $user->id)) {
            return false;
        }

        $case = $attachment->collectionCase;

        if ($case->debt->customer->is_read_only) {
            return false;
        }

        return $case->case_status !== 'closed';
    }
}
