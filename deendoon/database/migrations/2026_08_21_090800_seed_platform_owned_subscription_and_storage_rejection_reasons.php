<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record, Decision 4) — Release Readiness correction (Product
 * Owner-approved): predefined multi-select Rejection Reasons must be
 * available on a fresh V1 installation with zero manual operator step.
 * `database/seeders/DatabaseSeeder.php` is deliberately not the vehicle
 * here — it carries unrelated pending local work that must not be
 * touched, and it is the only code path Laravel automatically invokes for
 * `db:seed`/`migrate --seed` (with no `--seeder` flag), so any Seeder not
 * called from it requires a manual, easy-to-forget operator step.
 * Migrations, unlike seeding, always run unconditionally on
 * `php artisan migrate` — the one provisioning mechanism guaranteed to
 * execute on every fresh install. This also matches 06_Database_Design's
 * own framing of Seeders as development/testing convenience rather than
 * production-required data.
 *
 * Replaces `database/seeders/SubscriptionRejectionReasonSeeder.php`
 * (deleted) — this migration is now the single source of truth for these
 * 8 rows, not a second copy of the same data.
 *
 * Idempotent by hand (existence-check then insert-or-update), not
 * `DB::table()->updateOrInsert()`: `reference_data` has no unique
 * constraint on (tenant_id, category, value_label), and updateOrInsert()
 * applies its `$values` array on both the insert AND the update path —
 * which would have to include a freshly generated `id` for the insert
 * path, and would then silently reassign an already-seeded row's primary
 * key to a new random ULID on every re-run. This generates `id` only on
 * the insert branch, leaving an already-seeded row's identity untouched.
 */
return new class extends Migration
{
    /**
     * @return array<int, string>
     */
    private function reasons(): array
    {
        return [
            'Payment Not Verified',
            'Insufficient Payment Amount',
            'Duplicate Request',
            'Invalid Payment Reference',
        ];
    }

    public function up(): void
    {
        foreach (['subscription_rejection_reason', 'storage_rejection_reason'] as $category) {
            foreach ($this->reasons() as $index => $label) {
                $this->seedOne($category, $label, $index);
            }
        }
    }

    private function seedOne(string $category, string $label, int $sortOrder): void
    {
        $match = fn () => DB::table('reference_data')
            ->whereNull('tenant_id')
            ->where('category', $category)
            ->where('value_label', $label);

        if ($match()->exists()) {
            $match()->update(['sort_order' => $sortOrder, 'is_active' => true]);

            return;
        }

        DB::table('reference_data')->insert([
            'id' => (string) Str::ulid(),
            'tenant_id' => null,
            'category' => $category,
            'value_label' => $label,
            'sort_order' => $sortOrder,
            'is_active' => true,
            'created_at' => now(),
        ]);
    }

    public function down(): void
    {
        DB::table('reference_data')
            ->whereNull('tenant_id')
            ->whereIn('category', ['subscription_rejection_reason', 'storage_rejection_reason'])
            ->whereIn('value_label', $this->reasons())
            ->delete();
    }
};
