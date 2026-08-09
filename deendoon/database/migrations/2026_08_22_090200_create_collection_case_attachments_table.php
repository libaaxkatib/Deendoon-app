<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Final Product Completion Roadmap, P1.6 (Product Owner-approved
 * decision): a generic file attachment on a Collection Case — same
 * shape/conventions as `customer_attachments` (see that migration's
 * docblock).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('collection_case_attachments', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('collection_case_id', 26);
            $table->char('uploaded_by_user_id', 26)->nullable();
            $table->string('file_path', 255);
            $table->string('original_filename', 255);
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('file_size');
            $table->string('description', 255)->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('collection_case_id')->references('id')->on('collection_cases');

            $table->index(['tenant_id', 'collection_case_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('collection_case_attachments');
    }
};
