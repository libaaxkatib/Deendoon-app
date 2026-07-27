<?php

namespace App\Models;

use App\Enums\MessageChannel;
use App\Models\Concerns\BelongsToTenant;
use Database\Factories\SentMessageFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use LogicException;

/**
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §7.7, §7.8, §8.8): "every send
 * is recorded... for audit purposes" — immutable once created, matching
 * this project's existing pattern for audit-trail records (AuditLog,
 * DocumentEvent).
 */
#[Fillable([
    'template_id', 'reminder_id', 'case_id', 'document_type', 'document_id',
    'channel', 'recipient_phone', 'rendered_text', 'status', 'sent_by_user_id',
])]
class SentMessage extends Model
{
    /** @use HasFactory<SentMessageFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'channel' => MessageChannel::class,
            'sent_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function template(): BelongsTo
    {
        return $this->belongsTo(MessageTemplate::class, 'template_id');
    }

    public function reminder(): BelongsTo
    {
        return $this->belongsTo(Reminder::class);
    }

    public function case(): BelongsTo
    {
        return $this->belongsTo(CollectionCase::class, 'case_id');
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        throw new LogicException('Sent messages are immutable and cannot be updated.');
    }

    public function delete(): ?bool
    {
        throw new LogicException('Sent messages are immutable and cannot be deleted.');
    }
}
