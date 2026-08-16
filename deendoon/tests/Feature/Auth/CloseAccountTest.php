<?php

namespace Tests\Feature\Auth;

use App\Models\Customer;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Mobile Play Store Readiness (Fix #3, Part B) — self-service Close
 * Account. Non-destructive by design: archives the User (SoftDeletes),
 * suspends the Tenant (`Tenant::suspend()`), revokes all tokens — no
 * tenant-owned record is touched.
 */
class CloseAccountTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    /**
     * @return array{0: Tenant, 1: User, 2: string}
     */
    private function businessOwner(string $password = 'OldPassword123!'): array
    {
        $tenant = Tenant::factory()->create();
        $user = User::factory()->create(['password' => Hash::make($password)]);
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');
        $token = $user->createToken('auth_token')->plainTextToken;

        return [$tenant, $user, $token];
    }

    public function test_closing_the_account_succeeds_with_the_correct_password(): void
    {
        [, , $token] = $this->businessOwner();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'message', 'data', 'errors']);
    }

    public function test_closing_the_account_rejects_an_incorrect_password(): void
    {
        [$tenant, $user, $token] = $this->businessOwner();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'WrongPassword123!',
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
        $this->assertNull($user->fresh()->archived_at);
        $this->assertSame('active', $tenant->fresh()->status);
    }

    public function test_closing_the_account_rejects_an_unauthenticated_request(): void
    {
        $response = $this->postJson('/api/v1/account/close', ['password' => 'OldPassword123!']);

        $response->assertStatus(401)->assertJson(['success' => false]);
    }

    public function test_closing_the_account_rejects_a_missing_password(): void
    {
        [, , $token] = $this->businessOwner();

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', []);

        $response->assertStatus(422)->assertJsonValidationErrors(['password']);
    }

    public function test_the_user_becomes_archived(): void
    {
        [, $user, $token] = $this->businessOwner();

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ])->assertStatus(200);

        $fresh = User::withTrashed()->find($user->id);
        $this->assertNotNull($fresh->archived_at);
        $this->assertSame('archived', $fresh->status);
    }

    public function test_the_tenant_becomes_suspended(): void
    {
        [$tenant, , $token] = $this->businessOwner();

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ])->assertStatus(200);

        $this->assertSame('suspended', $tenant->fresh()->status);
        $this->assertNotNull($tenant->fresh()->suspended_at);
    }

    /**
     * See ChangePasswordTest::test_change_password_revokes_every_existing_token()
     * for why `forgetGuards()` is required between the two requests within
     * one test method.
     */
    public function test_all_sanctum_tokens_are_revoked(): void
    {
        [, $user, $token] = $this->businessOwner();
        $otherToken = $user->createToken('other_device')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ])->assertStatus(200);

        $this->assertSame(0, $user->tokens()->count());

        $this->app['auth']->forgetGuards();

        $this->withHeader('Authorization', 'Bearer '.$otherToken)
            ->getJson('/api/v1/notifications')
            ->assertStatus(401);
    }

    public function test_login_is_blocked_after_closure(): void
    {
        [, $user, $token] = $this->businessOwner();

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ])->assertStatus(200);

        $response = $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'OldPassword123!',
        ]);

        $response->assertStatus(401);
    }

    public function test_tenant_business_data_remains_intact(): void
    {
        [$tenant, $user, $token] = $this->businessOwner();
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ])->assertStatus(200);

        $this->assertDatabaseHas('customers', ['id' => $customer->id, 'tenant_id' => $tenant->id]);
        $this->assertDatabaseHas('users', ['id' => $user->id, 'tenant_id' => $tenant->id]);
    }

    public function test_closing_the_account_records_audit_log_entries_for_both_user_and_tenant(): void
    {
        [$tenant, $user, $token] = $this->businessOwner();

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ])->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'user', 'entity_id' => (string) $user->id, 'action' => 'archived',
        ]);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'tenant', 'entity_id' => $tenant->id, 'action' => 'status_changed',
        ]);
    }

    public function test_a_platform_administrator_cannot_close_their_own_account_via_this_endpoint(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');
        $token = $admin->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'password',
        ]);

        $response->assertStatus(403);
        $this->assertNull($admin->fresh()->archived_at);
    }

    public function test_closing_one_tenants_account_does_not_affect_another_tenant(): void
    {
        [, , $token] = $this->businessOwner();
        [$otherTenant, $otherUser] = $this->businessOwner('Password123!');

        $this->withHeader('Authorization', 'Bearer '.$token)->postJson('/api/v1/account/close', [
            'password' => 'OldPassword123!',
        ])->assertStatus(200);

        $this->assertSame('active', $otherTenant->fresh()->status);
        $this->assertNull($otherUser->fresh()->archived_at);
    }
}
