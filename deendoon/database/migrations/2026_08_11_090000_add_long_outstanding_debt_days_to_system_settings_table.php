<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Sprint 2A/2B (Risk_Level_Formula_Specification_v1.0.md §8, Change 2):
 * Long Outstanding Debt's day-count threshold is a per-tenant configurable
 * value, not a hardcoded constant. Modeled directly on the existing sibling
 * column `professional_collection_threshold_days` on this same table
 * (FR-069). Unlike that column, this one carries a DEFAULT so every
 * existing and new tenant row already has a working value (90) with no
 * configuration step required.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('system_settings', function (Blueprint $table) {
            $table->smallInteger('long_outstanding_debt_days')->default(90)->after('professional_collection_threshold_days');
        });
    }

    public function down(): void
    {
        Schema::table('system_settings', function (Blueprint $table) {
            $table->dropColumn('long_outstanding_debt_days');
        });
    }
};
