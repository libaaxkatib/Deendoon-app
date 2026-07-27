<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §2.9, §5.6, §6.2) resolves the
 * previously-undefined risk_level value set (DD-010) to a fixed three-value
 * classification. Matches the same PostgreSQL-only, defense-in-depth
 * pattern as the other CHECK constraints already on this table
 * (2026_07_26_090100_create_customers_table.php) — SQLite (the test suite)
 * doesn't support ALTER TABLE ADD CONSTRAINT, so enforcement there remains
 * the Form Request validation alone (UpdateRiskLevelRequest).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE customers ADD CONSTRAINT customers_risk_level_check CHECK (risk_level IS NULL OR risk_level IN (
                'high','medium','low'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_risk_level_check');
        }
    }
};
