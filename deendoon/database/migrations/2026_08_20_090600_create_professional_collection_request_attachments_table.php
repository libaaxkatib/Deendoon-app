<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): "Additional Supporting Documents that are specific to the
 * Professional Collection Request." Newly uploaded files belong only to
 * the Request (never duplicated from/into the existing Receipt/Demand
 * Letter/Statement/Invoice tables — those are linked by reference in
 * professional_collection_request_documents instead). `timeline_event_id`
 * is nullable: null when uploaded at submission time or independently of
 * any specific recovery activity, set when uploaded as evidence attached
 * to a particular Professional Collection Timeline event. Reuses
 * DocumentService's existing storage-quota enforcement
 * (assertCanUpload()) — this table's file_size is added to
 * DocumentService::storageUsage()'s sum, the same way Invoice's was
 * added in Phase 4.2, so quota enforcement stays a single source of truth.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('professional_collection_request_attachments', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('professional_collection_request_id', 26);
            $table->char('timeline_event_id', 26)->nullable();
            $table->char('uploaded_by_user_id', 26)->nullable();
            $table->string('file_path', 255);
            $table->string('original_filename', 255);
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('file_size');
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('professional_collection_request_id', 'pcr_attachments_pcr_id_foreign')
                ->references('id')->on('professional_collection_requests');
            $table->foreign('timeline_event_id', 'pcr_attachments_timeline_event_id_foreign')
                ->references('id')->on('professional_collection_timeline_events');

            $table->index('professional_collection_request_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('professional_collection_request_attachments');
    }
};
