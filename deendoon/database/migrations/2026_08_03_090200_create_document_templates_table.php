<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * 06_Database_Design.md §6.8 — the four Demand Letter templates, per
 * tenant (FR-069, part of System Preferences).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('document_templates', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->string('template_type', 20);
            $table->text('content');
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->unique(['tenant_id', 'template_type']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE document_templates ADD CONSTRAINT document_templates_template_type_check CHECK (template_type IN (
                'first_reminder','second_reminder','final_demand','legal_notice'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('document_templates');
    }
};
