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
        Schema::create('follow_up_history', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('debt_id', 26);
            // collection_case_id: CHAR(26) matches 06_Database_Design.md exactly.
            // No FK yet — collection_cases (Module 7) does not exist. Same
            // treatment as the users.id gap: column type kept faithful, FK
            // added once the target table exists.
            $table->char('collection_case_id', 26)->nullable();
            // actor_user_id: CHAR(26) matches 06 exactly. No FK — users.id is
            // still Laravel's default bigint, the same pre-existing,
            // already-flagged divergence noted on audit_log.user_id.
            $table->char('actor_user_id', 26)->nullable();
            $table->string('action_type', 30);
            $table->text('details')->nullable();
            $table->timestampTz('occurred_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->index(['tenant_id', 'debt_id', 'occurred_at']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE follow_up_history ADD CONSTRAINT follow_up_history_action_type_check CHECK (action_type IN (
                'reminder_sent','manual_whatsapp','manual_sms','call_logged','promise_recorded',
                'promise_fulfilled','promise_broken','payment_recorded','collection_activity','escalated'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('follow_up_history');
    }
};
