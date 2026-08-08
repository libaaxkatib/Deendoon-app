<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): Reason for Transfer and Requested Services must both come
 * from the existing Reference Data architecture (FR-070), not a
 * hardcoded list — same additive DROP/ADD CONSTRAINT pattern as every
 * prior expansion of this list.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE reference_data DROP CONSTRAINT IF EXISTS reference_data_category_check');
            DB::statement("ALTER TABLE reference_data ADD CONSTRAINT reference_data_category_check CHECK (category IN (
                'risk_level','payment_method','collection_outcome','transfer_reason','requested_service'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE reference_data DROP CONSTRAINT IF EXISTS reference_data_category_check');
            DB::statement("ALTER TABLE reference_data ADD CONSTRAINT reference_data_category_check CHECK (category IN (
                'risk_level','payment_method','collection_outcome'
            ))");
        }
    }
};
