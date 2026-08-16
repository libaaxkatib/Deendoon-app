<?php

namespace Tests\Feature\Admin;

use App\Enums\AuditAction;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminBusinessManagementTest extends TestCase
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

    public function test_platform_administrator_can_list_businesses(): void
    {
        Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/businesses');

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
    }

    public function test_business_list_can_be_searched_by_name(): void
    {
        Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/businesses?search=hodan');

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertDontSee('Barwaqo Imports');
    }

    public function test_platform_administrator_can_view_a_business_detail_page(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/businesses/{$tenant->id}");

        $response->assertOk();
        $response->assertSee('Hodan Trading');
    }

    public function test_platform_administrator_can_suspend_a_business_with_a_reason(): void
    {
        $tenant = Tenant::factory()->create();
        $admin = $this->platformAdmin();

        $response = $this->actingAs($admin)->post("/admin/businesses/{$tenant->id}/suspend", [
            'reason' => 'Repeated non-payment of subscription fees.',
        ]);

        $response->assertRedirect();
        $this->assertSame('suspended', $tenant->fresh()->status);
        $this->assertNotNull($tenant->fresh()->suspended_at);

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'action' => AuditAction::StatusChanged->value,
            'entity_type' => 'tenant',
            'entity_id' => $tenant->id,
        ]);
    }

    public function test_suspending_a_business_requires_a_reason(): void
    {
        $tenant = Tenant::factory()->create();

        $response = $this->actingAs($this->platformAdmin())->post("/admin/businesses/{$tenant->id}/suspend", []);

        $response->assertSessionHasErrors('reason');
        $this->assertSame('active', $tenant->fresh()->status);
    }

    public function test_platform_administrator_can_reactivate_a_suspended_business(): void
    {
        $tenant = Tenant::factory()->suspended()->create();

        $response = $this->actingAs($this->platformAdmin())->post("/admin/businesses/{$tenant->id}/activate");

        $response->assertRedirect();
        $tenant->refresh();
        $this->assertSame('active', $tenant->status);
        $this->assertNull($tenant->suspended_at);
    }

    public function test_a_business_owner_is_forbidden_from_managing_businesses(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        $this->actingAs($owner)->get('/admin/businesses')->assertForbidden();
        $this->actingAs($owner)->post("/admin/businesses/{$tenant->id}/suspend", ['reason' => 'test'])
            ->assertForbidden();
    }
}
