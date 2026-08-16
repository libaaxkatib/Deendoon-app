<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Module 9 — Notifications, Admin Announcements. All 14 pre-existing
 * notification types keep deriving their display purely from `type`
 * client-side, unchanged. Only the new `admin_announcement` type (next
 * migration) ever populates these two columns.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->string('title', 255)->nullable()->after('type');
            $table->text('message')->nullable()->after('title');
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropColumn(['title', 'message']);
        });
    }
};
