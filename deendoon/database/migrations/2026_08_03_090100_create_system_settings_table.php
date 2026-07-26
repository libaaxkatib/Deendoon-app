<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * 06_Database_Design.md §6.8 — tenant-level configurable policy (FR-069).
 * One row per tenant.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_settings', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->decimal('default_credit_limit', 12, 2);
            $table->boolean('credit_limit_reminder_enabled')->default(true);
            $table->decimal('soft_limit_warning_threshold', 5, 2)->nullable();
            $table->jsonb('whatsapp_reminder_days')->nullable();
            $table->jsonb('sms_reminder_days')->nullable();
            $table->jsonb('call_reminder_days')->nullable();
            $table->smallInteger('professional_collection_threshold_days')->nullable();
            $table->jsonb('notification_settings')->nullable();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->unique('tenant_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('system_settings');
    }
};
