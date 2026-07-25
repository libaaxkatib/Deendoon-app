<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_with_valid_credentials(): void
    {
        User::factory()->create([
            'email' => 'asad@example.com',
            'password' => Hash::make('Password123!'),
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => 'asad@example.com',
            'password' => 'Password123!',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['user' => ['id', 'name', 'email'], 'token'],
                'errors',
            ]);
    }

    public function test_login_with_mixed_case_and_padded_email_succeeds(): void
    {
        User::factory()->create([
            'email' => 'asad@example.com',
            'password' => Hash::make('Password123!'),
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => '  Asad@Example.COM  ',
            'password' => 'Password123!',
        ]);

        $response->assertStatus(200)->assertJson(['success' => true]);
    }

    public function test_login_is_rate_limited(): void
    {
        User::factory()->create([
            'email' => 'asad@example.com',
            'password' => Hash::make('Password123!'),
        ]);

        for ($i = 1; $i <= 5; $i++) {
            $this->postJson('/api/v1/login', [
                'email' => 'asad@example.com',
                'password' => 'WrongPassword!',
            ])->assertStatus(401);
        }

        $response = $this->postJson('/api/v1/login', [
            'email' => 'asad@example.com',
            'password' => 'WrongPassword!',
        ]);

        $response->assertStatus(429)->assertJson(['success' => false]);
    }

    public function test_login_fails_with_invalid_password(): void
    {
        User::factory()->create([
            'email' => 'asad@example.com',
            'password' => Hash::make('Password123!'),
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => 'asad@example.com',
            'password' => 'WrongPassword!',
        ]);

        $response->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    public function test_login_fails_for_nonexistent_user(): void
    {
        $response = $this->postJson('/api/v1/login', [
            'email' => 'nobody@example.com',
            'password' => 'Password123!',
        ]);

        $response->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    public function test_login_fails_with_missing_fields(): void
    {
        $response = $this->postJson('/api/v1/login', []);

        $response->assertStatus(422)->assertJsonValidationErrors(['email', 'password']);
    }
}
