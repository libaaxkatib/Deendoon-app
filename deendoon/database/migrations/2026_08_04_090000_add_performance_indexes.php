<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 13 — Performance Optimization. Three index gaps identified by
 * direct audit against `06_Database_Design.md` §10's own stated
 * principles, none of which is a new business rule or schema redesign:
 *
 * 1. `import_rows.resulting_customer_id` and `statements.debt_id` each
 *    already carry a `foreign()` constraint but no index — `06` §10 is
 *    explicit that "every foreign key... must be backed by an explicitly
 *    declared index" (PostgreSQL never indexes a plain FK automatically),
 *    the same principle every other FK in the schema already follows.
 * 2. `notifications(tenant_id, type, related_entity_type, related_entity_id)`
 *    covers the exact WHERE clause `NotificationService::notifyOnce()`
 *    already issues on every lazy Promise-to-Pay-Due check — none of the
 *    three indexes `06` §6.7 already lists for this table
 *    (`(recipient_user_id, read_at)`, `(recipient_user_id, type)`,
 *    `(tenant_id, created_at)`) covers this query shape.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('import_rows', function (Blueprint $table) {
            $table->index('resulting_customer_id');
        });

        Schema::table('statements', function (Blueprint $table) {
            $table->index('debt_id');
        });

        Schema::table('notifications', function (Blueprint $table) {
            $table->index(['tenant_id', 'type', 'related_entity_type', 'related_entity_id'], 'notifications_dedup_lookup_index');
        });
    }

    public function down(): void
    {
        Schema::table('import_rows', function (Blueprint $table) {
            $table->dropIndex(['resulting_customer_id']);
        });

        Schema::table('statements', function (Blueprint $table) {
            $table->dropIndex(['debt_id']);
        });

        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex('notifications_dedup_lookup_index');
        });
    }
};
