<?php

namespace Database\Seeders;

use App\Models\Tenant;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     *
     * Resolves SubscriptionService via the container explicitly (rather
     * than method injection) so this seeder keeps working when
     * instantiated directly — `(new DatabaseSeeder)->run()`, as
     * ProductionReadinessTest does to test the local/testing guard in
     * isolation — not only via `$this->call()`/`db:seed`, which are the
     * only paths that resolve `run()`'s parameters through the container.
     */
    public function run(): void
    {
        $subscriptions = app(SubscriptionService::class);

        $this->call(RoleSeeder::class);
        $this->call(SubscriptionPlanSeeder::class);

        // Phase 14 — Production Readiness (seeder safety): this account has
        // a well-known email and the UserFactory's shared default password
        // ('password'). RoleSeeder/SubscriptionPlanSeeder are safe to run
        // everywhere (roles and plans are real infrastructure, not test
        // data), but a known-credential account — and the tenant it
        // belongs to — must never be created outside local/testing —
        // guarded here rather than relying solely on operators remembering
        // to omit --seed in production (migrate/db:seed already require
        // --force in production per Laravel's own ConfirmableTrait; this
        // is defense-in-depth, not a replacement for that).
        //
        // Mirrors AuthController::register()'s real Business Owner
        // bootstrap (Tenant + admin User + Trial subscription) instead of
        // a bare, tenant-less/role-less account, so `migrate:fresh --seed`
        // alone leaves the Flutter app immediately usable — no manual
        // tinker step required, and no behavioral gap between this dev
        // account and a real signup.
        if (app()->environment(['local', 'testing']) && ! User::where('email', 'test@example.com')->exists()) {
            $tenant = Tenant::create(['business_name' => 'Debug']);

            $user = User::factory()->create([
                'name' => 'Test User',
                'email' => 'test@example.com',
            ]);
            $user->tenant_id = $tenant->id;
            $user->save();
            $user->assignRole('admin');

            $subscriptions->provisionTrial($tenant, $user);
        }

        // Message templates are provisioned per-tenant (Tenant::query()
        // ->each(...)), so this must run after the dev tenant above
        // exists — otherwise a fresh local environment's own tenant would
        // be skipped, the same gap Phase 1 of the Backend Completion
        // Audit already closed for real signups.
        $this->call(MessageTemplateSeeder::class);

        // Same rationale, same per-tenant loop pattern, for the
        // Professional Collection Reference Data fix (Reason for
        // Transfer / Requested Service default options).
        $this->call(ReferenceDataSeeder::class);
    }
}
