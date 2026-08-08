<?php

namespace App\Models;

use App\Enums\ProfessionalCollectionTimelineEventType;
use Database\Factories\ProfessionalCollectionTimelineEventFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): the Deendoon Recovery Team's own operational recovery
 * activity log for a Professional Collection Request — independent of
 * the Audit Log (system/data changes) and the existing, unchanged
 * Customer Collection Timeline. No tenant_id of its own — same pattern
 * as RequestMessage; visibility is derived through the parent Request.
 */
#[Fillable(['professional_collection_request_id', 'event_type', 'officer_user_id', 'occurred_at', 'notes', 'outcome'])]
class ProfessionalCollectionTimelineEvent extends Model
{
    /** @use HasFactory<ProfessionalCollectionTimelineEventFactory> */
    use HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'event_type' => ProfessionalCollectionTimelineEventType::class,
            'occurred_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function request(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCollectionRequest::class, 'professional_collection_request_id');
    }

    public function officer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'officer_user_id');
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(ProfessionalCollectionRequestAttachment::class, 'timeline_event_id');
    }
}
