<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): free-text comments accompanying the (multi-select, Reference
 * Data-backed) Reason for Transfer, and the Client Declaration acceptance
 * record. Authentication + accepted_by + accepted_at + the Audit Log are
 * the approved Version 1 legal-traceability mechanism — no digital
 * signature image.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('professional_collection_requests', function (Blueprint $table) {
            $table->text('transfer_notes')->nullable()->after('reference_number');
            $table->timestampTz('declaration_accepted_at')->nullable()->after('closed_at');
            // CHAR(26), no FK — same users.id bigint gap flagged elsewhere.
            $table->char('declaration_accepted_by_user_id', 26)->nullable()->after('declaration_accepted_at');
        });
    }

    public function down(): void
    {
        Schema::table('professional_collection_requests', function (Blueprint $table) {
            $table->dropColumn(['transfer_notes', 'declaration_accepted_at', 'declaration_accepted_by_user_id']);
        });
    }
};
