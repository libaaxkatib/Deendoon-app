<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Module 7 — Support & Tickets (Product Owner-approved V1). Deliberately
 * NOT scoped via BelongsToTenant — the Deendoon Platform Administrator's
 * cross-tenant view/reply/close/reopen access is a second, bimodal
 * authorization path that trait can't express, matching
 * ProfessionalCollectionRequest's exact precedent (see that model's
 * docblock): every query here is scoped by hand in the controllers.
 *
 * No assignment column (Decision 7 — Deendoon currently has one Super
 * Admin). `category`/`priority` are plain CHECK-constrained columns, not
 * `reference_data` rows: the Product Owner gave a fixed, literal 8/4-value
 * list rather than an admin-configurable one, so this matches
 * `professional_collection_requests.status`'s existing enum-via-CHECK
 * convention rather than reusing the (tenant/admin-editable)
 * `reference_data` architecture built for a different shape of problem.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('support_tickets', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            // CHAR(26), no FK — same users.id bigint gap flagged elsewhere.
            $table->char('submitted_by_user_id', 26);
            $table->string('reference_number', 20)->nullable();
            $table->string('subject', 255);
            $table->text('description');
            $table->string('status', 20)->default('open');
            $table->string('priority', 10);
            $table->string('category', 50);
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->timestampTz('closed_at')->nullable();
            $table->timestampTz('reopened_at')->nullable();

            $table->foreign('tenant_id')->references('id')->on('tenants');

            $table->unique(['tenant_id', 'reference_number']);
            $table->index('status');
            $table->index('priority');
            $table->index('category');
            $table->index(['tenant_id', 'status']);
            $table->index(['tenant_id', 'created_at']);
        });

        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE support_tickets ADD CONSTRAINT support_tickets_status_check CHECK (status IN (
                'open','in_progress','resolved','closed'
            ))");
            DB::statement("ALTER TABLE support_tickets ADD CONSTRAINT support_tickets_priority_check CHECK (priority IN (
                'low','medium','high','urgent'
            ))");
            DB::statement("ALTER TABLE support_tickets ADD CONSTRAINT support_tickets_category_check CHECK (category IN (
                'technical_issue','payment_billing','account','subscription','debt_recovery','professional_collection','feature_request','other'
            ))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('support_tickets');
    }
};
