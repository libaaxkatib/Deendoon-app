<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Final Product Completion Roadmap, P1.6 (Product Owner-approved
 * decision): a generic file attachment on a Customer, separate from the
 * 4 system-generated Document types (Receipt/DemandLetter/Statement/
 * Invoice) and separate from Professional Collection's own attachment
 * table. Mirrors `professional_collection_request_attachments`'
 * shape/conventions exactly, with its own `tenant_id` (unlike that
 * table, which deliberately omits one for cross-tenant Platform
 * Administrator visibility — no such requirement exists here), matching
 * the majority convention already used by Receipt/DemandLetter/
 * Statement/Invoice/Customer/Debt/CollectionCase. Reuses
 * `DocumentService::storeUploadedFile()`/`assertCanUpload()` for storage
 * and quota — this table's `file_size` is folded into
 * `DocumentService::storageUsage()`'s sum, the same way every other
 * document/attachment table already is.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_attachments', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('customer_id', 26);
            $table->char('uploaded_by_user_id', 26)->nullable();
            $table->string('file_path', 255);
            $table->string('original_filename', 255);
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('file_size');
            $table->string('description', 255)->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('customer_id')->references('id')->on('customers');

            $table->index(['tenant_id', 'customer_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_attachments');
    }
};
