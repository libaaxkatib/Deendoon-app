<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('support_ticket_messages', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('support_ticket_id', 26);
            // CHAR(26), no FK — same users.id bigint gap flagged elsewhere.
            // Either the submitting Business Owner or the Platform Administrator.
            $table->char('sender_user_id', 26);
            $table->text('content');
            // No updated_at/deleted_at — messages are immutable, matching
            // request_messages' existing convention.
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('support_ticket_id', 'support_ticket_messages_ticket_id_foreign')
                ->references('id')->on('support_tickets');

            $table->index(['support_ticket_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_ticket_messages');
    }
};
