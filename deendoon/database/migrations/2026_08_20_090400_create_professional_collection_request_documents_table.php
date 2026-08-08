<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): "the system must automatically include all existing
 * Customer/Debt documents already stored in Deendoon... Existing
 * documents must be linked by reference. Do NOT duplicate files already
 * stored." This is a pure link table — (document_type, document_id)
 * pointing at an existing Receipt/DemandLetter/Statement/Invoice row, no
 * file_path/file_size/content column of its own. Mirrors document_events'
 * existing polymorphic-by-convention design exactly (no FK on
 * document_id, since it can reference any of four different tables) —
 * see 06_Database_Design.md §6.6 and app/Models/DocumentEvent.php.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('professional_collection_request_documents', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('professional_collection_request_id', 26);
            $table->string('document_type', 30);
            $table->char('document_id', 26);
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('professional_collection_request_id', 'pcr_documents_pcr_id_foreign')
                ->references('id')->on('professional_collection_requests');

            $table->unique(['professional_collection_request_id', 'document_type', 'document_id'], 'pcr_documents_unique');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE professional_collection_request_documents ADD CONSTRAINT pcr_documents_type_check CHECK (document_type IN (
                'receipt','demand_letter','statement','invoice'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('professional_collection_request_documents');
    }
};
