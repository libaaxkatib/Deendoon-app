<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Create Account (Mobile Registration) — Product Owner-approved decision:
 * the Business Owner signup form collects a phone number. Nullable at the
 * schema level so it doesn't break users created before this column
 * existed; `RegisterRequest` enforces "required" for new registrations at
 * the application layer, per this project's own "Constraints Before
 * Code... Validation belongs in the application. Integrity belongs in
 * the database" convention.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 30)->nullable()->after('email');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('phone');
        });
    }
};
