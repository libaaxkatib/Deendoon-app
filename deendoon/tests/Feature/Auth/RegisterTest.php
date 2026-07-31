<?php

namespace Tests\Feature\Auth;

use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): registration creates a new Tenant and its
 * single Business Owner account (role `admin`) together.
 */
class RegisterTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_with_valid_data(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'email' => 'asad@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['user' => ['id', 'name', 'email'], 'token'],
                'errors',
            ]);

        $this->assertDatabaseHas('users', ['email' => 'asad@example.com']);
        $this->assertDatabaseHas('tenants', ['business_name' => 'Asad Trading Co.']);

        $user = User::where('email', 'asad@example.com')->firstOrFail();
        $this->assertNotSame('Password123!', $user->password);
        $this->assertStringStartsWith('$argon2id$', $user->password);
        $this->assertTrue($user->hasRole('admin'));
        $this->assertSame(Tenant::where('business_name', 'Asad Trading Co.')->firstOrFail()->id, $user->tenant_id);
    }

    public function test_registration_normalizes_email_to_lowercase_and_trimmed(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'email' => '  Asad@Example.COM  ',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('users', ['email' => 'asad@example.com']);
        $this->assertDatabaseMissing('users', ['email' => '  Asad@Example.COM  ']);
    }

    public function test_registration_is_rate_limited(): void
    {
        $payload = fn (int $i): array => [
            'business_name' => "Business {$i}",
            'name' => "User {$i}",
            'email' => "user{$i}@example.com",
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ];

        for ($i = 1; $i <= 5; $i++) {
            $this->postJson('/api/v1/register', $payload($i))->assertStatus(201);
        }

        $response = $this->postJson('/api/v1/register', $payload(6));

        $response->assertStatus(429)->assertJson(['success' => false]);
    }

    public function test_registration_fails_with_missing_fields(): void
    {
        $response = $this->postJson('/api/v1/register', []);

        $response->assertStatus(422)
            ->assertJson(['success' => false])
            ->assertJsonValidationErrors(['business_name', 'name', 'email', 'password']);
    }

    public function test_registration_fails_with_duplicate_email(): void
    {
        User::factory()->create(['email' => 'duplicate@example.com']);

        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Another Business',
            'name' => 'Another User',
            'email' => 'duplicate@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['email']);
    }
}
