<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\CollectionCaseFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['debt_id', 'reference_number', 'assigned_officer_user_id', 'case_status', 'closure_outcome'])]
class CollectionCase extends Model
{
    /** @use HasFactory<CollectionCaseFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'closed_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function debt(): BelongsTo
    {
        return $this->belongsTo(Debt::class);
    }

    public function professionalCollectionRequests(): HasMany
    {
        return $this->hasMany(ProfessionalCollectionRequest::class);
    }
}
