<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('statements', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('customer_id', 26);
            // NULLABLE — set only when triggered from Debt Details (FR-049 A1).
            // The Statement itself always covers the full Customer account
            // (FR-049's Main Flow never describes a single-debt variant); this
            // column is traceability metadata for the triggering context only.
            $table->char('debt_id', 26)->nullable();
            $table->string('reference_number', 20);
            $table->timestampTz('generated_at')->useCurrent();
            $table->string('file_path', 500);

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('customer_id')->references('id')->on('customers');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index('customer_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('statements');
    }
};
