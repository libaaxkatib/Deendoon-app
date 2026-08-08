<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\DebtFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['customer_id', 'reference_number', 'amount', 'due_date', 'debt_status', 'remaining_balance', 'recovery_stage', 'notes'])]
class Debt extends Model
{
    /** @use HasFactory<DebtFactory> */
    use BelongsToTenant, HasFactory, HasUlids, SoftDeletes;

    const DELETED_AT = 'archived_at';

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'remaining_balance' => 'decimal:2',
            'due_date' => 'date',
            'recovery_stage' => 'integer',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function followUpHistory(): HasMany
    {
        return $this->hasMany(FollowUpHistory::class);
    }

    public function promisesToPay(): HasMany
    {
        return $this->hasMany(PromiseToPay::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function collectionCases(): HasMany
    {
        return $this->hasMany(CollectionCase::class);
    }

    public function demandLetters(): HasMany
    {
        return $this->hasMany(DemandLetter::class);
    }

    public function statements(): HasMany
    {
        return $this->hasMany(Statement::class);
    }

    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class);
    }

    /**
     * FR-021 (Business Owner Backend Completion): the query-level mirror of
     * DebtController::refreshOverdueStatus()'s exact condition
     * (debt_status IN [draft, pending] AND due_date has passed) — used by
     * Reporting/Dashboard so they reflect the true overdue state even for
     * a Debt that has never been individually viewed and therefore never
     * had its stored debt_status lazily flipped to 'overdue'. Read-only:
     * this never writes debt_status itself.
     */
    public function scopeEffectivelyOverdue(Builder $query): Builder
    {
        return $query->where(function (Builder $q) {
            $q->where('debt_status', 'overdue')
                ->orWhere(function (Builder $q2) {
                    $q2->whereIn('debt_status', ['draft', 'pending'])
                        ->whereDate('due_date', '<=', now());
                });
        });
    }
}
