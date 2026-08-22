<?php

namespace Tests\Feature;

use App\Enums\ReferenceDataCategory;
use App\Models\Customer;
use App\Models\PlatformPaymentSetting;
use App\Models\ReferenceData;
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
        $this->getJson('/api/v1/subscription/payment-info')->assertStatus(401);
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
        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-1'])->assertStatus(403);
        $this->getJson('/api/v1/subscription/payment-info')->assertStatus(403);
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

    public function test_show_reports_read_only_true_once_an_expired_subscription_has_actually_recalculated(): void
    {
        // Backend Completion Roadmap (Phase 4.5 — Final Verification
        // fix): `read_only` now reflects the real, persisted
        // is_read_only state (the same one every Policy checks), not a
        // second, parallel `status === 'expired'` check — so this
        // requires the customer to have actually gone through
        // CustomerReadOnlyService::recalculate() (via `subscriptions:expire`),
        // exactly like every other consumer of is_read_only.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/subscription')->assertJsonPath('data.read_only', true);
        $this->assertTrue($customer->fresh()->is_read_only);
    }

    public function test_show_reports_read_only_true_for_an_over_limit_tenant_even_while_the_subscription_is_active(): void
    {
        // The exact bug this fix closes: after a Trial expires to the
        // Free Plan (status becomes 'active', never 'expired'), a
        // tenant who had more customers than Free's limit is read-only
        // right now — the old `status === 'expired'` check would have
        // reported false here, since this subscription is not expired.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $trialPlan = SubscriptionPlan::factory()->unlimited()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);
        Customer::factory()->for($tenant, 'tenant')->count(3)->create();
        $this->artisan('subscriptions:expire-trials');
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/subscription')
            ->assertJsonPath('data.subscription_status', 'active')
            ->assertJsonPath('data.read_only', true);
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

    // --- GET /subscription/payment-info ---

    public function test_payment_info_returns_the_destination_number_set_by_the_platform_administrator(): void
    {
        PlatformPaymentSetting::create(['destination_mobile_money_number' => '61XXXXXXX']);
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->getJson('/api/v1/subscription/payment-info')
            ->assertStatus(200)
            ->assertJsonPath('data.destination_mobile_money_number', '61XXXXXXX');
    }

    public function test_payment_info_returns_null_when_no_destination_number_has_been_set(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->getJson('/api/v1/subscription/payment-info')
            ->assertStatus(200)
            ->assertJsonPath('data.destination_mobile_money_number', null);
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
            'payment_phone' => '+252611234567',
            'payment_reference' => 'REF-123',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.payment_phone', '+252611234567')
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

        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => $targetPlan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-1'])
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

    public function test_upgrade_request_requires_a_payment_phone(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));
        $plan = SubscriptionPlan::factory()->create();

        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => $plan->id, 'payment_reference' => 'REF-1'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['payment_phone']);
    }

    public function test_upgrade_request_does_not_require_a_payment_reference(): void
    {
        // Manual Mobile-Money Subscription Payment Flow (Product Owner
        // decision): the approved UX flow lets a Business Owner submit
        // before the external mobile-money transaction reference is
        // known, so payment_reference must remain optional.
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));
        $plan = SubscriptionPlan::factory()->create();

        $response = $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567',
        ]);

        $response->assertStatus(201)->assertJsonPath('data.payment_reference', null);
    }

    public function test_upgrade_request_rejects_a_nonexistent_plan_id(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->postJson('/api/v1/subscription/upgrade-request', ['requested_plan_id' => 'not-a-real-id', 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-1'])
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

    // --- Phase 3.4: duplicate pending request prevention ---

    public function test_upgrade_request_rejects_a_duplicate_pending_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $response = $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-2',
        ]);

        $response->assertStatus(409)->assertJson(['success' => false]);
        $this->assertSame(1, SubscriptionChangeRequest::where('tenant_id', $tenant->id)->count());
    }

    public function test_upgrade_request_duplicate_check_is_tenant_isolated(): void
    {
        // Another tenant's pending request must never block this one.
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenantB->id, 'status' => 'pending',
        ]);

        $this->actingAsTenantUser($tenantA);
        $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-1',
        ])->assertStatus(201);
    }

    // Product Owner confirmation: ONLY status='pending' blocks a new
    // request. Approved and rejected requests never block — both
    // terminal states are exercised explicitly below, for both flows,
    // rather than assuming rejected behaves like approved.

    public function test_upgrade_request_allows_a_new_request_once_the_prior_one_was_approved(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'approved',
        ]);

        $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-2',
        ])->assertStatus(201);
    }

    public function test_upgrade_request_allows_a_new_request_once_the_prior_one_was_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'rejected',
        ]);

        $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-2',
        ])->assertStatus(201);
    }

    public function test_storage_addon_request_rejects_a_duplicate_pending_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending']);

        $response = $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '25gb', 'payment_reference' => 'REF-2',
        ]);

        $response->assertStatus(409)->assertJson(['success' => false]);
        $this->assertSame(1, StorageAddon::where('tenant_id', $tenant->id)->count());
    }

    public function test_storage_addon_request_allows_a_new_request_once_the_prior_one_was_approved(): void
    {
        // 'approved' was never a valid storage_addons.status value (the
        // CHECK constraint only allows pending/active/expired/rejected/
        // cancelled) — this test only ever passed under SQLite's
        // non-enforcement of CHECK constraints, a pre-existing bug fixed
        // here as part of building the real approve/reject/cancel
        // workflow. 'active' is the real terminal state a Storage Add-on
        // request reaches once accepted (StorageAddonService::approve()).
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'active']);

        $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '10gb', 'payment_reference' => 'REF-2',
        ])->assertStatus(201);
    }

    public function test_storage_addon_request_allows_a_new_request_once_the_prior_one_was_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'rejected']);

        $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '10gb', 'payment_reference' => 'REF-2',
        ])->assertStatus(201);
    }

    public function test_storage_addon_request_duplicate_check_is_tenant_isolated(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        StorageAddon::factory()->create(['tenant_id' => $tenantB->id, 'status' => 'pending']);

        $this->actingAsTenantUser($tenantA);
        $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '10gb', 'payment_reference' => 'REF-1',
        ])->assertStatus(201);
    }

    // --- Phase 3.4: audit trail ---

    public function test_upgrade_request_records_an_audit_log_entry_with_sufficient_metadata(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();

        $response = $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-1',
        ]);

        $changeRequestId = $response->json('data.id');
        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => $user->id,
            'action' => 'subscription_upgrade_requested',
            'entity_type' => 'subscription_change_request',
            'entity_id' => $changeRequestId,
            'reason' => "requested_plan_id={$plan->id}; payment_phone=+252611234567; payment_reference=REF-1",
        ]);
    }

    public function test_storage_addon_request_records_an_audit_log_entry_with_sufficient_metadata(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '10gb', 'payment_reference' => 'REF-1',
        ]);

        $addonId = $response->json('data.id');
        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => $user->id,
            'action' => 'storage_addon_requested',
            'entity_type' => 'storage_addon',
            'entity_id' => $addonId,
            'reason' => 'storage_package=10gb; payment_reference=REF-1',
        ]);
    }

    // --- Subscription Approval + Storage Add-on Approval (Product
    // Owner-approved decision record): Decision 24 same-plan guard ---

    public function test_upgrade_request_rejects_a_request_for_the_tenants_current_plan(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $plan->id, 'payment_phone' => '+252611234567', 'payment_reference' => 'REF-1',
        ])->assertStatus(409)->assertJson(['success' => false]);
    }

    // --- Business Owner cancels their own pending request ---

    private function seedRejectionReason(ReferenceDataCategory $category, string $label = 'Payment Not Verified'): void
    {
        ReferenceData::create([
            'tenant_id' => null,
            'category' => $category->value,
            'value_label' => $label,
            'is_active' => true,
        ]);
    }

    public function test_business_owner_can_cancel_their_own_pending_change_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $response = $this->postJson("/api/v1/subscription/change-requests/{$changeRequest->id}/cancel");

        $response->assertStatus(200)->assertJsonPath('data.status', 'cancelled');
        $this->assertDatabaseHas('subscription_change_requests', ['id' => $changeRequest->id, 'status' => 'cancelled']);
    }

    public function test_business_owner_cannot_cancel_another_tenants_change_request(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenantB->id, 'status' => 'pending',
        ]);

        $this->actingAsTenantUser($tenantA);
        $this->postJson("/api/v1/subscription/change-requests/{$changeRequest->id}/cancel")->assertStatus(404);
    }

    public function test_cancelling_a_non_pending_change_request_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'approved',
        ]);

        $this->postJson("/api/v1/subscription/change-requests/{$changeRequest->id}/cancel")
            ->assertStatus(409)->assertJson(['success' => false]);
    }

    public function test_business_owner_can_cancel_their_own_pending_storage_addon_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $addon = StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending']);

        $response = $this->postJson("/api/v1/subscription/storage-addon-requests/{$addon->id}/cancel");

        $response->assertStatus(200)->assertJsonPath('data.status', 'cancelled');
    }

    // --- Platform Admin Approval Center ---

    public function test_business_owner_is_forbidden_from_the_approval_center_endpoints(): void
    {
        $this->actingAsTenantUser(Tenant::create(['business_name' => 'Acme Co']));

        $this->getJson('/api/v1/admin/subscription/change-requests')->assertStatus(403);
        $this->getJson('/api/v1/admin/subscription/rejection-reasons')->assertStatus(403);
        $this->getJson('/api/v1/admin/storage-addons')->assertStatus(403);
        $this->getJson('/api/v1/admin/storage-addons/rejection-reasons')->assertStatus(403);
    }

    public function test_approval_center_lists_change_requests_across_every_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantA->id, 'status' => 'pending']);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantB->id, 'status' => 'pending']);

        $this->actingAsPlatformAdmin();
        $response = $this->getJson('/api/v1/admin/subscription/change-requests');

        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data.change_requests'));
    }

    public function test_approval_center_filters_change_requests_by_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenant->id, 'status' => 'pending']);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenant->id, 'status' => 'rejected']);

        $this->actingAsPlatformAdmin();
        $response = $this->getJson('/api/v1/admin/subscription/change-requests?status=pending');

        $this->assertCount(1, $response->json('data.change_requests'));
    }

    public function test_change_request_rejection_reasons_returns_the_predefined_platform_owned_values(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::SubscriptionRejectionReason, 'Payment Not Verified');
        $this->actingAsPlatformAdmin();

        $response = $this->getJson('/api/v1/admin/subscription/rejection-reasons');

        $response->assertStatus(200);
        $this->assertContains('Payment Not Verified', collect($response->json('data'))->pluck('value_label'));
    }

    // --- Approve ---

    public function test_platform_admin_can_approve_a_pending_change_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($currentPlan, 'plan')->active()->create();
        $targetPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business', 'customer_limit' => 110]);
        $changeRequest = SubscriptionChangeRequest::factory()->for($targetPlan, 'requestedPlan')->for($currentPlan, 'currentPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve");

        $response->assertStatus(200)->assertJsonPath('data.status', 'approved');
        $this->assertDatabaseHas('tenant_subscriptions', [
            'tenant_id' => $tenant->id, 'plan_id' => $targetPlan->id, 'status' => 'active',
        ]);
    }

    public function test_approving_a_paid_plan_sets_a_one_month_expiry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $targetPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        $changeRequest = SubscriptionChangeRequest::factory()->for($targetPlan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve")->assertStatus(200);

        $subscription = TenantSubscription::where('tenant_id', $tenant->id)->first();
        $this->assertNotNull($subscription->expires_at);
        $this->assertEqualsWithDelta(now()->addMonth()->timestamp, $subscription->expires_at->timestamp, 5);
    }

    public function test_approving_the_free_plan_leaves_no_expiry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($currentPlan, 'plan')->active()->create();
        $freePlan = SubscriptionPlan::factory()->create(['name' => 'Free']);
        $changeRequest = SubscriptionChangeRequest::factory()->for($freePlan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve")->assertStatus(200);

        $this->assertNull(TenantSubscription::where('tenant_id', $tenant->id)->first()->expires_at);
    }

    public function test_approving_a_change_request_recalculates_customer_read_only_status(): void
    {
        // Orchestration check: approving a downgrade to a stricter limit
        // must immediately flip over-limit customers to read-only —
        // CustomerReadOnlyService::recalculate() is triggered by the
        // controller after SubscriptionService::approve() returns.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business', 'customer_limit' => 110]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($currentPlan, 'plan')->active()->create();
        $freePlan = SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        Customer::factory()->for($tenant, 'tenant')->count(3)->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($freePlan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve")->assertStatus(200);

        // withoutGlobalScope('tenant'): the test process is still
        // Sanctum::actingAs() the Platform Administrator (tenant_id NULL)
        // here — Customer's own BelongsToTenant scope would otherwise
        // apply `WHERE tenant_id IS NULL` on top of this query's explicit
        // filter and always match zero rows, the exact bug this test
        // exists to catch in CustomerReadOnlyService itself (now fixed
        // there via the same scope bypass).
        $this->assertSame(1, Customer::withoutGlobalScope('tenant')->where('tenant_id', $tenant->id)->where('is_read_only', true)->count());
    }

    public function test_approving_an_already_reviewed_change_request_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'approved',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve")
            ->assertStatus(409)->assertJson(['success' => false]);
    }

    public function test_approving_a_request_for_the_tenants_now_current_plan_is_rejected(): void
    {
        // Decision 26 — approval-time safety net: the tenant's plan
        // changed (e.g. via a separately approved request) between
        // submission and review, so the requested plan now equals the
        // tenant's real current plan.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve")
            ->assertStatus(409)->assertJson(['success' => false]);
    }

    public function test_approving_a_change_request_records_an_audit_log_entry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);
        $admin = $this->actingAsPlatformAdmin();

        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve")->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => $admin->id,
            'action' => 'subscription_change_request_status_changed',
            'entity_type' => 'subscription_change_request',
            'entity_id' => $changeRequest->id,
        ]);
    }

    public function test_approving_a_change_request_notifies_the_business_owner(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $owner = $this->actingAsTenantUser($tenant);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/approve")->assertStatus(200);

        $this->assertDatabaseHas('notifications', [
            'tenant_id' => $tenant->id,
            'recipient_user_id' => $owner->id,
            'type' => 'subscription_request_update',
            'related_entity_type' => 'subscription_change_request',
            'related_entity_id' => $changeRequest->id,
        ]);
    }

    // --- Reject ---

    public function test_platform_admin_can_reject_a_pending_change_request_with_predefined_reasons(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::SubscriptionRejectionReason, 'Payment Not Verified');
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/reject", [
            'reasons' => ['Payment Not Verified'],
            'notes' => 'Bank reference could not be verified.',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'rejected')
            ->assertJsonPath('data.rejection_reason', 'Bank reference could not be verified.')
            ->assertJsonPath('data.rejection_reasons', ['Payment Not Verified']);
        $this->assertDatabaseHas('subscription_change_request_rejection_reasons', [
            'subscription_change_request_id' => $changeRequest->id, 'reason_label' => 'Payment Not Verified',
        ]);
    }

    public function test_rejecting_a_change_request_requires_at_least_one_predefined_reason(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/reject", [])
            ->assertStatus(422)->assertJsonValidationErrors(['reasons']);
    }

    public function test_rejecting_a_change_request_rejects_a_reason_not_in_the_predefined_list(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/reject", [
            'reasons' => ['Made Up Reason'],
        ])->assertStatus(422)->assertJsonValidationErrors(['reasons.0']);
    }

    public function test_rejecting_a_change_request_does_not_change_the_tenants_subscription(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::SubscriptionRejectionReason);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($currentPlan, 'plan')->active()->create();
        $targetPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        $changeRequest = SubscriptionChangeRequest::factory()->for($targetPlan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/subscription/change-requests/{$changeRequest->id}/reject", [
            'reasons' => ['Payment Not Verified'],
        ])->assertStatus(200);

        $this->assertDatabaseHas('tenant_subscriptions', ['tenant_id' => $tenant->id, 'plan_id' => $currentPlan->id]);
    }

    // --- Storage Add-on Approval Center ---

    public function test_storage_addon_approval_center_lists_requests_across_every_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        StorageAddon::factory()->create(['tenant_id' => $tenantA->id, 'status' => 'pending']);
        StorageAddon::factory()->create(['tenant_id' => $tenantB->id, 'status' => 'pending']);

        $this->actingAsPlatformAdmin();
        $response = $this->getJson('/api/v1/admin/storage-addons');

        $this->assertCount(2, $response->json('data.storage_addon_requests'));
    }

    public function test_storage_addon_rejection_reasons_returns_the_predefined_platform_owned_values(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::StorageRejectionReason, 'Duplicate Request');
        $this->actingAsPlatformAdmin();

        $response = $this->getJson('/api/v1/admin/storage-addons/rejection-reasons');

        $this->assertContains('Duplicate Request', collect($response->json('data'))->pluck('value_label'));
    }

    // --- Storage Add-on Approve ---

    public function test_platform_admin_can_approve_a_pending_storage_addon_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $addon = StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending', 'storage_size' => 25]);

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/admin/storage-addons/{$addon->id}/approve");

        $response->assertStatus(200)->assertJsonPath('data.status', 'active');
        $addon->refresh();
        $this->assertNotNull($addon->started_at);
        $this->assertEqualsWithDelta(now()->addMonth()->timestamp, $addon->expires_at->timestamp, 5);
    }

    public function test_approving_a_storage_addon_increases_the_tenants_total_allowance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $plan = SubscriptionPlan::factory()->create(['storage_limit' => 10]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();
        $addon = StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending', 'storage_package' => '25gb', 'storage_size' => 25]);
        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/storage-addons/{$addon->id}/approve")->assertStatus(200);

        $this->actingAsTenantUser($tenant);
        $this->getJson('/api/v1/subscription/storage')->assertJsonPath('data.storage_limit_gb', 35);
    }

    public function test_approving_an_already_reviewed_storage_addon_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $addon = StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'active']);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/storage-addons/{$addon->id}/approve")
            ->assertStatus(409)->assertJson(['success' => false]);
    }

    // --- Storage Add-on Reject ---

    public function test_platform_admin_can_reject_a_pending_storage_addon_request_with_predefined_reasons(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::StorageRejectionReason, 'Insufficient Payment Amount');
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $addon = StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending']);

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/admin/storage-addons/{$addon->id}/reject", [
            'reasons' => ['Insufficient Payment Amount'],
        ]);

        $response->assertStatus(200)->assertJsonPath('data.status', 'rejected');
        $this->assertDatabaseHas('storage_addon_rejection_reasons', [
            'storage_addon_id' => $addon->id, 'reason_label' => 'Insufficient Payment Amount',
        ]);
    }

    public function test_rejecting_a_storage_addon_requires_at_least_one_predefined_reason(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $addon = StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending']);

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/admin/storage-addons/{$addon->id}/reject", [])
            ->assertStatus(422)->assertJsonValidationErrors(['reasons']);
    }
}
