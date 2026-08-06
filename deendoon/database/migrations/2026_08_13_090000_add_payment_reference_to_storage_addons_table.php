<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Backend Completion Roadmap, Phase 3.3 (Product Owner correction):
 * payment_reference is now required on both Subscription Upgrade
 * Requests and Storage Add-on Requests. subscription_change_requests
 * already had this column (Phase 3.1); storage_addons never did. Column
 * itself stays nullable, matching subscription_change_requests.
 * payment_reference's type exactly — required-ness is enforced at the
 * application/FormRequest layer, not the schema layer, for consistency
 * with that existing column.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('storage_addons', function (Blueprint $table) {
            $table->string('payment_reference', 100)->nullable()->after('monthly_price');
        });
    }

    public function down(): void
    {
        Schema::table('storage_addons', function (Blueprint $table) {
            $table->dropColumn('payment_reference');
        });
    }
};
