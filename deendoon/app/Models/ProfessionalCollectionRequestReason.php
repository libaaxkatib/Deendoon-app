<?php

namespace App\Models;

use Database\Factories\ProfessionalCollectionRequestReasonFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): one row per Reason for Transfer selected on a Professional
 * Collection Request (multi-select). No tenant_id of its own — same
 * pattern as RequestMessage — visibility is derived entirely through the
 * parent ProfessionalCollectionRequest.
 */
#[Fillable(['professional_collection_request_id', 'reason_label'])]
class ProfessionalCollectionRequestReason extends Model
{
    /** @use HasFactory<ProfessionalCollectionRequestReasonFactory> */
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
        return $this->belongsTo(ProfessionalCollectionRequest::class, 'professional_collection_request_id');
    }
}
