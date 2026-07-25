<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\CustomerFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['name', 'phone', 'credit_limit', 'customer_status', 'risk_level'])]
class Customer extends Model
{
    /** @use HasFactory<CustomerFactory> */
    use BelongsToTenant, HasFactory, HasUlids, SoftDeletes;

    const DELETED_AT = 'archived_at';

    protected function casts(): array
    {
        return [
            'credit_limit' => 'decimal:2',
            'outstanding_balance' => 'decimal:2',
            'credit_score' => 'integer',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function debts(): HasMany
    {
        return $this->hasMany(Debt::class);
    }

    /**
     * BRL-017: Credit Limit minus Outstanding Balance. May be negative;
     * never clamped to zero. bcmath is used to keep this exact, matching
     * 06_Database_Design.md Principle 7 (money is never floating-point).
     */
    protected function remainingCredit(): Attribute
    {
        return Attribute::make(
            get: fn (): string => bcsub((string) $this->credit_limit, (string) $this->outstanding_balance, 2),
        );
    }
}
