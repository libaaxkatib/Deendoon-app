<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

/**
 * Sprint 1.2 — Security Hardening. Covers the cross-cutting additions:
 * the AuthorizationException envelope fix, response security headers,
 * the 'security' log channel's five event types, and the trusted-proxies
 * opt-in default. Token revocation on deactivate/role-change is covered
 * in AdministrationTest.php, next to the endpoints that trigger it.
 */
class SecurityHardeningTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function actingAsTenantUser(Tenant $tenant, string $role = 'admin'): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole($role);

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    // --- AuthorizationException now matches the project's response envelope ---

    public function test_a_permission_denied_response_matches_the_standard_envelope(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, 'sales_finance');

        $response = $this->getJson('/api/v1/admin/users');

        $response->assertStatus(403)
            ->assertJsonStructure(['success', 'message', 'data', 'errors'])
            ->assertJson(['success' => false, 'data' => null, 'errors' => null]);
    }

    // --- Security headers ---

    public function test_responses_carry_standard_security_headers(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers');

        $response->assertHeader('X-Content-Type-Options', 'nosniff')
            ->assertHeader('X-Frame-Options', 'DENY')
            ->assertHeader('Referrer-Policy', 'no-referrer');
    }

    public function test_authenticated_responses_are_marked_not_cacheable(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers');

        $response->assertHeader('Cache-Control', 'no-store, private');
    }

    public function test_unauthenticated_responses_still_carry_security_headers(): void
    {
        $response = $this->postJson('/api/v1/login', ['email' => 'nobody@example.com', 'password' => 'wrong']);

        $response->assertHeader('X-Content-Type-Options', 'nosniff');
    }

    // --- Security event logging ---

    public function test_a_failed_login_is_written_to_the_security_log(): void
    {
        Log::shouldReceive('channel')->once()->with('security')->andReturnSelf();
        Log::shouldReceive('warning')->once()->with('Login failed', \Mockery::on(
            fn ($context) => $context['event'] === 'login_failed' && $context['email'] === 'asad@example.com',
        ));

        User::factory()->create(['email' => 'asad@example.com', 'password' => Hash::make('Password123!')]);

        $this->postJson('/api/v1/login', [
            'email' => 'asad@example.com',
            'password' => 'WrongPassword!',
        ])->assertStatus(401);
    }

    public function test_a_password_reset_request_is_written_to_the_security_log(): void
    {
        Log::shouldReceive('channel')->once()->with('security')->andReturnSelf();
        Log::shouldReceive('info')->once()->with('Password reset requested', \Mockery::on(
            fn ($context) => $context['event'] === 'password_reset_requested' && $context['account_exists'] === false,
        ));

        $this->postJson('/api/v1/forgot-password', ['email' => 'nobody@example.com'])->assertStatus(200);
    }

    public function test_an_idle_token_revocation_is_written_to_the_security_log(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $newToken = $user->createToken('test');
        $newToken->accessToken->forceFill(['last_used_at' => now()->subMinutes(61)])->save();

        Log::shouldReceive('channel')->once()->with('security')->andReturnSelf();
        Log::shouldReceive('info')->once()->with('Token revoked for inactivity', \Mockery::on(
            fn ($context) => $context['event'] === 'token_revoked_idle',
        ));

        $this->withHeader('Authorization', 'Bearer '.$newToken->plainTextToken)
            ->getJson('/api/v1/notifications')
            ->assertStatus(401);
    }

    public function test_a_permission_denied_response_is_written_to_the_security_log(): void
    {
        Log::shouldReceive('channel')->once()->with('security')->andReturnSelf();
        Log::shouldReceive('warning')->once()->with('Permission denied', \Mockery::on(
            fn ($context) => $context['event'] === 'permission_denied',
        ));

        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, 'sales_finance');

        $this->getJson('/api/v1/admin/users')->assertStatus(403);
    }

    // --- Trusted proxies: opt-in only, default behavior unchanged ---

    public function test_forwarded_for_header_cannot_be_used_to_evade_rate_limiting(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create(['email' => 'asad@example.com', 'password' => Hash::make('Password123!')]);
        $user->tenant()->associate($tenant);
        $user->save();

        // The 'login' limiter keys by email+IP. If a spoofed X-Forwarded-For
        // were honored (it must not be — TRUSTED_PROXIES is unset), each
        // request below would land in its own bucket and never trip the
        // limit; since it isn't trusted, all five share the real test-client
        // IP's single bucket and the sixth attempt is still throttled.
        for ($i = 1; $i <= 5; $i++) {
            $this->withHeader('X-Forwarded-For', "203.0.113.{$i}")
                ->postJson('/api/v1/login', ['email' => 'asad@example.com', 'password' => 'WrongPassword!'])
                ->assertStatus(401);
        }

        $response = $this->withHeader('X-Forwarded-For', '203.0.113.99')
            ->postJson('/api/v1/login', ['email' => 'asad@example.com', 'password' => 'WrongPassword!']);

        $response->assertStatus(429);
    }
}
