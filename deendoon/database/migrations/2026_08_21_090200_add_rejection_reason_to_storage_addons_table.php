<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): brings Storage Add-ons to parity with
 * subscription_change_requests, which has carried `rejection_reason` since
 * Phase 3.1. Free-text field for the Deendoon Platform Administrator's
 * optional additional notes on rejection — the predefined multi-select
 * reasons themselves live in the new `storage_addon_rejection_reasons`
 * table (mirroring `professional_collection_request_reasons`), not here.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('storage_addons', function (Blueprint $table) {
            $table->text('rejection_reason')->nullable()->after('approved_at');
        });
    }

    public function down(): void
    {
        Schema::table('storage_addons', function (Blueprint $table) {
            $table->dropColumn('rejection_reason');
        });
    }
};
