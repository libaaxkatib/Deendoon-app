<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): adds `subscription_request_update`/`storage_request_update`
 * (NotificationType::SubscriptionRequestUpdate/StorageRequestUpdate) to the
 * notifications.type CHECK constraint — the Business Owner is notified
 * when the Deendoon Platform Administrator approves/rejects their pending
 * request, mirroring ProfessionalCollectionRequestUpdate's existing
 * "one type per domain" precedent.
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
                'subscription_request_update','storage_request_update'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check');
            DB::statement("ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN (
                'credit_limit_reached','payment_received','document_available','collection_assignment',
                'reminder_sent','promise_to_pay_due','professional_collection_request_update'
            ))");
        }
    }
};
