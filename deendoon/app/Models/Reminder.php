<?php

namespace App\Models;

use App\Enums\ReminderType;
use App\Models\Concerns\BelongsToTenant;
use Database\Factories\ReminderFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §7). `related_entity_type`/
 * `related_entity_id` are plain string/ULID columns, not an Eloquent
 * `morphTo` — matching this project's existing polymorphic convention
 * (AuditLog.entity_type/entity_id, DocumentEvent.document_type/document_id),
 * not introducing a new one.
 *
 * Soft-deletes, per docs/Backend_v2.1_Database_Alignment.md §9: deleting a
 * reminder must exclude it from every view (§7.4) while preserving the
 * record for any Sent Messages it already produced.
 */
#[Fillable([
    'created_by_user_id', 'type', 'related_entity_type', 'related_entity_id',
    'related_case_id', 'due_date', 'amount_due', 'timing_rule', 'custom_fire_at',
    'delivery_methods', 'notes', 'completed_at',
])]
class Reminder extends Model
{
    /** @use HasFactory<ReminderFactory> */
    use BelongsToTenant, HasFactory, HasUlids, SoftDeletes;

    protected function casts(): array
    {
        return [
            'type' => ReminderType::class,
            'due_date' => 'datetime',
            'amount_due' => 'decimal:2',
            'custom_fire_at' => 'datetime',
            'delivery_methods' => 'array',
            'completed_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function relatedCase(): BelongsTo
    {
        return $this->belongsTo(CollectionCase::class, 'related_case_id');
    }

    public function sentMessages(): HasMany
    {
        return $this->hasMany(SentMessage::class);
    }
}
