<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * FR-005 — Change Password. The authenticated counterpart to
 * ForgotPasswordTest/ResetPasswordTest (FR-004): proves ownership via the
 * caller's current password rather than a mailed token.
 */
class ChangePasswordTest extends TestCase
{
    use RefreshDatabase;

    private function authenticatedUser(string $currentPassword = 'OldPassword123!'): array
    {
        $user = User::factory()->create(['password' => Hash::make($currentPassword)]);
        $token = $user->createToken('auth_token')->plainTextToken;

        return [$user, $token];
    }

    public function test_change_password_succeeds_with_the_correct_current_password(): void
    {
        [$user, $token] = $this->authenticatedUser();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', [
            'current_password' => 'OldPassword123!',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'message', 'data', 'errors']);

        $this->assertTrue(Hash::check('NewPassword123!', $user->fresh()->password));
    }

    public function test_change_password_rejects_an_incorrect_current_password(): void
    {
        [, $token] = $this->authenticatedUser();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', [
            'current_password' => 'WrongPassword123!',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    public function test_change_password_leaves_the_password_unchanged_when_current_password_is_wrong(): void
    {
        [$user, $token] = $this->authenticatedUser();

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', [
            'current_password' => 'WrongPassword123!',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $this->assertTrue(Hash::check('OldPassword123!', $user->fresh()->password));
    }

    /**
     * Checks a *second*, previously-issued token distinct from the one
     * authenticating this request — not the same token twice — and forgets
     * the resolved auth guard before the follow-up call. Sanctum's guard
     * caches its resolved user for the lifetime of the guard instance, and
     * within a single test method Laravel reuses the same container (and
     * therefore the same guard) across simulated requests; without
     * `forgetGuards()`, the second request would return the first
     * request's cached user regardless of the token actually sent — a
     * test-harness artifact only, since a real deployment never reuses the
     * same process across requests. The direct token-count assertion below
     * is the reliable, guard-cache-independent proof; the HTTP check
     * confirms the guard itself also rejects it once freshly resolved.
     */
    public function test_change_password_revokes_every_existing_token(): void
    {
        [$user, $token] = $this->authenticatedUser();
        $otherToken = $user->createToken('other_device')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', [
            'current_password' => 'OldPassword123!',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])->assertStatus(200);

        $this->assertSame(0, $user->fresh()->tokens()->count());

        $this->app['auth']->forgetGuards();

        $this->withHeader('Authorization', 'Bearer '.$otherToken)
            ->getJson('/api/v1/notifications')
            ->assertStatus(401);
    }

    public function test_change_password_records_an_audit_log_entry(): void
    {
        [$user, $token] = $this->authenticatedUser();

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', [
            'current_password' => 'OldPassword123!',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'user',
            'entity_id' => (string) $user->id,
            'action' => 'edited',
        ]);
    }

    public function test_change_password_rejects_a_password_confirmation_mismatch(): void
    {
        [, $token] = $this->authenticatedUser();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', [
            'current_password' => 'OldPassword123!',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'DoesNotMatch123!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['password']);
    }

    public function test_change_password_enforces_the_global_password_policy(): void
    {
        [, $token] = $this->authenticatedUser();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', [
            'current_password' => 'OldPassword123!',
            'password' => 'Short11!',
            'password_confirmation' => 'Short11!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['password']);
    }

    public function test_change_password_rejects_missing_fields(): void
    {
        [, $token] = $this->authenticatedUser();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/change-password', []);

        $response->assertStatus(422)->assertJsonValidationErrors(['current_password', 'password']);
    }

    public function test_change_password_rejects_an_unauthenticated_request(): void
    {
        $response = $this->postJson('/api/v1/change-password', [
            'current_password' => 'OldPassword123!',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(401)->assertJson(['success' => false]);
    }
}
