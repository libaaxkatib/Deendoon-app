<?php

namespace App\Policies;

use App\Models\Statement;
use App\Models\User;

class StatementPolicy
{
    public function view(User $user, Statement $statement): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'sales_finance']);
    }
}
