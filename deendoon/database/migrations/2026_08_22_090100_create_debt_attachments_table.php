<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Final Product Completion Roadmap, P1.6 (Product Owner-approved
 * decision): a generic file attachment on a Debt — same shape/conventions
 * as `customer_attachments` (see that migration's docblock). Scan/Upload
 * Invoice (P2.6/P2.7) reuse this exact table as pure storage rather than
 * inventing a separate invoice-capture backend — a scanned or uploaded
 * invoice is simply a Debt Attachment, distinguished only by its capture
 * method and `description` caption.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('debt_attachments', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('debt_id', 26);
            $table->char('uploaded_by_user_id', 26)->nullable();
            $table->string('file_path', 255);
            $table->string('original_filename', 255);
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('file_size');
            $table->string('description', 255)->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->index(['tenant_id', 'debt_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('debt_attachments');
    }
};
