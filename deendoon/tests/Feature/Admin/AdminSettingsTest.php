<?php

namespace Tests\Feature\Admin;

use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminSettingsTest extends TestCase
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

    // --- Access control ---

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $this->get('/admin/settings')->assertRedirect(route('admin.login'));
    }

    public function test_a_business_owner_is_forbidden(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAs($this->businessOwner($tenant))->get('/admin/settings')->assertForbidden();
        $this->actingAs($this->businessOwner($tenant))->get('/admin/settings/create')->assertForbidden();
        $this->actingAs($this->businessOwner($tenant))->post('/admin/settings', [])->assertForbidden();
    }

    public function test_platform_administrator_can_view_the_plan_list(): void
    {
        SubscriptionPlan::factory()->create(['name' => 'Small Business']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/settings');

        $response->assertOk();
        $response->assertSee('Small Business');
    }

    // --- Create ---

    public function test_platform_administrator_can_create_a_plan(): void
    {
        $response = $this->actingAs($this->platformAdmin())->post('/admin/settings', [
            'name' => 'Growth',
            'monthly_price' => 12.50,
            'customer_limit' => 300,
            'storage_limit' => 40,
            'analytics_enabled' => '1',
        ]);

        $response->assertRedirect(route('admin.settings.index'));
        $this->assertDatabaseHas('subscription_plans', [
            'name' => 'Growth',
            'monthly_price' => 12.50,
            'customer_limit' => 300,
            'storage_limit' => 40,
            'analytics_enabled' => true,
            'active' => true,
        ]);
    }

    public function test_creating_a_plan_with_no_customer_limit_field_stores_unlimited(): void
    {
        $response = $this->actingAs($this->platformAdmin())->post('/admin/settings', [
            'name' => 'Corporate Plus',
            'monthly_price' => 25,
            'customer_limit' => '',
            'storage_limit' => 200,
        ]);

        $response->assertRedirect(route('admin.settings.index'));
        $this->assertDatabaseHas('subscription_plans', ['name' => 'Corporate Plus', 'customer_limit' => null]);
    }

    public function test_creating_a_plan_without_checking_analytics_stores_it_disabled(): void
    {
        $this->actingAs($this->platformAdmin())->post('/admin/settings', [
            'name' => 'Basic',
            'monthly_price' => 3,
            'storage_limit' => 10,
        ])->assertRedirect(route('admin.settings.index'));

        $this->assertDatabaseHas('subscription_plans', ['name' => 'Basic', 'analytics_enabled' => false]);
    }

    public function test_creating_a_plan_records_an_audit_log_entry(): void
    {
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post('/admin/settings', [
            'name' => 'Growth', 'monthly_price' => 12.50, 'storage_limit' => 40,
        ])->assertRedirect(route('admin.settings.index'));

        $this->assertDatabaseHas('audit_log', [
            'user_id' => (string) $admin->id, 'action' => 'created', 'entity_type' => 'subscription_plan',
        ]);
    }

    public function test_plan_name_must_be_unique(): void
    {
        SubscriptionPlan::factory()->create(['name' => 'Small Business']);

        $response = $this->actingAs($this->platformAdmin())->post('/admin/settings', [
            'name' => 'Small Business', 'monthly_price' => 5, 'storage_limit' => 25,
        ]);

        $response->assertSessionHasErrors('name');
        $this->assertSame(1, SubscriptionPlan::where('name', 'Small Business')->count());
    }

    public function test_validation_requires_name_price_and_storage_limit(): void
    {
        $response = $this->actingAs($this->platformAdmin())->post('/admin/settings', []);

        $response->assertSessionHasErrors(['name', 'monthly_price', 'storage_limit']);
    }

    // --- Update ---

    public function test_platform_administrator_can_edit_a_plan(): void
    {
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business', 'monthly_price' => 5]);

        $response = $this->actingAs($this->platformAdmin())->put("/admin/settings/{$plan->id}", [
            'name' => 'Small Business', 'monthly_price' => 7.50, 'customer_limit' => 150, 'storage_limit' => 30,
        ]);

        $response->assertRedirect(route('admin.settings.index'));
        $this->assertDatabaseHas('subscription_plans', [
            'id' => $plan->id, 'monthly_price' => 7.50, 'customer_limit' => 150, 'storage_limit' => 30,
        ]);
    }

    public function test_editing_a_plan_can_keep_its_own_name(): void
    {
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);

        $response = $this->actingAs($this->platformAdmin())->put("/admin/settings/{$plan->id}", [
            'name' => 'Small Business', 'monthly_price' => 5, 'storage_limit' => 25,
        ]);

        $response->assertRedirect(route('admin.settings.index'));
        $response->assertSessionHasNoErrors();
    }

    public function test_editing_a_plan_records_an_audit_log_entry(): void
    {
        $admin = $this->platformAdmin();
        $plan = SubscriptionPlan::factory()->create();

        $this->actingAs($admin)->put("/admin/settings/{$plan->id}", [
            'name' => $plan->name, 'monthly_price' => 9, 'storage_limit' => 20,
        ])->assertRedirect(route('admin.settings.index'));

        $this->assertDatabaseHas('audit_log', [
            'user_id' => (string) $admin->id, 'action' => 'edited', 'entity_type' => 'subscription_plan', 'entity_id' => $plan->id,
        ]);
    }

    // --- Activate / Deactivate ---

    public function test_platform_administrator_can_deactivate_a_plan(): void
    {
        $plan = SubscriptionPlan::factory()->create(['active' => true]);

        $response = $this->actingAs($this->platformAdmin())->post("/admin/settings/{$plan->id}/deactivate");

        $response->assertRedirect(route('admin.settings.index'));
        $this->assertDatabaseHas('subscription_plans', ['id' => $plan->id, 'active' => false]);
    }

    public function test_platform_administrator_can_reactivate_a_plan(): void
    {
        $plan = SubscriptionPlan::factory()->create(['active' => false]);

        $response = $this->actingAs($this->platformAdmin())->post("/admin/settings/{$plan->id}/activate");

        $response->assertRedirect(route('admin.settings.index'));
        $this->assertDatabaseHas('subscription_plans', ['id' => $plan->id, 'active' => true]);
    }

    public function test_deactivating_a_plan_records_an_audit_log_entry(): void
    {
        $admin = $this->platformAdmin();
        $plan = SubscriptionPlan::factory()->create(['active' => true]);

        $this->actingAs($admin)->post("/admin/settings/{$plan->id}/deactivate")->assertRedirect(route('admin.settings.index'));

        $this->assertDatabaseHas('audit_log', [
            'user_id' => (string) $admin->id, 'action' => 'status_changed', 'entity_type' => 'subscription_plan', 'entity_id' => $plan->id,
        ]);
    }

    public function test_a_business_owner_cannot_activate_or_deactivate_a_plan(): void
    {
        $tenant = Tenant::factory()->create();
        $plan = SubscriptionPlan::factory()->create(['active' => true]);

        $this->actingAs($this->businessOwner($tenant))->post("/admin/settings/{$plan->id}/deactivate")->assertForbidden();
    }
}
