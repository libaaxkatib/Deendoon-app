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
        Schema::create('notifications', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            // CHAR(26), no FK — same users.id bigint gap flagged elsewhere.
            $table->char('recipient_user_id', 26);
            $table->string('type', 50);
            $table->string('related_entity_type', 50);
            $table->char('related_entity_id', 26);
            $table->timestampTz('read_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');

            $table->index(['recipient_user_id', 'read_at']);
            $table->index(['recipient_user_id', 'type']);
            $table->index(['tenant_id', 'created_at']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN (
                'credit_limit_reached','payment_received','document_available','collection_assignment',
                'reminder_sent','promise_to_pay_due','professional_collection_request_update'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
