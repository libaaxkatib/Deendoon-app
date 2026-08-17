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
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * `risk_level` is deliberately NOT fillable (Sprint 2B): it is exclusively
 * system-calculated by RiskLevelService, which sets it via direct property
 * assignment + save() — the same pattern already used for
 * `outstanding_balance` (CustomerBalanceService) — never via mass
 * assignment, so no manual-override path can ever reappear accidentally.
 *
 * `is_read_only` (Backend Completion Roadmap, Phase 4.1) follows the
 * identical pattern: exclusively system-calculated by
 * CustomerReadOnlyService via bulk query-builder UPDATE statements (which
 * bypass mass-assignment guarding entirely, unlike `Model::update()`) —
 * also deliberately excluded from Fillable so no other write path can
 * ever set it directly.
 */
#[Fillable(['name', 'phone', 'address', 'credit_limit', 'customer_status'])]
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
            'is_read_only' => 'boolean',
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
     * FR-035 A1: Customer-level Payment History aggregates payments across
     * all of the Customer's Debts.
     */
    public function payments(): HasManyThrough
    {
        return $this->hasManyThrough(Payment::class, Debt::class);
    }

    public function statements(): HasMany
    {
        return $this->hasMany(Statement::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(CustomerAttachment::class);
    }

    /**
     * Fix #23 — Multiple Customer Phone Numbers. `customers.phone` remains
     * a maintained mirror of whichever row here has `is_primary = true`
     * (see {@see App\Services\CustomerPhoneNumberService}) — every
     * existing single-phone read path keeps reading `phone` directly and
     * needs no changes.
     */
    public function phoneNumbers(): HasMany
    {
        return $this->hasMany(CustomerPhoneNumber::class)
            ->orderByDesc('is_primary')
            ->orderBy('created_at');
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
