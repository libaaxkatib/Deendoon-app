<?php

namespace App\Policies;

use App\Models\CollectionCase;
use App\Models\User;

/**
 * Same judgment call as DebtPolicy/CustomerPolicy under the current
 * interim 3-role RBAC (Product Owner Decision 4): admin and sales_finance
 * manage Collection Cases. Unlike FR-041's assignee check (which names
 * "Collection Officer" specifically and is validated separately in
 * CollectionCaseService::assign(), against the real collection_officer
 * role), nothing in FR-042/043/044/045/046 names a specific role for who
 * may *perform* these actions — so, consistent with every other generic
 * "authorized user" requirement handled this way throughout the project,
 * they fall to the same admin/sales_finance interim mapping.
 */
class CollectionCasePolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, CollectionCase $case): bool
    {
        return $this->isAuthorized($user);
    }

    public function manage(User $user, CollectionCase $case): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'sales_finance']);
    }
}
