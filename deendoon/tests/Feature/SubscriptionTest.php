<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\StorageAddon;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 3.3 — Business Owner Subscription
 * APIs. Covers authentication, authorization, validation, tenant
 * isolation, response structure, and success/failure cases for all 6
 * endpoints.
 */
class SubscriptionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function actingAsTenantUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');

        Sanctum::actingAs($user, ['*']);

        return $user;
    }

    private function actingAsPlatformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        Sanctum::actingAs($admin, ['*']);

        return $admin;
    }

    // --- Authentication ---

    public function test_unauthenticated_requests_are_rejected_on_every_endpoint(): void
    {
        $this->getJson('/api/v1/subscription')->assertStatus(401);
        $this->getJson('/api/v1/subscription/plans')->assertStatus(401);
        $this->getJson('/api/v1/subscription/change-requests')->assertStatus(401);
        $this->postJson('/api/v1/subscription/upgrade-request')->assertStatus(401);
        $this->getJson('/api/v1/subscription/storage')->assertStatus(401);
        $this->postJson('/api/v1/subscription/storage-addon-request')->assertStatus(401);
    }

    // --- Authorization: Business Owner only ---

    public function test_platform_administrator_is_forbidden_from_every_endpoint(): void
    {
        // Valid payloads on the 2 POST endpoints, matching this
        // codebase's established FormRequest pattern (authorize()
        // returns true; Gate::authorize() runs inside the controller,
        // after validation) — an invalid/empty body would 422 before
        // authorization is ever checked, which would test validation
        // ordering rather than the authorization rule itself.
        $plan = SubscriptionPlan::factory()->create();
        $this->actingAsPlatformAdmin();

        $this->getJson('/api/v1/subscription')->assertStatus(403);
        $this->getJson('/api/v1/subscription/plans')->assertStatus(403);
        $this->getJson('/api/v1/subscription/change-requests')->assertStatus(403);
        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => $plan->id, 'payment_reference' => 'REF-1'])->assertStatus(403);
        $this->getJson('/api/v1/subscription/storage')->assertStatus(403);
        $this->postJson('/api/v1/subscription/storage-addon-request', ['storage_package' => '10gb', 'payment_reference' => 'REF-1'])->assertStatus(403);
    }

    // --- GET /subscription ---

    public function test_show_returns_the_expected_response_structure(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $response = $this->getJson('/api/v1/subscription');

        $response->assertStatus(200)->assertJsonStructure([
            'success', 'message', 'errors',
            'data' => [
                'plan', 'plan_name', 'plan_price', 'trial_status' => ['on_trial', 'trial_ends_at'],
                'started_at', 'expires_at', 'subscription_status', 'customer_usage', 'customer_limit',
                'storage_usage_bytes', 'storage_limit', 'analytics_enabled', 'read_only',
            ],
        ]);
    }

    public function test_show_returns_the_active_subscriptions_plan_details(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business', 'monthly_price' => 5, 'customer_limit' => 110]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $response = $this->getJson('/api/v1/subscription');

        $response->assertJsonPath('data.plan_name', 'Small Business')
            ->assertJsonPath('data.customer_limit', 110)
            ->assertJsonPath('data.subscription_status', 'active')
            ->assertJsonPath('data.read_only', false);
    }

    public function test_show_reports_read_only_true_when_the_subscription_has_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        $this->getJson('/api/v1/subscription')->assertJsonPath('data.read_only', true);
    }

    public function test_show_falls_back_to_the_free_plan_when_the_tenant_has_no_subscription(): void
    {
        SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/subscription')
            ->assertJsonPath('data.plan_name', 'Free')
            ->assertJsonPath('data.customer_limit', 2)
            ->assertJsonPath('data.subscription_status', null);
    }

    public function test_show_reports_the_correct_customer_usage_count(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        Customer::factory()->for($tenant, 'tenant')->count(3)->create();
        $otherTenant = Tenant::create(['business_name' => 'Other Co']);
        Customer::factory()->for($otherTenant, 'tenant')->count(10)->create();

        $this->getJson('/api/v1/subscription')->assertJsonPath('data.customer_usage', 3);
    }

    // --- GET /subscription/plans ---

    public function test_plans_returns_only_active_plans_ordered_by_price(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));
        SubscriptionPlan::factory()->create(['name' => 'Corporate', 'monthly_price' => 20, 'active' => true]);
        SubscriptionPlan::factory()->create(['name' => 'Free', 'monthly_price' => 0, 'active' => true]);
        SubscriptionPlan::factory()->create(['name' => 'Retired Plan', 'monthly_price' => 1, 'active' => false]);

        $response = $this->getJson('/api/v1/subscription/plans');

        $response->assertStatus(200);
        $names = collect($response->json('data'))->pluck('name');
        $this->assertSame(['Free', 'Corporate'], $names->all());
    }

    public function test_plans_are_trial_eligible_when_the_tenant_has_no_subscription_record(): void
    {
        // Never started anything -> eligible.
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));
        SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);

        $response = $this->getJson('/api/v1/subscription/plans');

        $byName = collect($response->json('data'))->keyBy('name');
        $this->assertTrue($byName['Trial']['trial_eligible']);
        $this->assertTrue($byName['Free']['trial_eligible']);
    }

    public function test_plans_are_trial_eligible_when_the_tenants_subscription_never_had_a_trial(): void
    {
        // e.g. a subscription activated directly, without ever trialing.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();
        SubscriptionPlan::factory()->create(['name' => 'Corporate']);

        $byName = collect($this->getJson('/api/v1/subscription/plans')->json('data'))->keyBy('name');

        $this->assertTrue($byName['Corporate']['trial_eligible']);
    }

    public function test_plans_are_not_trial_eligible_once_the_tenant_has_started_a_trial_before(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active', 'trial_started_at' => now()->subDays(30),
        ]);
        SubscriptionPlan::factory()->create(['name' => 'Corporate']);

        $byName = collect($this->getJson('/api/v1/subscription/plans')->json('data'))->keyBy('name');

        // False for every plan, not just Trial — the value is tenant-
        // derived, identical across the whole list.
        $this->assertFalse($byName['Corporate']['trial_eligible']);
    }

    public function test_plans_return_an_empty_features_array_rather_than_invented_descriptions(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));
        SubscriptionPlan::factory()->create();

        $response = $this->getJson('/api/v1/subscription/plans');

        $this->assertSame([], $response->json('data.0.features'));
    }

    // --- GET /subscription/change-requests ---

    public function test_change_requests_returns_only_the_authenticated_tenants_own_requests(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantA->id]);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantB->id]);

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/subscription/change-requests');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data.change_requests'));
    }

    public function test_change_requests_response_structure_includes_pagination(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenant->id]);

        $response = $this->getJson('/api/v1/subscription/change-requests');

        $response->assertJsonStructure([
            'data' => [
                'change_requests' => [['id', 'requested_plan', 'status', 'requested_at']],
                'pagination' => ['current_page', 'per_page', 'total', 'last_page'],
            ],
        ]);
    }

    // --- POST /subscription/upgrade-request ---

    public function test_upgrade_request_creates_a_pending_change_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($currentPlan, 'plan')->active()->create();
        $targetPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);

        $response = $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $targetPlan->id,
            'payment_reference' => 'REF-123',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.payment_reference', 'REF-123')
            ->assertJsonPath('data.requested_plan.name', 'Small Business');

        $this->assertDatabaseHas('subscription_change_requests', [
            'tenant_id' => $tenant->id,
            'requested_plan_id' => $targetPlan->id,
            'current_plan_id' => $currentPlan->id,
            'status' => 'pending',
        ]);
    }

    public function test_upgrade_request_never_approves_or_activates(): void
    {
        // Explicit regression guard for this phase's core rule: creates a
        // request only, never a real plan change.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $targetPlan = SubscriptionPlan::factory()->create();

        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => $targetPlan->id, 'payment_reference' => 'REF-1'])
            ->assertStatus(201);

        $this->assertDatabaseMissing('tenant_subscriptions', ['tenant_id' => $tenant->id, 'plan_id' => $targetPlan->id]);
        $this->assertDatabaseHas('subscription_change_requests', ['tenant_id' => $tenant->id, 'status' => 'pending']);
    }

    public function test_upgrade_request_requires_a_requested_plan_id(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->postJson('/api/v1/subscription/upgrade-request', ['payment_reference' => 'REF-1'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['requested_plan_id']);
    }

    public function test_upgrade_request_requires_a_payment_reference(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));
        $plan = SubscriptionPlan::factory()->create();

        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => $plan->id])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['payment_reference']);
    }

    public function test_upgrade_request_rejects_a_nonexistent_plan_id(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => 'not-a-real-id', 'payment_reference' => 'REF-1'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['requested_plan_id']);
    }

    // --- GET /subscription/storage ---

    public function test_storage_returns_the_expected_response_structure(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create(['storage_limit' => 10]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $response = $this->getJson('/api/v1/subscription/storage');

        $response->assertStatus(200)->assertJsonStructure([
            'data' => ['storage_usage_bytes', 'storage_usage_gb', 'storage_limit_gb', 'purchased_addons', 'remaining_storage_gb'],
        ]);
    }

    public function test_storage_includes_only_the_authenticated_tenants_active_addons(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        StorageAddon::factory()->for($tenantA, 'tenant')->active()->create();
        StorageAddon::factory()->for($tenantB, 'tenant')->active()->create();

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/subscription/storage');

        $this->assertCount(1, $response->json('data.purchased_addons'));
    }

    public function test_storage_computes_remaining_storage_correctly(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create(['storage_limit' => 10]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $response = $this->getJson('/api/v1/subscription/storage');

        // json_encode() drops the trailing zero fraction for whole-number
        // floats (0.0 -> 0), so decoded JSON gives ints here, not floats.
        $response->assertJsonPath('data.storage_usage_gb', 0)
            ->assertJsonPath('data.storage_limit_gb', 10)
            ->assertJsonPath('data.remaining_storage_gb', 10);
    }

    // --- POST /subscription/storage-addon-request ---

    public function test_storage_addon_request_creates_a_pending_addon_with_server_derived_pricing(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '25gb',
            'payment_reference' => 'REF-1',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.storage_package', '25gb')
            ->assertJsonPath('data.storage_size', 25)
            ->assertJsonPath('data.monthly_price', '4.00')
            ->assertJsonPath('data.payment_reference', 'REF-1')
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('storage_addons', [
            'tenant_id' => $tenant->id, 'storage_package' => '25gb', 'storage_size' => 25,
            'payment_reference' => 'REF-1', 'status' => 'pending',
        ]);
    }

    public function test_storage_addon_request_ignores_a_client_supplied_price_and_uses_the_approved_value(): void
    {
        // Never trust client input for pricing — only storage_package
        // (and payment_reference) are read; any other field the client
        // sends is simply not a validated/consumed input.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '10gb',
            'payment_reference' => 'REF-1',
            'monthly_price' => 0.01,
            'storage_size' => 99999,
        ]);

        $response->assertJsonPath('data.storage_size', 10)->assertJsonPath('data.monthly_price', '2.00');
    }

    public function test_storage_addon_request_rejects_an_invalid_package(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->postJson('/api/v1/subscription/storage-addon-request', ['storage_package' => '1000gb', 'payment_reference' => 'REF-1'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['storage_package']);
    }

    public function test_storage_addon_request_requires_a_payment_reference(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->postJson('/api/v1/subscription/storage-addon-request', ['storage_package' => '10gb'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['payment_reference']);
    }

    public function test_storage_addon_request_requires_a_package(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->postJson('/api/v1/subscription/storage-addon-request', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['storage_package']);
    }
}
