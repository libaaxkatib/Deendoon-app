<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Backend Completion Roadmap, Phase 3.5 (Product Owner mandatory fix):
 * service-level validation alone cannot prevent two concurrent requests
 * from both passing the "no pending request exists" check before either
 * commits (Postgres READ COMMITTED does not serialize this). Backs the
 * business rule ("a tenant may have only ONE pending Subscription/Storage
 * request at a time") with a database-level partial unique index —
 * the exact same pattern already established for the identical problem
 * class in `2026_07_31_090100_create_professional_collection_requests_table.php`
 * (`pcr_one_active_per_case`, "at most one active Request per Collection
 * Case").
 *
 * Postgres-only, matching every other business-rule CHECK/index in this
 * schema — SQLite (the test suite) has no equivalent constraint; the
 * application-level check remains the primary, tested defense there,
 * with this as the production safety net for the race it can't close.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("CREATE UNIQUE INDEX subscription_change_requests_one_pending_per_tenant ON subscription_change_requests (tenant_id) WHERE status = 'pending'");
            DB::statement("CREATE UNIQUE INDEX storage_addons_one_pending_per_tenant ON storage_addons (tenant_id) WHERE status = 'pending'");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('DROP INDEX IF EXISTS subscription_change_requests_one_pending_per_tenant');
            DB::statement('DROP INDEX IF EXISTS storage_addons_one_pending_per_tenant');
        }
    }
};
