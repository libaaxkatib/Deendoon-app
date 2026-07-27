<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Backend v2.1 (docs/Backend_v2.1_REST_API_Specification.md §7's
 * List Documents response; docs/Backend_v2.1_Database_Alignment.md §13,
 * already resolved: "Each document table requires a file_size value,
 * captured once at generation time and never recalculated — the only
 * capture point consistent with every document being immutable once
 * generated"). Nullable: existing rows generated before this migration
 * have no captured value and are not backfilled — no approved document
 * requires recomputing a value for an already-immutable record.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('receipts', function (Blueprint $table) {
            $table->unsignedBigInteger('file_size')->nullable()->after('file_path');
        });

        Schema::table('demand_letters', function (Blueprint $table) {
            $table->unsignedBigInteger('file_size')->nullable()->after('file_path');
        });

        Schema::table('statements', function (Blueprint $table) {
            $table->unsignedBigInteger('file_size')->nullable()->after('file_path');
        });
    }

    public function down(): void
    {
        Schema::table('receipts', function (Blueprint $table) {
            $table->dropColumn('file_size');
        });

        Schema::table('demand_letters', function (Blueprint $table) {
            $table->dropColumn('file_size');
        });

        Schema::table('statements', function (Blueprint $table) {
            $table->dropColumn('file_size');
        });
    }
};
