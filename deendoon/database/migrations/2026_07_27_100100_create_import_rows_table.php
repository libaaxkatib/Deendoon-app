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
        Schema::create('import_rows', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('batch_id', 26);
            $table->smallInteger('row_number');
            $table->jsonb('row_data');
            $table->string('validation_status', 20);
            $table->jsonb('validation_errors')->nullable();
            $table->char('duplicate_match_customer_id', 26)->nullable();
            $table->string('resolution', 20)->nullable();
            $table->char('resulting_customer_id', 26)->nullable();

            $table->foreign('batch_id')->references('id')->on('import_batches');
            $table->foreign('duplicate_match_customer_id')->references('id')->on('customers');
            $table->foreign('resulting_customer_id')->references('id')->on('customers');

            $table->index('batch_id');
            $table->index('duplicate_match_customer_id');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE import_rows ADD CONSTRAINT import_rows_validation_status_check CHECK (validation_status IN (
                'valid','invalid'
            ))");

            DB::statement("ALTER TABLE import_rows ADD CONSTRAINT import_rows_resolution_check CHECK (resolution IS NULL OR resolution IN (
                'skip','update','new'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('import_rows');
    }
};
