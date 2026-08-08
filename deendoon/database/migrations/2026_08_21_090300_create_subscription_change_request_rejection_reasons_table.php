<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): multi-select predefined rejection reasons, sourced
 * from the existing Reference Data architecture (category
 * `subscription_rejection_reason`) — same "store the selected value_label
 * string, one row per selection" convention already established by
 * `professional_collection_request_reasons` (Transfer Case to Deendoon
 * Recovery Team).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_change_request_rejection_reasons', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('subscription_change_request_id', 26);
            $table->string('reason_label', 100);
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('subscription_change_request_id', 'scr_rejection_reasons_scr_id_foreign')
                ->references('id')->on('subscription_change_requests');

            $table->unique(['subscription_change_request_id', 'reason_label'], 'scr_rejection_reasons_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_change_request_rejection_reasons');
    }
};
