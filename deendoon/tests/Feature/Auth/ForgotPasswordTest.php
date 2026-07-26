<?php

namespace Tests\Feature\Auth;

use App\Mail\PasswordResetMail;
use App\Models\PasswordResetToken;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class ForgotPasswordTest extends TestCase
{
    use RefreshDatabase;

    public function test_forgot_password_succeeds_for_an_existing_email(): void
    {
        Mail::fake();
        User::factory()->create(['email' => 'asad@example.com', 'password' => Hash::make('Password123!')]);

        $response = $this->postJson('/api/v1/forgot-password', ['email' => 'asad@example.com']);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'message', 'data', 'errors']);

        Mail::assertSent(PasswordResetMail::class, fn ($mail) => $mail->hasTo('asad@example.com'));
        $this->assertDatabaseHas('password_reset_tokens', ['email' => 'asad@example.com']);
    }

    public function test_forgot_password_returns_the_same_response_for_a_nonexistent_email(): void
    {
        Mail::fake();

        $response = $this->postJson('/api/v1/forgot-password', ['email' => 'nobody@example.com']);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'message', 'data', 'errors']);

        Mail::assertNothingSent();
        $this->assertDatabaseMissing('password_reset_tokens', ['email' => 'nobody@example.com']);
    }

    public function test_forgot_password_rejects_an_invalid_email_format(): void
    {
        $response = $this->postJson('/api/v1/forgot-password', ['email' => 'not-an-email']);

        $response->assertStatus(422)->assertJsonValidationErrors(['email']);
    }

    public function test_forgot_password_rejects_a_missing_email(): void
    {
        $response = $this->postJson('/api/v1/forgot-password', []);

        $response->assertStatus(422)->assertJsonValidationErrors(['email']);
    }

    public function test_forgot_password_does_not_reveal_a_deactivated_account(): void
    {
        Mail::fake();
        $user = User::factory()->create(['email' => 'archived@example.com']);
        $user->delete();

        $response = $this->postJson('/api/v1/forgot-password', ['email' => 'archived@example.com']);

        $response->assertStatus(200)->assertJson(['success' => true]);
        Mail::assertNothingSent();
    }

    public function test_requesting_a_new_token_supersedes_the_previous_one(): void
    {
        Mail::fake();
        User::factory()->create(['email' => 'asad@example.com']);

        $this->postJson('/api/v1/forgot-password', ['email' => 'asad@example.com'])->assertStatus(200);
        $firstToken = PasswordResetToken::where('email', 'asad@example.com')->first()->token;

        $this->postJson('/api/v1/forgot-password', ['email' => 'asad@example.com'])->assertStatus(200);
        $secondToken = PasswordResetToken::where('email', 'asad@example.com')->first()->token;

        $this->assertSame(1, PasswordResetToken::where('email', 'asad@example.com')->count());
        $this->assertNotSame($firstToken, $secondToken);
    }

    public function test_forgot_password_is_rate_limited(): void
    {
        Mail::fake();
        User::factory()->create(['email' => 'asad@example.com']);

        for ($i = 1; $i <= 5; $i++) {
            $this->postJson('/api/v1/forgot-password', ['email' => 'asad@example.com'])->assertStatus(200);
        }

        $response = $this->postJson('/api/v1/forgot-password', ['email' => 'asad@example.com']);

        $response->assertStatus(429)->assertJson(['success' => false]);
    }
}
