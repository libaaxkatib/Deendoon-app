<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\DocumentEventFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use LogicException;

/**
 * Document History (FR-052) — one shared, append-only log across all
 * three document types, mirroring AuditLog's immutability pattern.
 */
#[Fillable(['document_type', 'document_id', 'event_type', 'user_id', 'occurred_at'])]
class DocumentEvent extends Model
{
    /** @use HasFactory<DocumentEventFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
        ];
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        throw new LogicException('Document events are immutable and cannot be updated.');
    }

    public function delete(): ?bool
    {
        throw new LogicException('Document events are immutable and cannot be deleted.');
    }
}
