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
        Schema::create('audit_log', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26)->nullable();
            // CHAR(26) matches 06_Database_Design.md exactly (forward-compatible
            // with users.id once it migrates to ULID). No FK constraint is
            // possible today: users.id is still Laravel's default bigint, a
            // pre-existing, already-flagged divergence from the approved
            // schema (Sprint 2.0A's deliberately narrow scope) — not
            // something introduced here. See the Customer Module report's
            // NON-BLOCKING issues.
            $table->char('user_id', 26)->nullable();
            $table->string('action', 50);
            $table->string('entity_type', 50);
            $table->char('entity_id', 26);
            $table->string('reason', 500)->nullable();
            $table->timestampTz('occurred_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');

            $table->index(['tenant_id', 'occurred_at']);
            $table->index(['entity_type', 'entity_id']);
            $table->index(['user_id', 'occurred_at']);
            $table->index('action');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE audit_log ADD CONSTRAINT audit_log_action_check CHECK (action IN (
                'created','edited','archived','restored','status_changed','reminder_sent','payment_added',
                'collection_requested','login','logout','role_changed','credit_limit_changed',
                'credit_score_recalculated','demand_letter_generated','receipt_generated','statement_generated',
                'recovery_stage_override','professional_collection_request_submitted',
                'professional_collection_request_status_changed'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('audit_log');
    }
};
