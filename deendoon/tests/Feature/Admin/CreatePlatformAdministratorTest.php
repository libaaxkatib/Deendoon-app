<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class CreatePlatformAdministratorTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    public function test_it_creates_a_platform_administrator_with_no_tenant(): void
    {
        $this->artisan('admin:create-platform-admin', [
            '--name' => 'Deendoon Ops',
            '--email' => 'ops@deendoon.test',
            '--password' => 'Password123!',
        ])->assertSuccessful();

        $admin = User::where('email', 'ops@deendoon.test')->first();

        $this->assertNotNull($admin);
        $this->assertNull($admin->tenant_id);
        $this->assertTrue($admin->isPlatformAdmin());
        $this->assertTrue(Hash::check('Password123!', $admin->password));
    }

    public function test_it_rejects_a_duplicate_email(): void
    {
        User::factory()->create(['email' => 'ops@deendoon.test']);

        $this->artisan('admin:create-platform-admin', [
            '--name' => 'Deendoon Ops',
            '--email' => 'ops@deendoon.test',
            '--password' => 'Password123!',
        ])->assertFailed();
    }
}
