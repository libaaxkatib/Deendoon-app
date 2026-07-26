<?php

namespace App\Policies;

use App\Models\Receipt;
use App\Models\User;

/**
 * Same judgment call as every other tenant-scoped Policy under the
 * interim 3-role RBAC (Product Owner Decision 4): admin and sales_finance
 * are authorized to view/download Documents.
 */
class ReceiptPolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, Receipt $receipt): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'sales_finance']);
    }
}
