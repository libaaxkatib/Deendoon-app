<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('collection_cases', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('debt_id', 26);
            $table->string('reference_number', 20);
            // CHAR(26) matches 06 exactly. No FK — same users.id bigint gap
            // already flagged for actor_user_id/recorded_by_user_id elsewhere.
            $table->char('assigned_officer_user_id', 26)->nullable();
            $table->string('case_status', 20)->default('open');
            $table->string('closure_outcome', 50)->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->timestampTz('closed_at')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index('debt_id');
            $table->index(['tenant_id', 'case_status']);
            $table->index(['tenant_id', 'assigned_officer_user_id']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE collection_cases ADD CONSTRAINT collection_cases_status_check CHECK (case_status IN (
                'open','closed'
            ))");

            // BRL-048: at most one open Collection Case per Debt, enforced
            // at the database level via a partial unique index.
            DB::statement('CREATE UNIQUE INDEX collection_cases_one_open_per_debt ON collection_cases (debt_id) WHERE case_status = \'open\'');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('collection_cases');
    }
};
