<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['debt_id', 'promised_date', 'status', 'created_by_user_id', 'resolved_at'])]
class PromiseToPay extends Model
{
    use BelongsToTenant, HasFactory, HasUlids;

    protected $table = 'promises_to_pay';

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'promised_date' => 'date',
            'created_at' => 'datetime',
            'resolved_at' => 'datetime',
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
}
