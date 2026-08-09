<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Final Product Completion Roadmap, P2.2 (Product Owner-approved
 * decision): persists Client Visit "Check In" — previously local-only,
 * in-memory Flutter state that reset on navigation
 * (`reminder_detail_screen.dart`'s own TODO). Deliberately separate from
 * `completed_at`: checking in does not complete the reminder ("Mark as
 * Completed" remains its own explicit action per §7.3's "transition[s] to
 * Completed only through an explicit user action" rule) — a Business
 * Owner may check in on arrival and still need to Log Visit Outcome/Mark
 * Complete afterward.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reminders', function (Blueprint $table) {
            $table->dateTime('checked_in_at')->nullable()->after('completed_at');
        });
    }

    public function down(): void
    {
        Schema::table('reminders', function (Blueprint $table) {
            $table->dropColumn('checked_in_at');
        });
    }
};
