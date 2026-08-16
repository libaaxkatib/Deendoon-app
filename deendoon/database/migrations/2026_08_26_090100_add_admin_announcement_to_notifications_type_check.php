<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Module 9 — Notifications, Admin Announcements. Extends the existing
 * notifications.type CHECK constraint with the new Platform-Administrator
 * announcement event type, following the exact pattern already used for
 * the subscription/storage and support-ticket extensions.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check');
            DB::statement("ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN (
                'credit_limit_reached','payment_received','document_available','collection_assignment',
                'reminder_sent','promise_to_pay_due','professional_collection_request_update',
                'subscription_request_update','storage_request_update',
                'support_ticket_created','support_ticket_replied','support_ticket_status_changed',
                'support_ticket_closed','support_ticket_reopened','admin_announcement'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check');
            DB::statement("ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN (
                'credit_limit_reached','payment_received','document_available','collection_assignment',
                'reminder_sent','promise_to_pay_due','professional_collection_request_update',
                'subscription_request_update','storage_request_update',
                'support_ticket_created','support_ticket_replied','support_ticket_status_changed',
                'support_ticket_closed','support_ticket_reopened'
            ))");
        }
    }
};
