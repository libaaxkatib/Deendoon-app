<?php

namespace Tests\Feature\Admin;

use App\Enums\ReferenceDataCategory;
use App\Models\ReferenceData;
use App\Models\StorageAddon;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminSubscriptionManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function platformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        return $admin;
    }

    private function businessOwner(Tenant $tenant): User
    {
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        return $owner;
    }

    private function seedRejectionReason(ReferenceDataCategory $category, string $label = 'Payment Not Verified'): void
    {
        ReferenceData::create([
            'tenant_id' => null,
            'category' => $category->value,
            'value_label' => $label,
            'is_active' => true,
        ]);
    }

    public function test_platform_administrator_can_view_subscriptions_across_tenants(): void
    {
        $tenantA = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $tenantB = Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        TenantSubscription::factory()->for($tenantA, 'tenant')->for($plan, 'plan')->active()->create();
        TenantSubscription::factory()->for($tenantB, 'tenant')->for($plan, 'plan')->active()->create();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/subscriptions');

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
        $response->assertSee('Small Business');
    }

    public function test_a_business_owner_is_forbidden_from_subscriptions(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->businessOwner($tenant);

        $this->actingAs($owner)->get('/admin/subscriptions')->assertForbidden();
    }

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $response = $this->get('/admin/subscriptions');

        $response->assertRedirect(route('admin.login'));
    }

    public function test_current_subscription_renders_correctly(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $plan = SubscriptionPlan::factory()->create(['name' => 'Medium Business', 'monthly_price' => 25]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $response = $this->actingAs($this->platformAdmin())->get("/admin/subscriptions/{$tenant->id}");

        $response->assertOk();
        $response->assertSee('Medium Business');
        $response->assertSee('25.00');
        $response->assertSee('Active');
    }

    public function test_subscription_change_request_history_renders(): void
    {
        $tenant = Tenant::factory()->create();
        $plan = SubscriptionPlan::factory()->create(['name' => 'Corporate']);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'approved',
        ]);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/subscriptions/{$tenant->id}");

        $response->assertOk();
        $response->assertSee('Corporate');
        $response->assertSee('Approved');
    }

    public function test_storage_addon_history_renders(): void
    {
        $tenant = Tenant::factory()->create();
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_package' => '25gb', 'storage_size' => 25]);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/subscriptions/{$tenant->id}");

        $response->assertOk();
        $response->assertSee('25GB');
        $response->assertSee('25 GB');
    }

    public function test_pending_change_request_shows_approve_reject_actions(): void
    {
        $tenant = Tenant::factory()->create();
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/subscriptions/{$tenant->id}");

        $response->assertOk();
        $response->assertSee('Pending Plan Change');
        $response->assertSee('Confirm Approve');
        $response->assertSee('Confirm Reject');
    }

    public function test_approve_applies_the_requested_subscription_change_immediately(): void
    {
        $tenant = Tenant::factory()->create();
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($currentPlan, 'plan')->active()->create();
        $targetPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business', 'customer_limit' => 110]);
        $changeRequest = SubscriptionChangeRequest::factory()->for($targetPlan, 'requestedPlan')->for($currentPlan, 'currentPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.subscriptions.change-requests.approve', $changeRequest));

        $response->assertRedirect(route('admin.subscriptions.show', $tenant));
        $this->assertSame('approved', $changeRequest->fresh()->status);
        $subscription = TenantSubscription::where('tenant_id', $tenant->id)->first();
        $this->assertSame($targetPlan->id, $subscription->plan_id);
        $this->assertSame('active', $subscription->status);
    }

    public function test_approve_updates_existing_subscription_row_not_duplicate(): void
    {
        $tenant = Tenant::factory()->create();
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($currentPlan, 'plan')->active()->create();
        $targetPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        $changeRequest = SubscriptionChangeRequest::factory()->for($targetPlan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAs($this->platformAdmin())
            ->post(route('admin.subscriptions.change-requests.approve', $changeRequest));

        $this->assertSame(1, TenantSubscription::where('tenant_id', $tenant->id)->count());
    }

    public function test_approve_creates_an_audit_log(): void
    {
        $tenant = Tenant::factory()->create();
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post(route('admin.subscriptions.change-requests.approve', $changeRequest));

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => $admin->id,
            'action' => 'subscription_change_request_status_changed',
            'entity_type' => 'subscription_change_request',
            'entity_id' => $changeRequest->id,
        ]);
    }

    public function test_approve_sends_business_owner_notification(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->businessOwner($tenant);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAs($this->platformAdmin())
            ->post(route('admin.subscriptions.change-requests.approve', $changeRequest));

        $this->assertDatabaseHas('notifications', [
            'tenant_id' => $tenant->id,
            'recipient_user_id' => $owner->id,
            'type' => 'subscription_request_update',
            'related_entity_type' => 'subscription_change_request',
            'related_entity_id' => $changeRequest->id,
        ]);
    }

    public function test_reject_requires_a_rejection_reason(): void
    {
        $tenant = Tenant::factory()->create();
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.subscriptions.change-requests.reject', $changeRequest), []);

        $response->assertSessionHasErrors('reasons');
        $this->assertSame('pending', $changeRequest->fresh()->status);
    }

    public function test_reject_accepts_optional_comment(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::SubscriptionRejectionReason);
        $tenant = Tenant::factory()->create();
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.subscriptions.change-requests.reject', $changeRequest), [
                'reasons' => ['Payment Not Verified'],
                'notes' => 'Bank reference could not be verified.',
            ]);

        $response->assertRedirect(route('admin.subscriptions.show', $tenant));
        $changeRequest->refresh();
        $this->assertSame('rejected', $changeRequest->status);
        $this->assertSame('Bank reference could not be verified.', $changeRequest->rejection_reason);
        $this->assertDatabaseHas('subscription_change_request_rejection_reasons', [
            'subscription_change_request_id' => $changeRequest->id,
            'reason_label' => 'Payment Not Verified',
        ]);
    }

    public function test_reject_creates_an_audit_log(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::SubscriptionRejectionReason);
        $tenant = Tenant::factory()->create();
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post(route('admin.subscriptions.change-requests.reject', $changeRequest), [
            'reasons' => ['Payment Not Verified'],
        ]);

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => $admin->id,
            'action' => 'subscription_change_request_status_changed',
            'entity_type' => 'subscription_change_request',
            'entity_id' => $changeRequest->id,
        ]);
    }

    public function test_reject_sends_business_owner_notification(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::SubscriptionRejectionReason);
        $tenant = Tenant::factory()->create();
        $owner = $this->businessOwner($tenant);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);

        $this->actingAs($this->platformAdmin())->post(route('admin.subscriptions.change-requests.reject', $changeRequest), [
            'reasons' => ['Payment Not Verified'],
        ]);

        $this->assertDatabaseHas('notifications', [
            'tenant_id' => $tenant->id,
            'recipient_user_id' => $owner->id,
            'type' => 'subscription_request_update',
            'related_entity_type' => 'subscription_change_request',
            'related_entity_id' => $changeRequest->id,
        ]);
    }

    public function test_storage_addon_approval_works_through_existing_service(): void
    {
        $tenant = Tenant::factory()->create();
        $addon = StorageAddon::factory()->for($tenant, 'tenant')->create(['storage_package' => '50gb', 'storage_size' => 50, 'status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.subscriptions.storage-addons.approve', $addon));

        $response->assertRedirect(route('admin.subscriptions.show', $tenant));
        $addon->refresh();
        $this->assertSame('active', $addon->status);
        $this->assertNotNull($addon->started_at);
        $this->assertNotNull($addon->expires_at);
    }

    public function test_storage_addon_rejection_stores_reason_and_comment(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::StorageRejectionReason);
        $tenant = Tenant::factory()->create();
        $addon = StorageAddon::factory()->for($tenant, 'tenant')->create(['status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.subscriptions.storage-addons.reject', $addon), [
                'reasons' => ['Payment Not Verified'],
                'notes' => 'Reference number did not match.',
            ]);

        $response->assertRedirect(route('admin.subscriptions.show', $tenant));
        $addon->refresh();
        $this->assertSame('rejected', $addon->status);
        $this->assertSame('Reference number did not match.', $addon->rejection_reason);
        $this->assertDatabaseHas('storage_addon_rejection_reasons', [
            'storage_addon_id' => $addon->id,
            'reason_label' => 'Payment Not Verified',
        ]);
    }

    public function test_storage_addon_approve_and_reject_create_audit_logs_and_notifications(): void
    {
        $this->seedRejectionReason(ReferenceDataCategory::StorageRejectionReason);
        $tenant = Tenant::factory()->create();
        $owner = $this->businessOwner($tenant);
        $addonToApprove = StorageAddon::factory()->for($tenant, 'tenant')->create(['status' => 'pending']);
        $addonToReject = StorageAddon::factory()->for($tenant, 'tenant')->create(['status' => 'pending']);
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post(route('admin.subscriptions.storage-addons.approve', $addonToApprove));
        $this->actingAs($admin)->post(route('admin.subscriptions.storage-addons.reject', $addonToReject), [
            'reasons' => ['Payment Not Verified'],
        ]);

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id, 'user_id' => $admin->id,
            'action' => 'storage_addon_status_changed', 'entity_type' => 'storage_addon', 'entity_id' => $addonToApprove->id,
        ]);
        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id, 'user_id' => $admin->id,
            'action' => 'storage_addon_status_changed', 'entity_type' => 'storage_addon', 'entity_id' => $addonToReject->id,
        ]);
        $this->assertDatabaseHas('notifications', [
            'tenant_id' => $tenant->id, 'recipient_user_id' => $owner->id,
            'type' => 'storage_request_update', 'related_entity_type' => 'storage_addon', 'related_entity_id' => $addonToApprove->id,
        ]);
        $this->assertDatabaseHas('notifications', [
            'tenant_id' => $tenant->id, 'recipient_user_id' => $owner->id,
            'type' => 'storage_request_update', 'related_entity_type' => 'storage_addon', 'related_entity_id' => $addonToReject->id,
        ]);
    }

    public function test_confirmation_gated_actions_are_protected_from_business_owners(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->businessOwner($tenant);
        $plan = SubscriptionPlan::factory()->create();
        $changeRequest = SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create([
            'tenant_id' => $tenant->id, 'status' => 'pending',
        ]);
        $addon = StorageAddon::factory()->for($tenant, 'tenant')->create(['status' => 'pending']);

        $this->actingAs($owner)->post(route('admin.subscriptions.change-requests.approve', $changeRequest))->assertForbidden();
        $this->actingAs($owner)->post(route('admin.subscriptions.storage-addons.approve', $addon))->assertForbidden();
        $this->assertSame('pending', $changeRequest->fresh()->status);
        $this->assertSame('pending', $addon->fresh()->status);
    }

    public function test_tenant_isolation_cross_tenant_platform_admin_visibility_works_correctly(): void
    {
        // The Platform Administrator has tenant_id === null. TenantSubscription/
        // SubscriptionChangeRequest/StorageAddon use BelongsToTenantOrPlatformAdmin,
        // which is verified to apply no filter at all for the Platform
        // Administrator — this guards against a regression where that
        // exemption stops working and cross-tenant rows silently disappear.
        $tenantA = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $tenantB = Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantA->id, 'status' => 'pending']);
        StorageAddon::factory()->for($tenantB, 'tenant')->create(['status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/subscriptions?pending_only=1');

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
    }
}
