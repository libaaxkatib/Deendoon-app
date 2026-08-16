<?php

namespace App\Models;

use Database\Factories\SecurityEventFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use LogicException;

/**
 * Insert-only, matching AuditLog's exact precedent — a security event is a
 * historical fact and must never be altered/removed after the fact.
 */
#[Fillable(['event_type', 'email', 'user_id', 'tenant_id', 'ip_address', 'method', 'path', 'token_id', 'account_exists', 'occurred_at'])]
class SecurityEvent extends Model
{
    /** @use HasFactory<SecurityEventFactory> */
    use HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'account_exists' => 'boolean',
            'occurred_at' => 'datetime',
        ];
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        throw new LogicException('SecurityEvent records are immutable and cannot be updated.');
    }

    public function delete(): ?bool
    {
        throw new LogicException('SecurityEvent records are immutable and cannot be deleted.');
    }
}
