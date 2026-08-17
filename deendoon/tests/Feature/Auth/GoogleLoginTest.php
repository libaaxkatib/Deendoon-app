<?php

namespace Tests\Feature\Auth;

use App\Exceptions\InvalidGoogleTokenException;
use App\Models\Tenant;
use App\Models\User;
use App\Services\GoogleIdTokenVerifier;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Mobile Fix #22 — Google Login. Mocks {@see GoogleIdTokenVerifier} at the
 * controller boundary (the same shape as Log::shouldReceive() elsewhere in
 * this codebase's security tests) — these tests exercise the account-
 * resolution/linking-refusal/registration orchestration in AuthController,
 * not JWT verification itself (that's GoogleIdTokenVerifierTest, unit-
 * level). No real Google account or network call is used anywhere here.
 */
class GoogleLoginTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(SubscriptionPlanSeeder::class);
    }

    private function fakeVerifiedIdentity(array $identity): void
    {
        $this->mock(GoogleIdTokenVerifier::class, function ($mock) use ($identity) {
            $mock->shouldReceive('verify')->with('valid-token')->andReturn($identity);
        });
    }

    // --- google-login: existing Google-linked user ---

    public function test_an_existing_google_linked_user_logs_in_successfully(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create([
            'tenant_id' => $tenant->id,
            'email' => 'asad@example.com',
            'google_id' => 'google-sub-123',
        ]);
        $user->assignRole('admin');

        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-123',
            'email' => 'asad@example.com',
            'email_verified' => true,
            'name' => 'Asad Mohamed',
        ]);

        $response = $this->postJson('/api/v1/google-login', ['id_token' => 'valid-token']);

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'message', 'data' => ['user' => ['id', 'name', 'email', 'phone'], 'token'], 'errors'])
            ->assertJson(['success' => true, 'data' => ['user' => ['email' => 'asad@example.com']]]);
    }

    public function test_the_same_google_sub_cannot_create_duplicate_users(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create(['tenant_id' => $tenant->id, 'google_id' => 'google-sub-123']);
        $user->assignRole('admin');

        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-123',
            'email' => $user->email,
            'email_verified' => true,
            'name' => 'Asad Mohamed',
        ]);

        $this->postJson('/api/v1/google-login', ['id_token' => 'valid-token'])
            ->assertStatus(200)
            ->assertJson(['success' => true]);

        $this->assertSame(1, User::where('google_id', 'google-sub-123')->count());
    }

    // --- google-login: no google_id match ---

    public function test_a_new_google_identity_with_no_matching_email_signals_registration_required(): void
    {
        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-999',
            'email' => 'brandnew@example.com',
            'email_verified' => true,
            'name' => 'Brand New',
        ]);

        $response = $this->postJson('/api/v1/google-login', ['id_token' => 'valid-token']);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'registration_required' => true,
                    'google' => ['email' => 'brandnew@example.com', 'name' => 'Brand New'],
                ],
            ]);

        $this->assertDatabaseMissing('users', ['email' => 'brandnew@example.com']);
    }

    public function test_a_google_email_matching_an_existing_password_account_does_not_silently_authenticate_or_link(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $existing = User::factory()->create([
            'tenant_id' => $tenant->id,
            'email' => 'asad@example.com',
            'password' => Hash::make('Password123!'),
            'google_id' => null,
        ]);
        $existing->assignRole('admin');

        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-new',
            'email' => 'asad@example.com',
            'email_verified' => true,
            'name' => 'Asad Mohamed',
        ]);

        $response = $this->postJson('/api/v1/google-login', ['id_token' => 'valid-token']);

        $response->assertStatus(409)->assertJson(['success' => false]);

        $this->assertNull($existing->fresh()->google_id);
        $this->assertGuest();
    }

    // --- google-login: invalid token ---

    public function test_an_invalid_google_token_returns_401_not_a_validation_error(): void
    {
        $this->mock(GoogleIdTokenVerifier::class, function ($mock) {
            $mock->shouldReceive('verify')->with('bad-token')
                ->andThrow(new InvalidGoogleTokenException('signature mismatch'));
        });

        $this->postJson('/api/v1/google-login', ['id_token' => 'bad-token'])
            ->assertStatus(401)
            ->assertJson(['success' => false, 'data' => null]);
    }

    public function test_id_token_is_the_only_accepted_field_client_supplied_email_is_ignored(): void
    {
        // GoogleLoginRequest has no email/name rule at all — a client
        // cannot assert an identity, only the mocked (in real life,
        // server-verified) token result ever determines who this is.
        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-1',
            'email' => 'real-verified-owner@example.com',
            'email_verified' => true,
            'name' => 'Real Owner',
        ]);

        $response = $this->postJson('/api/v1/google-login', [
            'id_token' => 'valid-token',
            'email' => 'attacker@example.com',
            'name' => 'Attacker',
        ]);

        $response->assertStatus(200)
            ->assertJson(['data' => ['google' => ['email' => 'real-verified-owner@example.com']]]);
    }

    // --- google-register: new account creation ---

    public function test_a_new_google_identity_completes_registration_with_a_business_name(): void
    {
        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-999',
            'email' => 'brandnew@example.com',
            'email_verified' => true,
            'name' => 'Brand New',
        ]);

        $response = $this->postJson('/api/v1/google-register', [
            'id_token' => 'valid-token',
            'business_name' => 'Brand New Trading Co.',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['success', 'message', 'data' => ['user' => ['id', 'name', 'email', 'phone'], 'token'], 'errors'])
            ->assertJson(['success' => true, 'data' => ['user' => ['email' => 'brandnew@example.com', 'name' => 'Brand New']]]);

        $this->assertDatabaseHas('tenants', ['business_name' => 'Brand New Trading Co.']);
        $user = User::where('email', 'brandnew@example.com')->firstOrFail();
        $this->assertSame('google-sub-999', $user->google_id);
        $this->assertNull($user->password);
        $this->assertTrue($user->hasRole('admin'));
    }

    public function test_google_register_refuses_when_an_account_for_the_identity_already_exists(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create(['tenant_id' => $tenant->id, 'google_id' => 'google-sub-123']);
        $user->assignRole('admin');

        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-123',
            'email' => $user->email,
            'email_verified' => true,
            'name' => 'Asad Mohamed',
        ]);

        $this->postJson('/api/v1/google-register', [
            'id_token' => 'valid-token',
            'business_name' => 'Should Not Be Created',
        ])->assertStatus(409);

        $this->assertDatabaseMissing('tenants', ['business_name' => 'Should Not Be Created']);
    }

    public function test_google_register_requires_a_business_name(): void
    {
        $this->fakeVerifiedIdentity([
            'sub' => 'google-sub-999',
            'email' => 'brandnew@example.com',
            'email_verified' => true,
            'name' => 'Brand New',
        ]);

        $this->postJson('/api/v1/google-register', ['id_token' => 'valid-token'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('business_name');
    }

    // --- password login unaffected (Google-only accounts and regression) ---

    public function test_password_login_still_works_for_existing_password_users(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create([
            'tenant_id' => $tenant->id,
            'email' => 'asad@example.com',
            'password' => Hash::make('Password123!'),
        ]);
        $user->assignRole('admin');

        $this->postJson('/api/v1/login', [
            'email' => 'asad@example.com',
            'password' => 'Password123!',
        ])->assertStatus(200)->assertJson(['success' => true]);
    }

    public function test_a_google_only_account_cannot_password_login_and_does_not_error(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create([
            'tenant_id' => $tenant->id,
            'email' => 'googleonly@example.com',
            'password' => null,
            'google_id' => 'google-sub-1',
        ]);
        $user->assignRole('admin');

        $this->postJson('/api/v1/login', [
            'email' => 'googleonly@example.com',
            'password' => 'anything-at-all',
        ])->assertStatus(401)->assertJson(['success' => false]);
    }
}
