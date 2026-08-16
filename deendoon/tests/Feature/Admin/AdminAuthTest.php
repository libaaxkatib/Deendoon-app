<?php

namespace Tests\Feature\Admin;

use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminAuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function platformAdmin(): User
    {
        $admin = User::factory()->create(['password' => Hash::make('Password123!')]);
        $admin->assignRole('deendoon_platform_administrator');

        return $admin;
    }

    public function test_platform_administrator_can_login_and_reach_the_dashboard(): void
    {
        $admin = $this->platformAdmin();

        $response = $this->post('/admin/login', [
            'email' => $admin->email,
            'password' => 'Password123!',
        ]);

        $response->assertRedirect(route('admin.dashboard'));
        $this->assertAuthenticatedAs($admin);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        $admin = $this->platformAdmin();

        $response = $this->post('/admin/login', [
            'email' => $admin->email,
            'password' => 'WrongPassword!',
        ]);

        $response->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    public function test_a_business_owner_cannot_login_to_the_admin_panel(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create(['password' => Hash::make('Password123!')]);
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        $response = $this->post('/admin/login', [
            'email' => $owner->email,
            'password' => 'Password123!',
        ]);

        $response->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    public function test_guest_is_redirected_to_login_when_visiting_the_dashboard(): void
    {
        $response = $this->get('/admin/dashboard');

        $response->assertRedirect(route('admin.login'));
    }

    public function test_platform_administrator_can_logout(): void
    {
        $admin = $this->platformAdmin();

        $response = $this->actingAs($admin)->post('/admin/logout');

        $response->assertRedirect(route('admin.login'));
        $this->assertGuest();
    }
}
