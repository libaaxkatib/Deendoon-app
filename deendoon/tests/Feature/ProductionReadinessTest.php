<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Phase 14 — Production Readiness. Covers the concrete hardening fixes:
 * the 12-character password floor (08 §10), login/logout audit coverage
 * (08 §13), the general API rate limiter now being registered
 * (AppServiceProvider), DatabaseSeeder's known-credential guard, and the
 * Sanctum sliding idle-timeout (Product Owner Decision, 60 minutes).
 */
class ProductionReadinessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    // --- Password policy (08 §10: minimum 12 characters) ---

    public function test_registration_rejects_a_password_under_twelve_characters(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'name' => 'Asad Mohamed',
            'email' => 'short-pw@example.com',
            'password' => 'Short11!',
            'password_confirmation' => 'Short11!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['password']);
    }

    public function test_registration_accepts_a_twelve_character_password(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Acme Co',
            'name' => 'Asad Mohamed',
            'email' => 'ok-pw@example.com',
            'password' => 'TwelveChars1',
            'password_confirmation' => 'TwelveChars1',
        ]);

        $response->assertStatus(201);
    }

    // --- Login/logout audit coverage (08 §13) ---

    public function test_login_writes_an_audit_log_entry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create(['password' => Hash::make('Password123!')]);
        $user->tenant()->associate($tenant);
        $user->save();

        $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'Password123!',
        ])->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'user',
            'entity_id' => (string) $user->id,
            'action' => 'login',
            'user_id' => (string) $user->id,
        ]);
    }

    public function test_logout_writes_an_audit_log_entry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $token = $user->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/logout')
            ->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'user',
            'entity_id' => (string) $user->id,
            'action' => 'logout',
            'user_id' => (string) $user->id,
        ]);
    }

    // --- General API rate limiting (AppServiceProvider's 'api' RateLimiter) ---

    public function test_api_responses_carry_rate_limit_headers(): void
    {
        // Rate-limit headers are added by ThrottleRequests after $next()
        // returns normally — an exception-rendered response (e.g. the 401
        // AuthenticationException handler in bootstrap/app.php) bypasses
        // that entirely, so this must be a normally-completed request, not
        // an unauthenticated one.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/customers');

        $response->assertStatus(200)->assertHeader('X-RateLimit-Limit');
    }

    // --- Seeder safety: known-credential account never seeds outside local/testing ---

    public function test_database_seeder_skips_the_test_user_outside_local_and_testing(): void
    {
        // Instantiated directly (not via $this->seed()/db:seed) to test the
        // seeder's own internal guard in isolation — Artisan's db:seed
        // command has its own separate ConfirmableTrait prompt for
        // "production," which is a different, already-existing safety net
        // this test isn't exercising.
        $this->app->detectEnvironment(fn () => 'production');

        (new DatabaseSeeder)->run();

        $this->assertDatabaseMissing('users', ['email' => 'test@example.com']);
    }

    public function test_database_seeder_creates_the_test_user_in_testing(): void
    {
        (new DatabaseSeeder)->run();

        $this->assertDatabaseHas('users', ['email' => 'test@example.com']);
    }

    // --- Sanctum sliding idle timeout (Product Owner Decision: 60 minutes) ---

    public function test_a_freshly_created_never_used_token_is_accepted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $token = $user->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/notifications')
            ->assertStatus(200);
    }

    public function test_a_token_idle_for_under_sixty_minutes_is_accepted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $newToken = $user->createToken('test');

        $newToken->accessToken->forceFill(['last_used_at' => now()->subMinutes(59)])->save();

        $this->withHeader('Authorization', 'Bearer '.$newToken->plainTextToken)
            ->getJson('/api/v1/notifications')
            ->assertStatus(200);
    }

    public function test_a_token_idle_for_over_sixty_minutes_is_rejected_and_deleted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $newToken = $user->createToken('test');
        $tokenId = $newToken->accessToken->id;

        $newToken->accessToken->forceFill(['last_used_at' => now()->subMinutes(61)])->save();

        $response = $this->withHeader('Authorization', 'Bearer '.$newToken->plainTextToken)
            ->getJson('/api/v1/notifications');

        $response->assertStatus(401)->assertJson(['success' => false]);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $tokenId]);
    }
}
