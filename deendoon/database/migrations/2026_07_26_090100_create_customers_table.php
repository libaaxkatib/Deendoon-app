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
        Schema::create('customers', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->string('name');
            $table->string('phone', 30);
            $table->string('customer_status', 20)->default('active');
            $table->decimal('credit_limit', 12, 2);
            $table->decimal('outstanding_balance', 12, 2)->default(0);
            $table->string('risk_level', 50)->nullable();
            $table->smallInteger('credit_score')->nullable();
            $table->string('credit_score_band', 20)->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->timestampTz('archived_at')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');

            $table->index(['tenant_id', 'phone']);
            $table->index(['tenant_id', 'name']);
            $table->index(['tenant_id', 'customer_status']);
            $table->index(['tenant_id', 'archived_at']);
        });

        // CHECK constraints are a PostgreSQL-only defense-in-depth layer on top
        // of Form Request validation (the primary, tested enforcement). SQLite
        // (used for the test suite) doesn't support ALTER TABLE ADD CONSTRAINT.
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE customers ADD CONSTRAINT customers_customer_status_check CHECK (customer_status IN (
                'active','good_standing','late_payer','high_risk','in_collection','recovered','blocked'
            ))");

            DB::statement('ALTER TABLE customers ADD CONSTRAINT customers_credit_score_check CHECK (credit_score IS NULL OR (credit_score BETWEEN 0 AND 100))');

            DB::statement("ALTER TABLE customers ADD CONSTRAINT customers_credit_score_band_check CHECK (credit_score_band IS NULL OR credit_score_band IN (
                'excellent','good','fair','poor'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('customers');
    }
};
