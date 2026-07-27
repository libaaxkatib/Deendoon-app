<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\DemandLetterFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use LogicException;

/**
 * Immutable after generation (BRL-057) — see Receipt's docblock.
 */
#[Fillable(['debt_id', 'template_type', 'reference_number', 'generated_at', 'file_path', 'file_size'])]
class DemandLetter extends Model
{
    /** @use HasFactory<DemandLetterFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'generated_at' => 'datetime',
            'file_size' => 'integer',
        ];
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        throw new LogicException('Demand Letters are immutable and cannot be updated.');
    }

    public function delete(): ?bool
    {
        throw new LogicException('Demand Letters are immutable and cannot be deleted.');
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function debt(): BelongsTo
    {
        return $this->belongsTo(Debt::class);
    }
}
