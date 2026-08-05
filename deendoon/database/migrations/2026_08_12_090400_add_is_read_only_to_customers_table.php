<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Backend Completion Roadmap, Phase 3.1 — Subscription Database Foundation.
 * Database representation ONLY for Customer Read Only (approved Product
 * Owner decisions A/B: customers beyond a plan's limit become read-only;
 * the restriction cascades to related Debts/Collection Cases/Payments/
 * Reminders/Documents, enforced at the application layer, not here).
 * No enforcement, no recompute trigger, and no index is added in this
 * phase — Phase 3.1 is schema-only; indexing this column now would be
 * premature optimization with no real query pattern yet to support
 * (that pattern is introduced in Phase 4 — Subscription Enforcement).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->boolean('is_read_only')->default(false)->after('archived_at');
        });
    }

    public function down(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->dropColumn('is_read_only');
        });
    }
};
