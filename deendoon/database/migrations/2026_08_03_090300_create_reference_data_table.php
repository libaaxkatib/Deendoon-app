<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * 06_Database_Design.md §6.8 — the single mechanism holding every value
 * set still pending a Deferred Decision (FR-070): Risk Level, Payment
 * Method, Collection Case closure outcome. Enforcement is
 * application-level, not database-level (no FK from the consuming
 * columns) — deliberate, per 06 §6.8's own note.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reference_data', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->string('category', 30);
            $table->string('value_label', 100);
            $table->smallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->index(['tenant_id', 'category', 'is_active']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE reference_data ADD CONSTRAINT reference_data_category_check CHECK (category IN (
                'risk_level','payment_method','collection_outcome'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('reference_data');
    }
};
