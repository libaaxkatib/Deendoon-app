<?php

use App\Services\CustomerPhoneNumberService;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

/**
 * Fix #23 — Multiple Customer Phone Numbers. Mirrors `customer_attachments`'
 * per-entity-table shape/conventions exactly (own `tenant_id`, FK to
 * `customers`, composite index) rather than a generic polymorphic contacts
 * table. `customers.phone` is deliberately left untouched — it becomes a
 * maintained mirror of the primary row here ({@see
 * App\Services\CustomerPhoneNumberService}), not removed, so every existing
 * read path (duplicate detection, search, message rendering, older mobile
 * clients) keeps working unmodified. A maximum of 3 rows per customer and
 * "exactly one is_primary" are both enforced by
 * {@see CustomerPhoneNumberService}, not by a DB constraint —
 * SQLite (test suite) and PostgreSQL (dev/prod) would need materially
 * different conditional-unique-index syntax for "at most one is_primary
 * per customer," and the smallest correct enforcement here is the
 * application layer, consistent with this project's existing
 * validation-is-the-primary-enforcement / CHECK-constraints-are-Postgres-
 * only-defense-in-depth pattern already used on `customers` itself.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_phone_numbers', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('tenant_id', 26);
            $table->char('customer_id', 26);
            $table->string('phone', 30);
            $table->boolean('is_primary')->default(false);
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('tenant_id')->references('id')->on('tenants');
            $table->foreign('customer_id')->references('id')->on('customers');

            $table->index(['tenant_id', 'customer_id']);
        });

        // Backfill: every existing customer's single `phone` value becomes
        // its primary row here. Run in chunks to avoid loading the whole
        // table into memory on a large tenant.
        DB::table('customers')->orderBy('id')->chunkById(500, function ($customers) {
            $now = now();
            $rows = $customers->map(fn ($customer) => [
                'id' => (string) Str::ulid(),
                'tenant_id' => $customer->tenant_id,
                'customer_id' => $customer->id,
                'phone' => $customer->phone,
                'is_primary' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ])->all();

            if ($rows !== []) {
                DB::table('customer_phone_numbers')->insert($rows);
            }
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_phone_numbers');
    }
};
