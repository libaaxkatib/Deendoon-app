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
        Schema::create('document_events', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->string('document_type', 20);
            // Polymorphic — points into whichever table document_type names.
            // No FK possible (three different target tables).
            $table->char('document_id', 26);
            $table->string('event_type', 20);
            // CHAR(26), no FK — same users.id bigint gap flagged elsewhere.
            // NULL for the automatic 'generated' event on Receipts.
            $table->char('user_id', 26)->nullable();
            $table->timestampTz('occurred_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');

            $table->index(['tenant_id', 'document_type', 'document_id', 'occurred_at']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE document_events ADD CONSTRAINT document_events_document_type_check CHECK (document_type IN (
                'receipt','demand_letter','statement'
            ))");
            DB::statement("ALTER TABLE document_events ADD CONSTRAINT document_events_event_type_check CHECK (event_type IN (
                'generated','downloaded','regenerated'
            ))");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('document_events');
    }
};
