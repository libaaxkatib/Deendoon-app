<?php

namespace App\Models;

use Database\Factories\AnnouncementFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Module 9 follow-up — Announcement History. See the
 * create_announcements_table migration for why this table exists
 * alongside Notification/AuditLog rather than deriving History from them.
 * `id` is set explicitly by AnnouncementService to the same batch ULID
 * used for that send's Notification/AuditLog rows, not auto-generated —
 * kept out of Fillable like every other model's own PK/system field.
 */
#[Fillable(['title', 'message', 'scope', 'recipient_count', 'sent_by_user_id', 'sent_at'])]
class Announcement extends Model
{
    /** @use HasFactory<AnnouncementFactory> */
    use HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'recipient_count' => 'integer',
            'sent_at' => 'datetime',
        ];
    }

    /**
     * `sent_by_user_id` is CHAR(26) — chosen to mirror `audit_log.user_id`'s
     * existing, already-documented pattern — but unlike a ULID (which
     * exactly fills 26 characters), it holds a short `users.id` bigint
     * string (e.g. "4"). PostgreSQL's fixed-length `char(n)` type
     * right-pads stored values with spaces up to the declared length and
     * returns that padding on SELECT (confirmed: a stored "4" round-trips
     * as "4" followed by 25 trailing spaces). Untrimmed, that broke every
     * lookup keyed on this value (History's "Sent By" always showed
     * "Unknown"). Trimming here, not at each call site, fixes every
     * current and future reader in one place.
     */
    protected function sentByUserId(): Attribute
    {
        return Attribute::make(
            get: fn (?string $value) => $value === null ? null : trim($value),
        );
    }
}
