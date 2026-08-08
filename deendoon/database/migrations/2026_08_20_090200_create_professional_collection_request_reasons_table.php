<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): multi-select Reason for Transfer, sourced from the existing
 * Reference Data architecture (category `transfer_reason`). Stores the
 * selected `value_label` string directly, matching the convention already
 * established by every other Reference Data consumer in this codebase
 * (Customer.risk_level, Payment.payment_method, CollectionCase.
 * closure_outcome all store the label, not a foreign key to reference_data
 * — ReferenceDataService::isValueInUse() matches on this exact string) —
 * one row per selected reason rather than a single column, since this is
 * the first multi-select consumer.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('professional_collection_request_reasons', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('professional_collection_request_id', 26);
            $table->string('reason_label', 100);
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('professional_collection_request_id', 'pcr_reasons_pcr_id_foreign')
                ->references('id')->on('professional_collection_requests');

            $table->unique(['professional_collection_request_id', 'reason_label'], 'pcr_reasons_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('professional_collection_request_reasons');
    }
};
