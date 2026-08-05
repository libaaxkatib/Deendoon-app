<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Backend Completion Roadmap, Phase 3.1 — Subscription Database Foundation.
 * One row per tenant (`unique('tenant_id')`), mirroring `system_settings`.
 * `status` values ('trialing'/'active'/'expired') are the only ones
 * approved so far (Product Owner decisions on trial expiration and paid
 * subscription expiration); no additional status is invented here.
 *
 * `approved_by` is CHAR(26) with no foreign key — `users.id` is a bigint
 * auto-increment (see `2014_10_12_000000_create_users_table.php`), not a
 * ULID, the same pre-existing type mismatch already documented and worked
 * around identically for `professional_collection_requests
 * .submitted_by_user_id`/`.actioned_by_user_id`. Not fixed here — Phase 0
 * confirmed no database redesign is required, and this is a known,
 * accepted gap, not new.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_subscriptions', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('plan_id', 26);
            $table->string('status', 20)->default('trialing');
            $table->timestampTz('started_at');
            $table->timestampTz('expires_at')->nullable();
            $table->timestampTz('trial_started_at')->nullable();
            $table->timestampTz('trial_ends_at')->nullable();
            $table->char('approved_by', 26)->nullable();
            $table->timestampTz('approved_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('plan_id')->references('id')->on('subscription_plans');

            $table->unique('tenant_id');
            $table->index('plan_id');
            $table->index('status');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE tenant_subscriptions ADD CONSTRAINT tenant_subscriptions_status_check CHECK (status IN (
                'trialing','active','expired'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_subscriptions');
    }
};
