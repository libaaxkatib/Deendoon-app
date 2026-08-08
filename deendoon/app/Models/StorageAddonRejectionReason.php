<?php

namespace App\Models;

use Database\Factories\StorageAddonRejectionReasonFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): one row per predefined Rejection Reason selected by
 * the Deendoon Platform Administrator on a Storage Add-on request
 * (multi-select). No tenant_id of its own — same pattern as
 * SubscriptionChangeRequestRejectionReason — visibility is derived
 * entirely through the parent StorageAddon.
 */
#[Fillable(['storage_addon_id', 'reason_label'])]
class StorageAddonRejectionReason extends Model
{
    /** @use HasFactory<StorageAddonRejectionReasonFactory> */
    use HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function addon(): BelongsTo
    {
        return $this->belongsTo(StorageAddon::class, 'storage_addon_id');
    }
}
