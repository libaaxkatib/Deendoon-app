<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Final Product Completion Roadmap, P2.13 (Product Owner-approved
 * decision, mobile Item 13): a free-text street address so Client Visit
 * reminders' "Navigate" action can open a real location instead of a
 * text search on the customer's name alone. Nullable/optional — most
 * existing customers won't have one, and it's not required by FR-007.
 * SRS/06_Database_Design.md §6.2 and FR-007 amended alongside this.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->string('address', 500)->nullable()->after('phone');
        });
    }

    public function down(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->dropColumn('address');
        });
    }
};
