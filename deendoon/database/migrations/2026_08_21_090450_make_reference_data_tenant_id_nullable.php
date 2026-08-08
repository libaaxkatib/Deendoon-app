<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record, Decision 4): predefined Rejection Reasons are hosted as
 * platform-owned (tenant_id NULL) `reference_data` rows — {@see
 * \App\Models\Concerns\BelongsToTenant}'s existing fail-closed scope
 * already makes a NULL-tenant row visible only to the Deendoon Platform
 * Administrator (whose own tenant_id is NULL: `WHERE tenant_id IS NULL`)
 * and invisible to every ordinary tenant user, with zero modification to
 * that trait or the ReferenceData model.
 *
 * Discovered during implementation: `reference_data.tenant_id` was created
 * NOT NULL (2026_08_03_090300), which blocks that design at the database
 * level regardless of application logic — a necessary prerequisite
 * correction, not a new business rule. The foreign key to `tenants` is
 * left in place; NULL values are not checked against a foreign key
 * constraint (Postgres MATCH SIMPLE, the default), so this remains purely
 * additive — every existing NOT NULL row stays valid.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reference_data', function (Blueprint $table) {
            $table->char('tenant_id', 26)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('reference_data', function (Blueprint $table) {
            $table->char('tenant_id', 26)->nullable(false)->change();
        });
    }
};
