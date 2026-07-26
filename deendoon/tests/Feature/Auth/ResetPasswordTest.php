<?php

namespace Tests\Feature\Auth;

use App\Models\PasswordResetToken;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ResetPasswordTest extends TestCase
{
    use RefreshDatabase;

    private function issueToken(string $email, ?Carbon $createdAt = null): string
    {
        $token = 'plain-test-token-'.$email;

        PasswordResetToken::updateOrCreate(
            ['email' => $email],
            ['token' => Hash::make($token), 'created_at' => $createdAt ?? now()],
        );

        return $token;
    }

    public function test_reset_password_succeeds_with_a_valid_token(): void
    {
        $user = User::factory()->create(['email' => 'asad@example.com', 'password' => Hash::make('OldPassword123!')]);
        $token = $this->issueToken('asad@example.com');

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $token,
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'message', 'data', 'errors']);

        $this->assertTrue(Hash::check('NewPassword123!', $user->fresh()->password));
        $this->assertDatabaseMissing('password_reset_tokens', ['email' => 'asad@example.com']);
    }

    public function test_reset_password_revokes_existing_tokens(): void
    {
        $user = User::factory()->create(['email' => 'asad@example.com']);
        $activeToken = $user->createToken('test')->plainTextToken;
        $resetToken = $this->issueToken('asad@example.com');

        $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $resetToken,
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])->assertStatus(200);

        $this->withHeader('Authorization', 'Bearer '.$activeToken)
            ->getJson('/api/v1/notifications')
            ->assertStatus(401);
    }

    public function test_reset_password_records_an_audit_log_entry(): void
    {
        $user = User::factory()->create(['email' => 'asad@example.com']);
        $token = $this->issueToken('asad@example.com');

        $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $token,
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'user',
            'entity_id' => (string) $user->id,
            'action' => 'edited',
        ]);
    }

    public function test_reset_password_rejects_an_invalid_token(): void
    {
        User::factory()->create(['email' => 'asad@example.com']);
        $this->issueToken('asad@example.com');

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => 'the-wrong-token',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    public function test_reset_password_rejects_an_expired_token(): void
    {
        User::factory()->create(['email' => 'asad@example.com']);
        $token = $this->issueToken('asad@example.com', now()->subMinutes(61));

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $token,
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    public function test_reset_password_rejects_a_token_that_has_already_been_used(): void
    {
        User::factory()->create(['email' => 'asad@example.com']);
        $token = $this->issueToken('asad@example.com');

        $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $token,
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])->assertStatus(200);

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $token,
            'password' => 'AnotherPassword123!',
            'password_confirmation' => 'AnotherPassword123!',
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    public function test_reset_password_rejects_a_nonexistent_email_with_the_same_generic_error(): void
    {
        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'nobody@example.com',
            'token' => 'anything',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    public function test_reset_password_rejects_a_password_confirmation_mismatch(): void
    {
        User::factory()->create(['email' => 'asad@example.com']);
        $token = $this->issueToken('asad@example.com');

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $token,
            'password' => 'NewPassword123!',
            'password_confirmation' => 'DoesNotMatch123!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['password']);
    }

    public function test_reset_password_enforces_the_global_password_policy(): void
    {
        User::factory()->create(['email' => 'asad@example.com']);
        $token = $this->issueToken('asad@example.com');

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => $token,
            'password' => 'Short11!',
            'password_confirmation' => 'Short11!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['password']);
    }

    public function test_reset_password_rejects_missing_fields(): void
    {
        $response = $this->postJson('/api/v1/reset-password', []);

        $response->assertStatus(422)->assertJsonValidationErrors(['email', 'token', 'password']);
    }

    public function test_reset_password_is_rate_limited(): void
    {
        User::factory()->create(['email' => 'asad@example.com']);
        $this->issueToken('asad@example.com');

        for ($i = 1; $i <= 5; $i++) {
            $this->postJson('/api/v1/reset-password', [
                'email' => 'asad@example.com',
                'token' => 'wrong-token',
                'password' => 'NewPassword123!',
                'password_confirmation' => 'NewPassword123!',
            ])->assertStatus(422);
        }

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => 'asad@example.com',
            'token' => 'wrong-token',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(429)->assertJson(['success' => false]);
    }
}
