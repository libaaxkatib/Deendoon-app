<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): a dedicated Professional Collection Timeline, independent
 * of the Audit Log (which records system/data changes) and independent
 * of the existing, unchanged Customer Collection Timeline
 * (DebtController::timeline()) — this one records the Deendoon Recovery
 * Team's own operational recovery activities after a case is transferred.
 * `officer_user_id` has no FK, matching the same users.id bigint gap
 * already flagged for actor_user_id/recorded_by_user_id elsewhere in this
 * schema (e.g. collection_cases.assigned_officer_user_id).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('professional_collection_timeline_events', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('professional_collection_request_id', 26);
            $table->string('event_type', 30);
            $table->char('officer_user_id', 26)->nullable();
            $table->timestampTz('occurred_at');
            $table->text('notes')->nullable();
            $table->string('outcome', 50)->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('professional_collection_request_id', 'pcr_timeline_pcr_id_foreign')
                ->references('id')->on('professional_collection_requests');

            $table->index(['professional_collection_request_id', 'occurred_at']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE professional_collection_timeline_events ADD CONSTRAINT pcr_timeline_event_type_check CHECK (event_type IN (
                'pending_review','documents_verified','assigned','initial_contact','telephone_collection',
                'whatsapp_follow_up','sms_follow_up','email_collection','meeting','field_visit',
                'payment_negotiation','settlement_negotiation','installment_arrangement','official_demand_letter',
                'skip_tracing','legal_review','court_preparation','partial_recovery','fully_recovered','closed'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('professional_collection_timeline_events');
    }
};
