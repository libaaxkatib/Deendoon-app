<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RefreshTokenTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_refresh_their_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/refresh');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['user', 'token']]);
    }

    public function test_refreshing_deletes_the_old_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;
        $oldTokenId = $user->tokens()->first()->id;

        $this->assertDatabaseCount('personal_access_tokens', 1);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/refresh');

        // Asserted against the database directly, not via a second live HTTP
        // call with the old token — this project's test suite has a known
        // Sanctum guard-caching quirk where a second bearer-token request
        // within the same test method isn't re-resolved from scratch.
        $this->assertDatabaseCount('personal_access_tokens', 1);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $oldTokenId]);
    }

    public function test_the_new_token_authenticates_successfully(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        $refreshResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/refresh');

        $newToken = $refreshResponse->json('data.token');

        $response = $this->withHeader('Authorization', 'Bearer '.$newToken)
            ->postJson('/api/v1/logout');

        $response->assertStatus(200)
            ->assertJson(['success' => true]);
    }

    public function test_unauthenticated_user_cannot_refresh(): void
    {
        $response = $this->postJson('/api/v1/refresh');

        $response->assertStatus(401)
            ->assertJson(['success' => false]);
    }
}
