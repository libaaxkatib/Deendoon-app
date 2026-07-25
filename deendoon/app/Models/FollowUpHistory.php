<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['debt_id', 'collection_case_id', 'action_type', 'actor_user_id', 'details', 'occurred_at'])]
class FollowUpHistory extends Model
{
    use BelongsToTenant, HasUlids;

    protected $table = 'follow_up_history';

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
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
