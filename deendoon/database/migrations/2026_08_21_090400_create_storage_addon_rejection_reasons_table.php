<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): same multi-select predefined rejection reasons pattern
 * as subscription_change_request_rejection_reasons, sourced from Reference
 * Data category `storage_rejection_reason`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('storage_addon_rejection_reasons', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('storage_addon_id', 26);
            $table->string('reason_label', 100);
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('storage_addon_id', 'storage_addon_rejection_reasons_addon_id_foreign')
                ->references('id')->on('storage_addons');

            $table->unique(['storage_addon_id', 'reason_label'], 'storage_addon_rejection_reasons_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('storage_addon_rejection_reasons');
    }
};
