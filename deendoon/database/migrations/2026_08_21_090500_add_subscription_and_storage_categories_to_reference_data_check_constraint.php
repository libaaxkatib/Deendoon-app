<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): predefined Rejection Reasons for both workflows come
 * from the existing Reference Data architecture, not a hardcoded list —
 * same additive DROP/ADD CONSTRAINT pattern as every prior expansion of
 * this list. These rows are platform-owned (created with tenant_id NULL)
 * rather than per-tenant — ReferenceData's existing BelongsToTenant trait
 * already makes a NULL-tenant row visible only to the Deendoon Platform
 * Administrator (whose own tenant_id is NULL) and invisible to every
 * ordinary tenant user, with zero modification to that trait or model.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE reference_data DROP CONSTRAINT IF EXISTS reference_data_category_check');
            DB::statement("ALTER TABLE reference_data ADD CONSTRAINT reference_data_category_check CHECK (category IN (
                'risk_level','payment_method','collection_outcome','transfer_reason','requested_service',
                'subscription_rejection_reason','storage_rejection_reason'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE reference_data DROP CONSTRAINT IF EXISTS reference_data_category_check');
            DB::statement("ALTER TABLE reference_data ADD CONSTRAINT reference_data_category_check CHECK (category IN (
                'risk_level','payment_method','collection_outcome','transfer_reason','requested_service'
            ))");
        }
    }
};
