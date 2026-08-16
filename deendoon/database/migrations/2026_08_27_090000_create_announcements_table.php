<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Module 9 follow-up — Announcement History. One immutable row per
 * AnnouncementService::send() batch, written alongside (not instead of)
 * the existing per-recipient `notifications` rows and per-tenant
 * `audit_log` entries. Neither of those sources is durable enough to back
 * a permanent History page on its own: `notifications` rows are
 * recipient-owned and deletable (manual delete + 90-day read-notification
 * pruning), and `audit_log` — while immutable — never stores the message
 * body and has no concept of "scope" (all vs selected businesses).
 *
 * `id` reuses the exact same batch ULID already generated as
 * `notifications.related_entity_id` / `audit_log.entity_id` for that
 * send, so the three remain correlatable. No tenant scoping — a
 * platform-level record, visible only to the Platform Administrator, same
 * as `professional_collection_requests`. `sent_by_user_id` is CHAR(26)
 * with no FK, mirroring `audit_log.user_id`'s already-documented
 * bigint-vs-ULID `users.id` divergence — not a new inconsistency.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('announcements', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('title', 255);
            $table->text('message');
            $table->string('scope', 20);
            $table->unsignedInteger('recipient_count');
            $table->char('sent_by_user_id', 26)->nullable();
            $table->timestampTz('sent_at');

            $table->index('sent_at');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE announcements ADD CONSTRAINT announcements_scope_check CHECK (scope IN ('all', 'selected'))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('announcements');
    }
};
