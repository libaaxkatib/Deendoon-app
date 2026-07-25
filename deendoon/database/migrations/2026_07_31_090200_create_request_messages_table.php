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
        Schema::create('request_messages', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('professional_collection_request_id', 26);
            // CHAR(26), no FK — same users.id bigint gap flagged elsewhere.
            // Either a tenant user or the Deendoon Platform Administrator.
            $table->char('sender_user_id', 26);
            $table->text('content');
            // No updated_at/deleted_at — messages are immutable (BRL-080).
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('professional_collection_request_id', 'request_messages_pcr_id_foreign')
                ->references('id')->on('professional_collection_requests');

            $table->index(['professional_collection_request_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('request_messages');
    }
};
