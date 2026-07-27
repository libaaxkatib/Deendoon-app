<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §7.7, §7.8, §8.8;
 * docs/Backend_v2.1_Database_Alignment.md §3, §8) — records every
 * WhatsApp/SMS dispatch, for the "every send is recorded... for audit
 * purposes" rule repeated across §7.7/§7.8/§8.8. `reminder_id`/`case_id`/
 * `document_id` are mutually-exclusive-in-practice nullable references
 * (at most one populated per row, matching whichever source the send
 * originated from), avoiding a join table for what the approved
 * documents describe as at-most-one-source-per-send.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sent_messages', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('template_id', 26)->nullable();
            $table->char('reminder_id', 26)->nullable();
            $table->char('case_id', 26)->nullable();
            $table->string('document_type', 20)->nullable();
            $table->char('document_id', 26)->nullable();
            $table->string('channel', 20);
            $table->string('recipient_phone', 30);
            $table->text('rendered_text');
            $table->string('status', 20)->default('sent');
            $table->char('sent_by_user_id', 26);
            $table->timestampTz('sent_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('template_id')->references('id')->on('message_templates');
            $table->foreign('reminder_id')->references('id')->on('reminders');
            $table->foreign('case_id')->references('id')->on('collection_cases');

            $table->index(['tenant_id', 'reminder_id']);
            $table->index(['tenant_id', 'case_id']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE sent_messages ADD CONSTRAINT sent_messages_channel_check CHECK (channel IN (
                'whatsapp','sms'
            ))");

            DB::statement("ALTER TABLE sent_messages ADD CONSTRAINT sent_messages_status_check CHECK (status IN (
                'sent','failed'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('sent_messages');
    }
};
