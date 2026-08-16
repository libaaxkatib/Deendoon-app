<?php

use App\Services\SecurityEventLogger;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Module 8 — System Management, Security Events. Persists exactly the 4
 * event shapes {@see SecurityEventLogger} already emits to
 * the file-based `security` log channel (config/logging.php) — no new
 * event type is invented here. The file channel is NOT replaced; this is
 * an additional write path so the Admin Panel has something queryable to
 * list/filter, matching AuditLog's existing insert-only precedent
 * (2026_07_26_090000_create_audit_log_table.php).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('security_events', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('event_type', 50);
            $table->string('email', 255)->nullable();
            // CHAR(26), no FK — same users.id bigint gap already flagged
            // on audit_log.user_id.
            $table->char('user_id', 26)->nullable();
            $table->char('tenant_id', 26)->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('method', 10)->nullable();
            $table->string('path', 255)->nullable();
            $table->string('token_id', 100)->nullable();
            $table->boolean('account_exists')->nullable();
            $table->timestampTz('occurred_at')->useCurrent();

            $table->index('event_type');
            $table->index('occurred_at');
            $table->index('email');
            $table->index('user_id');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE security_events ADD CONSTRAINT security_events_event_type_check CHECK (event_type IN (
                'login_failed','password_reset_requested','token_revoked_idle','permission_denied'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('security_events');
    }
};
