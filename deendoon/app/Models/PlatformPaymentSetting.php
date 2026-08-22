<?php

namespace App\Models;

use App\Services\PlatformPaymentSettingsService;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

/**
 * Manual Mobile-Money Subscription Payment Flow (Product Owner decision):
 * the single platform-level row holding the destination mobile-money
 * number a Business Owner is shown on the "Send Money" step. Deliberately
 * not tenant-scoped (see the migration's docblock) — there is exactly one
 * row, upserted by {@see PlatformPaymentSettingsService}.
 * `updated_by` is excluded from Fillable and set via direct property
 * assignment, matching the established `approved_by`/`reviewed_by`
 * convention elsewhere in this domain.
 */
#[Fillable(['destination_mobile_money_number'])]
class PlatformPaymentSetting extends Model
{
    use HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'updated_at' => 'datetime',
        ];
    }
}
