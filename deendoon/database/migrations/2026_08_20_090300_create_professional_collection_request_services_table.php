<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): multi-select Requested Services, sourced from the existing
 * Reference Data architecture (category `requested_service`). Same
 * label-storage convention as professional_collection_request_reasons —
 * see that migration's docblock.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('professional_collection_request_services', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('professional_collection_request_id', 26);
            $table->string('service_label', 100);
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('professional_collection_request_id', 'pcr_services_pcr_id_foreign')
                ->references('id')->on('professional_collection_requests');

            $table->unique(['professional_collection_request_id', 'service_label'], 'pcr_services_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('professional_collection_request_services');
    }
};
