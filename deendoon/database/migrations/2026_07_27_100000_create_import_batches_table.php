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
        Schema::create('import_batches', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            // CHAR(26) matches 06_Database_Design.md exactly. No FK constraint
            // is possible today: users.id is still Laravel's default bigint —
            // the same pre-existing, already-flagged divergence noted on
            // audit_log.user_id (Sprint 2.0A's deliberately narrow scope).
            $table->char('uploaded_by_user_id', 26);
            $table->string('file_name');
            $table->string('status', 20)->default('preview');
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');

            $table->index('tenant_id');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE import_batches ADD CONSTRAINT import_batches_status_check CHECK (status IN (
                'preview','validated','committed','cancelled'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('import_batches');
    }
};
