<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

/**
 * FR-004 — Forgot Password / Password Reset. Wraps the stock Laravel
 * `password_reset_tokens` table (migrated since Foundation, unused until
 * this feature). `email` is the table's own primary key, so issuing a new
 * token for an email structurally replaces any prior one — "old tokens
 * invalidated once a new one is issued" is a property of the schema, not
 * something PasswordResetService has to separately enforce. `token` is
 * always a hash (08_Security_and_RBAC.md §10: "hashed at rest, same
 * standard as a credential, never stored or logged in plaintext") —
 * never the plaintext value emailed to the user.
 */
#[Fillable(['email', 'token', 'created_at'])]
class PasswordResetToken extends Model
{
    protected $table = 'password_reset_tokens';

    protected $primaryKey = 'email';

    public $incrementing = false;

    protected $keyType = 'string';

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }
}
