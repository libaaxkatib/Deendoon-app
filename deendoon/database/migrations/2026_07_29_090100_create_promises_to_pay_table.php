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
        Schema::create('promises_to_pay', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('debt_id', 26);
            $table->date('promised_date');
            $table->string('status', 20)->default('open');
            // CHAR(26) matches 06 exactly. No FK — same users.id bigint gap.
            $table->char('created_by_user_id', 26);
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('resolved_at')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->index(['tenant_id', 'debt_id']);
            $table->index(['tenant_id', 'promised_date']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE promises_to_pay ADD CONSTRAINT promises_to_pay_status_check CHECK (status IN (
                'open','fulfilled','broken'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('promises_to_pay');
    }
};
