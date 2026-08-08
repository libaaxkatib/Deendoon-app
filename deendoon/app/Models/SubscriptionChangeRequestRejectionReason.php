<?php

namespace App\Models;

use Database\Factories\SubscriptionChangeRequestRejectionReasonFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): one row per predefined Rejection Reason selected by
 * the Deendoon Platform Administrator on a Subscription Change Request
 * (multi-select). No tenant_id of its own — same pattern as
 * ProfessionalCollectionRequestReason — visibility is derived entirely
 * through the parent SubscriptionChangeRequest.
 */
#[Fillable(['subscription_change_request_id', 'reason_label'])]
class SubscriptionChangeRequestRejectionReason extends Model
{
    /** @use HasFactory<SubscriptionChangeRequestRejectionReasonFactory> */
    use HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function request(): BelongsTo
    {
        return $this->belongsTo(SubscriptionChangeRequest::class, 'subscription_change_request_id');
    }
}
