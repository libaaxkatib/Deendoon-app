<?php

namespace Tests\Feature\Admin;

use App\Models\AuditLog;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
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

    public function test_platform_administrator_can_view_the_dashboard(): void
    {
        Tenant::factory()->count(3)->create();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Total Businesses');
        $response->assertSee('Total Debtors');
        $response->assertSee('Business & Recovery Dashboard');
        $response->assertSee('System / Platform Dashboard');
    }

    public function test_a_business_owner_is_forbidden_from_the_dashboard(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        $response = $this->actingAs($owner)->get('/admin/dashboard');

        $response->assertForbidden();
    }

    public function test_dashboard_renders_pending_state_for_unbuilt_backend_metrics(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/dashboard');

        $response->assertOk();
        // Support ticketing and system-usage trend have no backend yet —
        // the dashboard must say so honestly rather than hide the card or
        // fabricate a number (Product Owner instruction).
        $response->assertSee('Pending backend support');
    }

    public function test_recent_activity_shows_a_humanized_label_and_business_tag_not_a_raw_action_token(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Debug']);
        AuditLog::factory()->for($tenant, 'tenant')->create([
            'action' => 'credit_score_recalculated',
            'entity_type' => 'customer',
            'occurred_at' => now(),
        ]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Credit Score Recalculated');
        $response->assertSee('Debug');
        $response->assertDontSee('credit_score_recalculated');
    }
}
