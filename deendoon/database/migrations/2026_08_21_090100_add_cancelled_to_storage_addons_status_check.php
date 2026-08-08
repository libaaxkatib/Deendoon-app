<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): same 'cancelled' status added to the mirrored Storage
 * Add-on workflow, for the same reason documented in
 * 2026_08_21_090000_add_cancelled_to_subscription_change_requests_status_check.php.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE storage_addons DROP CONSTRAINT IF EXISTS storage_addons_status_check');
            DB::statement("ALTER TABLE storage_addons ADD CONSTRAINT storage_addons_status_check CHECK (status IN (
                'pending','active','expired','rejected','cancelled'
            ))");
        }
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE storage_addons DROP CONSTRAINT IF EXISTS storage_addons_status_check');
            DB::statement("ALTER TABLE storage_addons ADD CONSTRAINT storage_addons_status_check CHECK (status IN (
                'pending','active','expired','rejected'
            ))");
        }
    }
};
