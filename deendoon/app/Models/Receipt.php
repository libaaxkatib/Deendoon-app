<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\ReceiptFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use LogicException;

/**
 * Immutable after generation (BRL-057) — no UPDATE path is approved
 * (DD-029 regeneration policy unresolved), so update()/delete() are
 * blocked structurally, same pattern as AuditLog.
 */
#[Fillable(['payment_id', 'reference_number', 'generated_at', 'file_path'])]
class Receipt extends Model
{
    /** @use HasFactory<ReceiptFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'generated_at' => 'datetime',
        ];
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        throw new LogicException('Receipts are immutable and cannot be updated.');
    }

    public function delete(): ?bool
    {
        throw new LogicException('Receipts are immutable and cannot be deleted.');
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }
}
