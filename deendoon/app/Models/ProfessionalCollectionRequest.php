<?php

namespace App\Models;

use Database\Factories\ProfessionalCollectionRequestFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Deliberately does NOT use BelongsToTenant. This table is bimodal by
 * design (06 §2, BR-042): visible to its submitting tenant AND, without
 * any tenant filter at all, to the Deendoon Platform Administrator
 * (tenant_id IS NULL). That can't be expressed by a single always-scope-
 * or-never-scope trait, so every query against this model is scoped
 * explicitly in ProfessionalCollectionRequestController/Policy instead.
 *
 * `closed_at` was previously missing here, so
 * ProfessionalCollectionRequestService::close()'s `$request->update([...,
 * 'closed_at' => now()])` silently dropped that key on every call —
 * `status` persisted correctly, the timestamp never did. Fixed by adding
 * it to this list; no schema, service, or workflow change.
 */
#[Fillable([
    'collection_case_id', 'reference_number', 'status', 'submitted_by_user_id', 'actioned_by_user_id',
    'transfer_notes', 'declaration_accepted_at', 'declaration_accepted_by_user_id', 'closed_at',
])]
class ProfessionalCollectionRequest extends Model
{
    /** @use HasFactory<ProfessionalCollectionRequestFactory> */
    use HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'closed_at' => 'datetime',
            'declaration_accepted_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function collectionCase(): BelongsTo
    {
        return $this->belongsTo(CollectionCase::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(RequestMessage::class);
    }

    public function reasons(): HasMany
    {
        return $this->hasMany(ProfessionalCollectionRequestReason::class);
    }

    public function requestedServices(): HasMany
    {
        return $this->hasMany(RequestedServiceItem::class);
    }

    public function linkedDocuments(): HasMany
    {
        return $this->hasMany(ProfessionalCollectionRequestDocument::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(ProfessionalCollectionRequestAttachment::class);
    }

    public function timelineEvents(): HasMany
    {
        return $this->hasMany(ProfessionalCollectionTimelineEvent::class);
    }
}
