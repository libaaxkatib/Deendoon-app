<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use LogicException;

/**
 * Insert-only, per 06_Database_Design.md §6.9 Principle 4: "no application
 * code path... permits UPDATE or DELETE against it." update()/delete() are
 * blocked here to make that structural, not just a convention nobody
 * happens to violate yet.
 */
#[Fillable(['tenant_id', 'user_id', 'action', 'entity_type', 'entity_id', 'reason', 'occurred_at'])]
class AuditLog extends Model
{
    use HasUlids;

    protected $table = 'audit_log';

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
        ];
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        throw new LogicException('AuditLog records are immutable and cannot be updated.');
    }

    public function delete(): ?bool
    {
        throw new LogicException('AuditLog records are immutable and cannot be deleted.');
    }
}
