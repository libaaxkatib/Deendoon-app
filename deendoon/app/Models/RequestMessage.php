<?php

namespace App\Models;

use Database\Factories\RequestMessageFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * No tenant_id column at all (06 §6.5) — visibility is entirely derived
 * through the parent ProfessionalCollectionRequest, never scoped
 * independently.
 */
#[Fillable(['professional_collection_request_id', 'sender_user_id', 'content'])]
class RequestMessage extends Model
{
    /** @use HasFactory<RequestMessageFactory> */
    use HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function request(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCollectionRequest::class, 'professional_collection_request_id');
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_user_id');
    }
}
