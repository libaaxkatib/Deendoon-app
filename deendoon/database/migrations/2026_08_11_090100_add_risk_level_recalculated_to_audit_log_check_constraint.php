<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Sprint 2B — Risk Level Engine. Adds `risk_level_recalculated`
 * (AuditAction::RiskLevelRecalculated) to the audit_log.action CHECK
 * constraint, following the same additive DROP/ADD CONSTRAINT pattern as
 * every prior expansion of this list (see
 * 2026_07_26_090000_create_audit_log_table.php for the original set).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS audit_log_action_check');
            DB::statement("ALTER TABLE audit_log ADD CONSTRAINT audit_log_action_check CHECK (action IN (
                'created','edited','archived','restored','status_changed','reminder_sent','payment_added',
                'collection_requested','login','logout','role_changed','credit_limit_changed',
                'credit_score_recalculated','demand_letter_generated','receipt_generated','statement_generated',
                'invoice_generated','recovery_stage_override','professional_collection_request_submitted',
                'professional_collection_request_status_changed','risk_level_recalculated'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS audit_log_action_check');
            DB::statement("ALTER TABLE audit_log ADD CONSTRAINT audit_log_action_check CHECK (action IN (
                'created','edited','archived','restored','status_changed','reminder_sent','payment_added',
                'collection_requested','login','logout','role_changed','credit_limit_changed',
                'credit_score_recalculated','demand_letter_generated','receipt_generated','statement_generated',
                'invoice_generated','recovery_stage_override','professional_collection_request_submitted',
                'professional_collection_request_status_changed'
            ))");
        }
    }
};
