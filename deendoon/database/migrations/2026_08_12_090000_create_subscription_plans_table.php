<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Backend Completion Roadmap, Phase 3.1 — Subscription Database Foundation.
 * A global reference/catalog table (no tenant_id): the 5 approved plans
 * (Trial, Free, Small Business, Medium Business, Corporate) are shared
 * platform-wide, not per-tenant data. `customer_limit` is nullable to
 * represent Corporate's approved "Unlimited customers" without inventing
 * a magic sentinel value. Row data itself (the 5 plans, their limits and
 * prices) is not seeded by this migration — schema only, per Phase 3.1
 * scope (no business logic yet).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('name', 50)->unique();
            $table->integer('customer_limit')->nullable();
            $table->boolean('analytics_enabled')->default(true);
            $table->integer('storage_limit');
            $table->decimal('monthly_price', 8, 2);
            $table->boolean('active')->default(true);
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_plans');
    }
};
