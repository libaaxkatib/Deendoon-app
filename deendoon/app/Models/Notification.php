<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\NotificationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * BRL-064: created only as a passive consequence of a qualifying event
 * from an owning module — never directly by a client request (07 §11:
 * "No POST /notifications endpoint exists... deliberate, not an
 * omission"). The only mutation ever made after creation is read_at
 * (FR-059/BRL-066); every other field is fixed at creation.
 */
#[Fillable(['recipient_user_id', 'type', 'related_entity_type', 'related_entity_id', 'read_at'])]
class Notification extends Model
{
    /** @use HasFactory<NotificationFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'read_at' => 'datetime',
            'created_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
