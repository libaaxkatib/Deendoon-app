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
        Schema::create('debts', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('customer_id', 26);
            $table->string('reference_number', 20);
            $table->decimal('amount', 12, 2);
            $table->date('due_date');
            // DD-006 (04_Business_Rules.md) is unresolved on Draft vs Pending
            // as the creation default. 'pending' is used as the safest
            // interim value — see the Debt Module report's NON-BLOCKING
            // issues; this is not an invented resolution to DD-006.
            $table->string('debt_status', 20)->default('pending');
            $table->decimal('remaining_balance', 12, 2);
            $table->smallInteger('recovery_stage')->default(1);
            $table->text('notes')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->timestampTz('archived_at')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('customer_id')->references('id')->on('customers');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index(['tenant_id', 'customer_id']);
            $table->index(['tenant_id', 'debt_status']);
            $table->index(['tenant_id', 'due_date']);
            $table->index(['tenant_id', 'recovery_stage']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE debts ADD CONSTRAINT debts_amount_positive_check CHECK (amount > 0)');

            DB::statement("ALTER TABLE debts ADD CONSTRAINT debts_debt_status_check CHECK (debt_status IN (
                'draft','pending','overdue','partial_paid','paid','cancelled','written_off'
            ))");

            DB::statement('ALTER TABLE debts ADD CONSTRAINT debts_recovery_stage_check CHECK (recovery_stage BETWEEN 1 AND 6)');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('debts');
    }
};
