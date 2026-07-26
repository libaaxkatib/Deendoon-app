<?php

namespace App\Policies;

use App\Models\DemandLetter;
use App\Models\User;

class DemandLetterPolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, DemandLetter $demandLetter): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'sales_finance']);
    }
}
