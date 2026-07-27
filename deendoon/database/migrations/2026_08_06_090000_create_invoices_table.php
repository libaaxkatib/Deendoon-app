<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Sprint 4.1 — the final document type (docs/Mobile_UI_V1_Frozen.md §8.2).
 * Mirrors receipts/demand_letters exactly (Product Owner Decision: manual
 * generation, not automatic on Debt creation, per this sprint's Business
 * Rules) — same column shape, same reference-number pattern (INV-),
 * file_size included from creation (Receipt/DemandLetter/Statement only
 * gained it via a follow-up migration in Sprint 4; Invoice starts with
 * it).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('debt_id', 26);
            $table->string('reference_number', 20);
            $table->timestampTz('generated_at')->useCurrent();
            $table->string('file_path', 500);
            $table->unsignedBigInteger('file_size')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('debt_id')->references('id')->on('debts');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index('debt_id');
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE document_events DROP CONSTRAINT IF EXISTS document_events_document_type_check');
            DB::statement("ALTER TABLE document_events ADD CONSTRAINT document_events_document_type_check CHECK (document_type IN (
                'receipt','demand_letter','statement','invoice'
            ))");

            DB::statement('ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS audit_log_action_check');
            DB::statement("ALTER TABLE audit_log ADD CONSTRAINT audit_log_action_check CHECK (action IN (
                'created','edited','archived','restored','status_changed','reminder_sent','payment_added',
                'collection_requested','login','logout','role_changed','credit_limit_changed',
                'credit_score_recalculated','demand_letter_generated','receipt_generated','statement_generated',
                'invoice_generated','recovery_stage_override','professional_collection_request_submitted',
                'professional_collection_request_status_changed'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE document_events DROP CONSTRAINT IF EXISTS document_events_document_type_check');
            DB::statement("ALTER TABLE document_events ADD CONSTRAINT document_events_document_type_check CHECK (document_type IN (
                'receipt','demand_letter','statement'
            ))");

            DB::statement('ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS audit_log_action_check');
            DB::statement("ALTER TABLE audit_log ADD CONSTRAINT audit_log_action_check CHECK (action IN (
                'created','edited','archived','restored','status_changed','reminder_sent','payment_added',
                'collection_requested','login','logout','role_changed','credit_limit_changed',
                'credit_score_recalculated','demand_letter_generated','receipt_generated','statement_generated',
                'recovery_stage_override','professional_collection_request_submitted',
                'professional_collection_request_status_changed'
            ))");
        }
    }
};
