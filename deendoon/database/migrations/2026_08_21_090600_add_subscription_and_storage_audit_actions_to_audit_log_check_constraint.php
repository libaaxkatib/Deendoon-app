<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): adds `subscription_change_request_status_changed`/
 * `storage_addon_status_changed` (AuditAction::SubscriptionChangeRequestStatusChanged/
 * StorageAddonStatusChanged) to the audit_log.action CHECK constraint —
 * one action per domain covering approve/reject/cancel, mirroring
 * ProfessionalCollectionRequestStatusChanged's "one case spans multiple
 * outcomes" precedent rather than a granular case per outcome. Same
 * additive DROP/ADD CONSTRAINT pattern as every prior expansion of this
 * list (see 2026_08_17_090000_add_final_verification_audit_actions_to_audit_log_check_constraint.php).
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
                'professional_collection_request_status_changed','risk_level_recalculated',
                'subscription_upgrade_requested','storage_addon_requested','trial_expired','subscription_expired',
                'trial_provisioned','customer_read_only_recalculated','subscription_change_request_status_changed',
                'storage_addon_status_changed'
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
                'professional_collection_request_status_changed','risk_level_recalculated',
                'subscription_upgrade_requested','storage_addon_requested','trial_expired','subscription_expired',
                'trial_provisioned','customer_read_only_recalculated'
            ))");
        }
    }
};
