<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mobile Fix #22 — Google Login. `google_id` stores Google's stable `sub`
 * claim (never the email, which can change) — nullable/unique so a
 * password-only account has no row here until it's explicitly linked, and
 * two users can never share one Google identity. `password` becomes
 * nullable to correctly represent a Google-only account that has never
 * set one — AuthController::login()/PasswordResetService::changePassword()
 * are updated in the same fix to treat a null password as "no password
 * login possible" rather than passing null into Hash::check().
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('google_id', 255)->nullable()->unique()->after('phone');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('google_id');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable(false)->change();
        });
    }
};
