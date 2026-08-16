<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Reuses DocumentService's existing storage-quota enforcement
 * (assertCanUpload()/storeUploadedFile()) — this table's file_size is
 * added to DocumentService::storageUsage()'s sum, the same way
 * ProfessionalCollectionRequestAttachment's was added, so quota
 * enforcement stays a single source of truth.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('support_ticket_attachments', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('support_ticket_id', 26);
            $table->char('uploaded_by_user_id', 26)->nullable();
            $table->string('file_path', 255);
            $table->string('original_filename', 255);
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('file_size');
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('support_ticket_id', 'support_ticket_attachments_ticket_id_foreign')
                ->references('id')->on('support_tickets');

            $table->index('support_ticket_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_ticket_attachments');
    }
};
