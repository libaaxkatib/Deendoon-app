<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 4.4 — Feature & Read-Only Enforcement.
 * End-to-end coverage of: (1) analytics_enabled feature gating on the
 * Reporting module + Business Health, and confirmation that unrelated
 * endpoints (Dashboard KPIs, Documents, Calendar) remain unrestricted;
 * (2) expired-subscription read-only, reusing the exact Phase 4.1
 * CustomerReadOnlyService/is_read_only mechanism.
 */
class FeatureAndReadOnlyEnforcementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function actingAsTenantUser(Tenant $tenant, ?string $role = 'admin'): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        if ($role !== null) {
            $user->assignRole($role);
        }

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    private function subscribe(Tenant $tenant, array $planAttributes = []): SubscriptionPlan
    {
        $plan = SubscriptionPlan::factory()->create($planAttributes);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        return $plan;
    }

    private function subscribeExpired(Tenant $tenant, array $planAttributes = []): SubscriptionPlan
    {
        $plan = SubscriptionPlan::factory()->create($planAttributes);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        return $plan;
    }

    /**
     * Unlike subscribeExpired() (already status 'expired', for testing
     * effectiveCustomerLimit()/CustomerPolicy::create() directly), this
     * creates a subscription still 'active' with a past expires_at — the
     * exact state ExpireSubscriptions::expireSubscriptions() queries for
     * and transitions. Needed for tests that assert the is_read_only
     * cascade, since that only fires via CustomerReadOnlyService::recalculate(),
     * itself only triggered by the actual active->expired transition.
     */
    private function subscribeExpiring(Tenant $tenant, array $planAttributes = []): SubscriptionPlan
    {
        $plan = SubscriptionPlan::factory()->create($planAttributes);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        return $plan;
    }

    private function makeDebt(Tenant $tenant): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
    }

    // --- Feature Enforcement: Reporting module gated by analytics_enabled ---

    public function test_reports_are_blocked_when_the_plan_excludes_analytics(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, ['analytics_enabled' => false]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/customers')->assertStatus(403);
        $this->getJson('/api/v1/reports/collection-analytics')->assertStatus(403);
        $this->getJson('/api/v1/reports/customers/export?format=csv')->assertStatus(403);
    }

    public function test_reports_are_allowed_when_the_plan_includes_analytics(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, ['analytics_enabled' => true]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/customers')->assertStatus(200);
        $this->getJson('/api/v1/reports/collection-analytics')->assertStatus(200);
    }

    public function test_reports_are_blocked_when_no_plan_can_be_resolved_at_all(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/customers')->assertStatus(403);
    }

    // --- Feature Enforcement: unrelated endpoints must stay unrestricted ---
    // (Product Owner clarification, 2026-08-06: "Business Health must
    // remain available for all subscription plans, including the Free
    // Plan. Do NOT gate Business Health behind analytics_enabled...
    // Dashboard KPIs, Today's Overview, Recent Cases, and Business Health
    // must all remain available regardless of subscription plan." An
    // earlier draft of this phase briefly gated Business Health behind
    // analytics_enabled; reverted — asserted explicitly here so it can
    // never silently regress back.)

    public function test_dashboard_endpoints_including_business_health_remain_accessible_without_analytics(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, ['analytics_enabled' => false]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/dashboard/kpis')->assertStatus(200);
        $this->getJson('/api/v1/dashboard/todays-overview')->assertStatus(200);
        $this->getJson('/api/v1/dashboard/recent-cases')->assertStatus(200);
        $this->getJson('/api/v1/dashboard/business-health')->assertStatus(200);
    }

    public function test_dashboard_endpoints_including_business_health_remain_accessible_with_no_resolvable_plan(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/dashboard/kpis')->assertStatus(200);
        $this->getJson('/api/v1/dashboard/business-health')->assertStatus(200);
    }

    public function test_documents_and_calendar_remain_accessible_without_analytics(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, ['analytics_enabled' => false]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/documents')->assertStatus(200);
        $this->getJson('/api/v1/documents/storage-usage')->assertStatus(200);
        $this->getJson('/api/v1/calendar')->assertStatus(200);
    }

    // --- Read-Only Enforcement: expired subscription blocks writes ---

    public function test_creating_a_customer_is_blocked_when_the_subscription_is_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribeExpired($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
            'credit_limit' => 1000,
        ]);

        $response->assertStatus(403);
        $this->assertSame(0, Customer::count());
    }

    public function test_reading_customers_still_works_when_the_subscription_is_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->subscribeExpired($tenant);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/customers')->assertStatus(200);
        $this->getJson("/api/v1/customers/{$customer->id}")->assertStatus(200);
    }

    public function test_existing_customers_become_read_only_once_the_expire_command_runs(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->subscribeExpiring($tenant);

        $this->artisan('subscriptions:expire')->assertExitCode(0);

        $this->assertTrue($customer->fresh()->is_read_only);
    }

    public function test_editing_a_customer_is_blocked_after_the_subscription_expires_and_recalculates(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Old Name']);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $response = $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'New Name',
            'phone' => $customer->phone,
            'credit_limit' => $customer->credit_limit,
        ]);

        $response->assertStatus(403);
        $this->assertSame('Old Name', $customer->fresh()->name);
    }

    public function test_debt_write_operations_are_blocked_after_the_subscription_expires_and_recalculates(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->putJson("/api/v1/debts/{$debt->id}", [
            'due_date' => now()->addDays(30)->toDateString(),
        ])->assertStatus(403);
    }

    public function test_document_generation_is_blocked_after_the_subscription_expires_and_recalculates(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(403);
    }

    public function test_collection_case_activity_is_blocked_after_the_subscription_expires_and_recalculates(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/collection-cases/{$case->id}/activities", [
            'details' => 'Called the customer',
        ])->assertStatus(403);
    }

    // --- Read-Only Enforcement: administrative/subscription actions remain available ---
    // (Product Owner clarification, 2026-08-06: "When a subscription is
    // expired, the Business Owner must still be able to: Update Company
    // Profile, Update Company Logo, Update System Settings, Submit
    // Subscription Upgrade Requests, Submit Storage Add-on Requests.
    // Business data write operations remain blocked exactly as approved
    // in Phase 4.1. Do not expand the protected scope." None of these 5
    // actions were ever gated by is_read_only/effectiveCustomerLimit() —
    // asserted explicitly here as a confirmed, tested guarantee rather
    // than an untested assumption.)

    public function test_updating_the_company_profile_is_allowed_when_the_subscription_is_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->putJson('/api/v1/admin/settings/company-profile', [
            'business_name' => 'Acme Trading Co',
        ])->assertStatus(200);
    }

    public function test_updating_the_company_logo_is_allowed_when_the_subscription_is_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        Storage::fake('local');

        $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Co',
            'logo' => UploadedFile::fake()->image('logo.png'),
        ])->assertStatus(200);
    }

    public function test_updating_system_settings_is_allowed_when_the_subscription_is_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->putJson('/api/v1/admin/settings/preferences', [
            'default_credit_limit' => 5000,
            'credit_limit_reminder_enabled' => true,
        ])->assertStatus(200);
    }

    public function test_submitting_a_subscription_upgrade_request_is_allowed_when_the_subscription_is_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);
        $targetPlan = SubscriptionPlan::factory()->create();

        $this->postJson('/api/v1/subscription/upgrade-request', [
            'requested_plan_id' => $targetPlan->id,
            'payment_reference' => 'REF-12345',
        ])->assertStatus(201);
    }

    public function test_submitting_a_storage_addon_request_is_allowed_when_the_subscription_is_expired(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribeExpiring($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/subscription/storage-addon-request', [
            'storage_package' => '25gb',
            'payment_reference' => 'REF-67890',
        ])->assertStatus(201);
    }

    // --- Read-Only Enforcement: unaffected states ---

    public function test_customers_remain_editable_while_the_subscription_is_active(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->subscribe($tenant);
        $this->artisan('subscriptions:expire');
        $this->actingAsTenantUser($tenant);

        $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'Still Editable',
            'phone' => $customer->phone,
            'credit_limit' => $customer->credit_limit,
        ])->assertStatus(200);
    }

    public function test_customers_remain_editable_during_the_trial(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $trialPlan = SubscriptionPlan::factory()->unlimited()->create(['name' => 'Trial']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->addDays(7),
        ]);
        $this->actingAsTenantUser($tenant);

        $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'Still Editable',
            'phone' => $customer->phone,
            'credit_limit' => $customer->credit_limit,
        ])->assertStatus(200);
    }

    // --- Tenant isolation ---

    public function test_one_tenants_expired_subscription_does_not_affect_another_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $customerA = Customer::factory()->for($tenantA, 'tenant')->create();
        $customerB = Customer::factory()->for($tenantB, 'tenant')->create();
        $this->subscribeExpiring($tenantA);
        $this->subscribe($tenantB);

        $this->artisan('subscriptions:expire');

        $this->assertTrue($customerA->fresh()->is_read_only);
        $this->assertFalse($customerB->fresh()->is_read_only);
    }
}
