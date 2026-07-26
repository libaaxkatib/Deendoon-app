<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\ReferenceDataFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * 06 §6.8 (FR-070): every value set still pending a Deferred Decision —
 * Risk Level, Payment Method, Collection Case closure outcome. Storage
 * only: business validation logic for how these values are applied
 * remains owned by the consuming module (FR-070 Main Flow step 4) — this
 * module does not wire consuming-module validation against it (see the
 * Final Report's Future Review Notes).
 */
#[Fillable(['category', 'value_label', 'sort_order', 'is_active'])]
class ReferenceData extends Model
{
    /** @use HasFactory<ReferenceDataFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'sort_order' => 'integer',
            'is_active' => 'boolean',
            'created_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
