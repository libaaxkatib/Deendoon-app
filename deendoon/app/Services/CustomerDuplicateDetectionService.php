<?php

namespace App\Services;

use App\Models\Customer;

/**
 * BRL-013: a phone match against an existing active Customer is treated as
 * a likely duplicate. The name-matching algorithm's exact/fuzzy behavior is
 * an unresolved Deferred Decision (DD-003) — only a case-insensitive exact
 * match is implemented here, deliberately not a similarity/fuzzy algorithm
 * this document was never given approval to invent.
 */
class CustomerDuplicateDetectionService
{
    public function findPotentialDuplicate(
        string $tenantId,
        string $name,
        string $phone,
        ?string $excludeCustomerId = null,
    ): ?Customer {
        return Customer::withoutGlobalScope('tenant')
            ->where('tenant_id', $tenantId)
            ->when($excludeCustomerId, fn ($query) => $query->where('id', '!=', $excludeCustomerId))
            ->where(function ($query) use ($name, $phone) {
                $query->whereRaw('LOWER(phone) = ?', [mb_strtolower($phone)])
                    ->orWhereRaw('LOWER(name) = ?', [mb_strtolower($name)]);
            })
            ->first();
    }
}
