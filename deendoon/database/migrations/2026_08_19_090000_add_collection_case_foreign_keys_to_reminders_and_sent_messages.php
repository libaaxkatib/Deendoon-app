<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Known_Backend_Issues.md §2.1: `reminders.related_case_id` and
 * `sent_messages.case_id` both originally declared their foreign key to
 * `collection_cases` inline in their own CREATE TABLE migrations
 * (2026-07-27), but `collection_cases` itself isn't created until
 * 2026-07-31 — a fresh `migrate:fresh` against a real database that
 * enforces FK target existence at migration time (PostgreSQL; SQLite
 * doesn't, which is why the test suite never caught this) fails outright.
 * Both original migrations now create their columns without the FK
 * (see their own updated docblocks); this migration adds both
 * constraints here instead, once collection_cases genuinely exists.
 *
 * The existence check below is defense-in-depth, not a correctness
 * requirement of the ordering fix itself: it guards against this
 * migration ever being re-applied to a database that somehow already has
 * one of these constraints (for example a manual/out-of-band schema
 * change), so `up()` doesn't fail with "constraint already exists" in
 * that scenario. Same driver-guarded style as the CHECK constraints in
 * create_reminders_table.php.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! $this->constraintExists('reminders', 'reminders_related_case_id_foreign')) {
            Schema::table('reminders', function (Blueprint $table) {
                $table->foreign('related_case_id')->references('id')->on('collection_cases');
            });
        }

        if (! $this->constraintExists('sent_messages', 'sent_messages_case_id_foreign')) {
            Schema::table('sent_messages', function (Blueprint $table) {
                $table->foreign('case_id')->references('id')->on('collection_cases');
            });
        }
    }

    public function down(): void
    {
        Schema::table('sent_messages', function (Blueprint $table) {
            $table->dropForeign(['case_id']);
        });

        Schema::table('reminders', function (Blueprint $table) {
            $table->dropForeign(['related_case_id']);
        });
    }

    private function constraintExists(string $table, string $constraint): bool
    {
        if (DB::connection()->getDriverName() !== 'pgsql') {
            return false;
        }

        return DB::table('information_schema.table_constraints')
            ->where('table_name', $table)
            ->where('constraint_name', $constraint)
            ->exists();
    }
};
