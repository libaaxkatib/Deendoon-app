<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §7.7, §7.8;
 * docs/Backend_v2.1_Database_Alignment.md §3) — reusable, placeholder-based
 * WhatsApp/SMS message bodies. Distinct from the pre-existing
 * `document_templates` table, which is scoped specifically to the four
 * Demand Letter PDF templates — a different concept, not reused here.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('message_templates', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->string('name', 100);
            $table->string('channel', 20);
            $table->text('body');
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->index(['tenant_id', 'channel']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE message_templates ADD CONSTRAINT message_templates_channel_check CHECK (channel IN (
                'whatsapp','sms'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('message_templates');
    }
};
