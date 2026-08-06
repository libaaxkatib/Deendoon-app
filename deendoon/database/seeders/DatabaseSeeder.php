<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call(RoleSeeder::class);
        $this->call(SubscriptionPlanSeeder::class);
        $this->call(MessageTemplateSeeder::class);

        // Phase 14 — Production Readiness (seeder safety): this account has
        // a well-known email and the UserFactory's shared default password
        // ('password'). RoleSeeder is safe to run everywhere (roles are
        // real infrastructure, not test data), but a known-credential
        // account must never be created outside local/testing — guarded
        // here rather than relying solely on operators remembering to omit
        // --seed in production (migrate/db:seed already require --force in
        // production per Laravel's own ConfirmableTrait; this is
        // defense-in-depth, not a replacement for that).
        if (app()->environment(['local', 'testing'])) {
            User::factory()->create([
                'name' => 'Test User',
                'email' => 'test@example.com',
            ]);
        }
    }
}
