<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Backend Completion Roadmap, Phase 3.1 — Subscription Database Foundation.
 * Storage Add-ons are purchased separately from the subscription plan
 * (Product Owner decision) via the same manual-payment
 * request/approve/reject/activate pattern as `subscription_change_requests`
 * — `status` values ('pending'/'active'/'expired'/'rejected') mirror that.
 * `storage_package` is a CHECK-guarded enum of the 4 approved package
 * sizes (10GB/25GB/50GB/100GB); `storage_size` carries the corresponding
 * numeric GB value, both columns as explicitly listed in the approved
 * Phase 3.1 spec.
 *
 * A tenant may accumulate multiple rows over time (one per request); no
 * "at most one active add-on" constraint is added here — not an approved
 * business rule yet, matching the same restraint documented in
 * `2026_08_12_090200_create_subscription_change_requests_table.php`.
 *
 * `approved_by` is CHAR(26) with no foreign key, for the same `users.id`
 * bigint/ULID mismatch reason documented in the tenant_subscriptions
 * migration.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('storage_addons', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->string('storage_package', 20);
            $table->integer('storage_size');
            $table->decimal('monthly_price', 8, 2);
            $table->timestampTz('started_at')->nullable();
            $table->timestampTz('expires_at')->nullable();
            $table->char('approved_by', 26)->nullable();
            $table->timestampTz('approved_at')->nullable();
            $table->string('status', 20)->default('pending');
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');

            $table->index(['tenant_id', 'status']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE storage_addons ADD CONSTRAINT storage_addons_package_check CHECK (storage_package IN (
                '10gb','25gb','50gb','100gb'
            ))");

            DB::statement("ALTER TABLE storage_addons ADD CONSTRAINT storage_addons_status_check CHECK (status IN (
                'pending','active','expired','rejected'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('storage_addons');
    }
};
