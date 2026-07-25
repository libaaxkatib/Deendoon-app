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
        Schema::create('professional_collection_requests', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            // Identifies the *submitting* business. Deliberately NOT scoped
            // via the BelongsToTenant trait — the Deendoon Platform
            // Administrator's cross-tenant read/action access (06 §2, BR-042)
            // is a second, bimodal authorization path this trait can't
            // express; the model and controllers handle it explicitly.
            $table->char('tenant_id', 26);
            $table->char('collection_case_id', 26);
            $table->string('reference_number', 20)->nullable();
            $table->string('status', 30)->default('submitted');
            // CHAR(26), no FK — same users.id bigint gap flagged elsewhere.
            $table->char('submitted_by_user_id', 26);
            $table->char('actioned_by_user_id', 26)->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->timestampTz('closed_at')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('collection_case_id')->references('id')->on('collection_cases');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index('status');
            $table->index(['tenant_id', 'status']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE professional_collection_requests ADD CONSTRAINT pcr_status_check CHECK (status IN (
                'submitted','under_review','need_more_information','accepted','assigned','in_progress','recovered','closed'
            ))");

            // BRL-078: at most one active Request per Collection Case.
            DB::statement("CREATE UNIQUE INDEX pcr_one_active_per_case ON professional_collection_requests (collection_case_id) WHERE status NOT IN ('recovered', 'closed')");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('professional_collection_requests');
    }
};
