<?php

namespace App\Policies;

use App\Models\Invoice;
use App\Models\User;

/**
 * Same judgment call as ReceiptPolicy/DemandLetterPolicy/StatementPolicy
 * under the current interim 3-role RBAC: admin and sales_finance are
 * authorized to view/download/share/generate Documents.
 */
class InvoicePolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, Invoice $invoice): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'sales_finance']);
    }
}
