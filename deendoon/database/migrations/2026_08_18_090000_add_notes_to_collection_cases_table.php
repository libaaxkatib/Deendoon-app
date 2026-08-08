<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Business Owner Backend Completion (pre-Phase 5): FR-043 (Collection Case
 * Update) previously had no editable field beyond assignment (retired) and
 * closure, leaving PUT /collection-cases/{id} a functional no-op. Adds a
 * `notes` field matching the exact same pattern already used on
 * `debts.notes` — a free-text case annotation, distinct from the
 * chronological follow_up_history activity log.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('collection_cases', function (Blueprint $table) {
            $table->text('notes')->nullable()->after('closure_outcome');
        });
    }

    public function down(): void
    {
        Schema::table('collection_cases', function (Blueprint $table) {
            $table->dropColumn('notes');
        });
    }
};
