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
        Schema::create('receipts', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('payment_id', 26);
            $table->string('reference_number', 20);
            $table->timestampTz('generated_at')->useCurrent();
            $table->string('file_path', 500);

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('payment_id')->references('id')->on('payments');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index('payment_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('receipts');
    }
};
