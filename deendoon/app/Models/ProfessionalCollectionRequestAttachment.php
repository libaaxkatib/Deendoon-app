<?php

namespace App\Models;

use Database\Factories\ProfessionalCollectionRequestAttachmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): a newly uploaded file specific to a Professional Collection
 * Request — never a duplicate of an existing Receipt/DemandLetter/
 * Statement/Invoice (those are linked by reference via
 * ProfessionalCollectionRequestDocument instead). `timeline_event_id` is
 * nullable: null when uploaded at submission time, set when attached to
 * a specific Professional Collection Timeline event. No tenant_id of its
 * own — same pattern as RequestMessage.
 */
#[Fillable(['professional_collection_request_id', 'timeline_event_id', 'uploaded_by_user_id', 'file_path', 'original_filename', 'mime_type', 'file_size'])]
class ProfessionalCollectionRequestAttachment extends Model
{
    /** @use HasFactory<ProfessionalCollectionRequestAttachmentFactory> */
    use HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'file_size' => 'integer',
            'created_at' => 'datetime',
        ];
    }

    public function request(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCollectionRequest::class, 'professional_collection_request_id');
    }

    public function timelineEvent(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCollectionTimelineEvent::class, 'timeline_event_id');
    }

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }
}
