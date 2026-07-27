<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §7; docs/Backend_v2.1_UI_Mapping.md
 * §5; docs/Backend_v2.1_Database_Alignment.md §3) — the Reminder Center's
 * schedulable reminder entity. Genuinely new: no prior table represents a
 * user-scheduled, typed follow-up with a due date and a status lifecycle.
 * `follow_up_history` (past, already-occurred actions only) and
 * `notifications` (system-generated events only) are both deliberately
 * left untouched — neither is repurposed here.
 *
 * `completed_at` is the only persisted status flag; Today/Upcoming/Overdue
 * are derived from `due_date` at read time by the Smart Reminder Engine —
 * per §7.3's rule that a reminder "transition[s] to Completed only through
 * an explicit user action, not automatically upon its due date passing,"
 * read as constraining the Completed transition specifically, not the
 * Today/Upcoming/Overdue distinction, which is a direct function of the
 * due date by definition.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reminders', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('created_by_user_id', 26);
            $table->string('type', 30);
            $table->string('related_entity_type', 20);
            $table->char('related_entity_id', 26);
            $table->char('related_case_id', 26)->nullable();
            $table->dateTime('due_date');
            $table->decimal('amount_due', 12, 2)->nullable();
            $table->string('timing_rule', 20);
            $table->dateTime('custom_fire_at')->nullable();
            $table->json('delivery_methods');
            $table->text('notes')->nullable();
            $table->dateTime('completed_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->timestampTz('deleted_at')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('related_case_id')->references('id')->on('collection_cases');

            $table->index(['tenant_id', 'due_date', 'completed_at']);
            $table->index(['tenant_id', 'type']);
            $table->index(['tenant_id', 'related_entity_type', 'related_entity_id']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE reminders ADD CONSTRAINT reminders_type_check CHECK (type IN (
                'client_visit','follow_up_call','payment_due','contract_renewal','promise_to_pay'
            ))");

            DB::statement("ALTER TABLE reminders ADD CONSTRAINT reminders_related_entity_type_check CHECK (related_entity_type IN (
                'customer','debt','collection_case','promise_to_pay'
            ))");

            DB::statement("ALTER TABLE reminders ADD CONSTRAINT reminders_timing_rule_check CHECK (timing_rule IN (
                'one_day_before','same_day','one_hour_before','custom'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('reminders');
    }
};
