<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Manual Mobile-Money Subscription Payment Flow (Product Owner decision):
 * the single, platform-level, Platform-Administrator-editable destination
 * mobile-money number shown to a Business Owner on the "Send Money" step.
 * Deliberately not tenant-scoped (no `tenant_id`) and not part of
 * `system_settings`, which is a one-row-per-tenant table (06_Database_Design.md
 * §6.8) — this is one row for the whole platform. `updated_by` mirrors the
 * existing `approved_by`/`reviewed_by` convention on
 * TenantSubscription/SubscriptionChangeRequest: no foreign key, since
 * `users.id` is a bigint auto-increment column, not a ULID.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platform_payment_settings', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('destination_mobile_money_number', 20)->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestampTz('updated_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_payment_settings');
    }
};
