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
        Schema::create('demand_letters', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('debt_id', 26);
            $table->string('template_type', 20);
            $table->string('reference_number', 20);
            $table->timestampTz('generated_at')->useCurrent();
            $table->string('file_path', 500);

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index('debt_id');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE demand_letters ADD CONSTRAINT demand_letters_template_type_check CHECK (template_type IN (
                'first_reminder','second_reminder','final_demand','legal_notice'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('demand_letters');
    }
};
