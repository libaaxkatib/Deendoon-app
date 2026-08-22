<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Manual Mobile-Money Subscription Payment Flow (Product Owner decision):
 * captures the phone number the payment was sent from, alongside the
 * existing free-text `payment_reference`. Nullable to keep this an
 * additive, backward-compatible column — matches the exact pattern of
 * `2026_08_13_090000_add_payment_reference_to_storage_addons_table.php`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subscription_change_requests', function (Blueprint $table) {
            $table->string('payment_phone', 20)->nullable()->after('payment_reference');
        });
    }

    public function down(): void
    {
        Schema::table('subscription_change_requests', function (Blueprint $table) {
            $table->dropColumn('payment_phone');
        });
    }
};
