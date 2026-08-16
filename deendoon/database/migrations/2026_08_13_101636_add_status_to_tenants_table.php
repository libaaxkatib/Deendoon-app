<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Admin Panel — Business Management (Product Owner decision): the Deendoon
 * Platform Administrator can suspend/reactivate a tenant. No such concept
 * existed on `tenants` before this — mirrors the `status` +
 * `{verb}_at`/`{verb}_reason` shape already used for `users.status`
 * (`2026_08_03_090000_add_archived_at_to_users_table.php`), not a new
 * pattern. Suspending a tenant does not delete or archive anything —
 * enforcement of what a suspended tenant's Business Owner can/cannot do
 * belongs to a separate, explicitly-approved authorization change, not
 * this schema addition.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->string('status', 20)->default('active')->after('contact_phone');
            $table->timestampTz('suspended_at')->nullable()->after('status');
            $table->string('suspended_reason', 500)->nullable()->after('suspended_at');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE tenants ADD CONSTRAINT tenants_status_check CHECK (status IN ('active', 'suspended'))");
        }
    }

    public function down(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn(['status', 'suspended_at', 'suspended_reason']);
        });
    }
};
