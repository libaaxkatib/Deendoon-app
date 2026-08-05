<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Backend Completion Roadmap, Phase 3.1 — Subscription Database Foundation.
 * Backs the approved Manual Payment workflow (Request -> Pending ->
 * Administrator Review -> Approve/Reject -> Activate). `status` values
 * ('pending'/'approved'/'rejected') are exactly the three states that
 * workflow describes — no additional state invented.
 *
 * Deliberately NOT added here (out of Phase 3.1 scope, business logic):
 * any uniqueness constraint limiting a tenant to one pending request at a
 * time. Unlike `professional_collection_requests`'s partial unique index
 * (BRL-078, an explicitly approved business rule at the time that table
 * was built), no equivalent "one pending request per tenant" rule has
 * been approved for Subscription yet — adding one now would be inventing
 * a business rule, not implementing an approved one.
 *
 * `reviewed_by` is CHAR(26) with no foreign key, for the same `users.id`
 * bigint/ULID mismatch reason documented in
 * `2026_08_12_090100_create_tenant_subscriptions_table.php`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_change_requests', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('requested_plan_id', 26);
            $table->char('current_plan_id', 26)->nullable();
            $table->string('payment_reference', 100)->nullable();
            $table->string('status', 20)->default('pending');
            $table->timestampTz('requested_at')->useCurrent();
            $table->char('reviewed_by', 26)->nullable();
            $table->timestampTz('reviewed_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('requested_plan_id')->references('id')->on('subscription_plans');
            $table->foreign('current_plan_id')->references('id')->on('subscription_plans');

            $table->index(['tenant_id', 'status']);
            $table->index('status');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE subscription_change_requests ADD CONSTRAINT subscription_change_requests_status_check CHECK (status IN (
                'pending','approved','rejected'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_change_requests');
    }
};
