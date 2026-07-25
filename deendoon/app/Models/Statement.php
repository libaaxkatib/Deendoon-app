<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\StatementFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use LogicException;

/**
 * Immutable after generation (BRL-057) — see Receipt's docblock.
 */
#[Fillable(['customer_id', 'debt_id', 'reference_number', 'generated_at', 'file_path'])]
class Statement extends Model
{
    /** @use HasFactory<StatementFactory> */
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
        throw new LogicException('Statements are immutable and cannot be updated.');
    }

    public function delete(): ?bool
    {
        throw new LogicException('Statements are immutable and cannot be deleted.');
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function debt(): BelongsTo
    {
        return $this->belongsTo(Debt::class);
    }
}
