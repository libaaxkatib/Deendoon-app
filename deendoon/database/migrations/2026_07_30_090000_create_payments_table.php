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
        Schema::create('payments', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('debt_id', 26);
            $table->decimal('amount', 12, 2);
            $table->date('payment_date');
            $table->string('payment_method', 50)->nullable();
            $table->string('reference_notes', 500)->nullable();
            // CHAR(26) matches 06 exactly. No FK — same users.id bigint gap
            // already flagged for actor_user_id/created_by_user_id elsewhere.
            $table->char('recorded_by_user_id', 26);
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->index(['tenant_id', 'debt_id', 'payment_date']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            // Overpayment handling (cap/reject/credit) is DD-016 — this CHECK
            // enforces only "positive," not a ceiling, so it doesn't
            // pre-decide DD-016 (06_Database_Design.md §6.4).
            DB::statement('ALTER TABLE payments ADD CONSTRAINT payments_amount_check CHECK (amount > 0)');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
