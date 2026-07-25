<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\DebtFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
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
}
