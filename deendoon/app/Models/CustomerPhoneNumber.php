<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Fix #23 — Multiple Customer Phone Numbers. One row per phone number,
 * up to 3 per customer, exactly one `is_primary` — both invariants
 * enforced by {@see App\Services\CustomerPhoneNumberService}, never by
 * mass assignment here. `tenant_id` is never fillable — set exclusively
 * by {@see BelongsToTenant}.
 */
#[Fillable(['customer_id', 'phone', 'is_primary'])]
class CustomerPhoneNumber extends Model
{
    use BelongsToTenant, HasUlids;

    protected function casts(): array
    {
        return [
            'is_primary' => 'boolean',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
