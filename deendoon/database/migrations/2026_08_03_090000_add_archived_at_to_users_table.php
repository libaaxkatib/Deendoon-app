<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * FR-066: deactivation follows the Archive/Restore pattern (BC-002) — a
 * user account is never permanently deleted. `06_Database_Design.md`
 * §6.1's approved `users` table pairs TWO columns for this, not one:
 * `status VARCHAR(20) CHECK (status IN ('active','archived')) DEFAULT
 * 'active'` (the archival flag itself) alongside `archived_at
 * TIMESTAMPTZ NULLABLE` (the naming convention, `06` §3, shared with
 * Customer/Debt). Customer/Debt use `archived_at` alone as their
 * complete archival signal (`06` §9) — Users is the one table where the
 * detailed §6.1 column definition adds a dedicated status column on top
 * of that general pattern, per Verification 2's direct re-read.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('status', 20)->default('active')->after('remember_token');
            $table->timestampTz('archived_at')->nullable()->after('status');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status IN ('active', 'archived'))");
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['status', 'archived_at']);
        });
    }
};
