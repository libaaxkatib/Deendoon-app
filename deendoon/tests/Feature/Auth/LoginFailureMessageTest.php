<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * A failed login answers 401 with one message that does not reveal whether
 * the email exists: the same text for a wrong password and an unknown email.
 */
class LoginFailureMessageTest extends TestCase
{
    use RefreshDatabase;

    private const MESSAGE = 'User or password is incorrect.';

    public function test_a_wrong_password_returns_the_generic_message(): void
    {
        User::factory()->create(['email' => 'owner@example.com', 'password' => Hash::make('correct-password')]);

        $this->postJson('/api/v1/login', ['email' => 'owner@example.com', 'password' => 'wrong-password'])
            ->assertStatus(401)
            ->assertJson(['success' => false, 'message' => self::MESSAGE]);
    }

    public function test_an_unknown_email_returns_the_same_message(): void
    {
        $this->postJson('/api/v1/login', ['email' => 'nobody@example.com', 'password' => 'whatever-password'])
            ->assertStatus(401)
            ->assertJson(['success' => false, 'message' => self::MESSAGE]);
    }
}
