<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): a Business Owner may cancel their own still-pending
 * request before the Deendoon Platform Administrator reviews it — a fourth
 * status alongside the original 'pending'/'approved'/'rejected' set. Same
 * additive DROP/ADD CONSTRAINT pattern as every prior expansion of a CHECK
 * constraint in this codebase.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE subscription_change_requests DROP CONSTRAINT IF EXISTS subscription_change_requests_status_check');
            DB::statement("ALTER TABLE subscription_change_requests ADD CONSTRAINT subscription_change_requests_status_check CHECK (status IN (
                'pending','approved','rejected','cancelled'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE subscription_change_requests DROP CONSTRAINT IF EXISTS subscription_change_requests_status_check');
            DB::statement("ALTER TABLE subscription_change_requests ADD CONSTRAINT subscription_change_requests_status_check CHECK (status IN (
                'pending','approved','rejected'
            ))");
        }
    }
};
