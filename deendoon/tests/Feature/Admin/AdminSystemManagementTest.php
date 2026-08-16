<?php

namespace Tests\Feature\Admin;

use App\Models\SecurityEvent;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class AdminSystemManagementTest extends TestCase
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

    private function businessOwner(): User
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        return $owner;
    }

    /**
     * @return array<int, string>
     */
    public static function systemRouteProvider(): array
    {
        return [
            ['/admin/system'],
            ['/admin/system/platform-administrators'],
            ['/admin/system/security-events'],
            ['/admin/system/backup'],
            ['/admin/system/scheduler'],
        ];
    }

    #[DataProvider('systemRouteProvider')]
    public function test_guest_is_redirected_to_admin_login(string $path): void
    {
        $this->get($path)->assertRedirect(route('admin.login'));
    }

    #[DataProvider('systemRouteProvider')]
    public function test_a_business_owner_is_forbidden(string $path): void
    {
        $this->actingAs($this->businessOwner())->get($path)->assertForbidden();
    }

    #[DataProvider('systemRouteProvider')]
    public function test_platform_administrator_can_access_every_page(string $path): void
    {
        $this->actingAs($this->platformAdmin())->get($path)->assertOk();
    }

    // --- System Health ---

    public function test_system_health_shows_database_and_file_storage_as_real_checks(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/system');

        $response->assertOk();
        $response->assertSee('Database');
        $response->assertSee('File Storage');
        $response->assertSee('Application');
        $response->assertSee('API');
        $response->assertSee('Live check');
        $response->assertSee('Not yet backed by a real check');
    }

    public function test_system_health_shows_real_environment_info(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/system');

        $response->assertOk();
        $response->assertSee('Database Driver');
        $response->assertSee(config('database.default'));
    }

    // --- Scheduler ---

    public function test_scheduler_page_shows_the_three_registered_commands_via_a_real_http_request(): void
    {
        // Deliberately a plain HTTP-level test, not a console-context one —
        // this is exactly the request path that would have missed the
        // Artisan::starting() boot-timing issue if only tested via
        // Artisan::call()/artisan test's own console bootstrap.
        $response = $this->actingAs($this->platformAdmin())->get('/admin/system/scheduler');

        $response->assertOk();
        $response->assertSee('reminders:fire-due');
        $response->assertSee('subscriptions:expire-trials');
        $response->assertSee('notifications:prune-read');
        $response->assertSee('*/15 * * * *', false);
    }

    // --- Platform Administrator (read-only) ---

    public function test_platform_administrator_page_lists_administrators_read_only(): void
    {
        $admin = $this->platformAdmin();

        $response = $this->actingAs($admin)->get('/admin/system/platform-administrators');

        $response->assertOk();
        $response->assertSee($admin->email);
        $response->assertSee('Read-only');
    }

    public function test_there_is_no_create_platform_administrator_route(): void
    {
        $this->actingAs($this->platformAdmin())
            ->post('/admin/system/platform-administrators')
            ->assertStatus(405);
    }

    // --- Security Events ---

    public function test_security_events_lists_persisted_events(): void
    {
        SecurityEvent::factory()->create(['event_type' => 'login_failed', 'email' => 'attacker@example.com']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/system/security-events');

        $response->assertOk();
        $response->assertSee('attacker@example.com');
        $response->assertSee('Login Failed');
    }

    public function test_security_events_can_be_filtered_by_type(): void
    {
        SecurityEvent::factory()->create(['event_type' => 'login_failed', 'email' => 'a@example.com']);
        SecurityEvent::factory()->create(['event_type' => 'permission_denied', 'email' => null, 'path' => 'admin/users']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/system/security-events?event_type=permission_denied');

        $response->assertOk();
        $response->assertSee('admin/users');
        $response->assertDontSee('a@example.com');
    }

    public function test_security_events_can_be_searched_by_email(): void
    {
        SecurityEvent::factory()->create(['event_type' => 'login_failed', 'email' => 'findme@example.com']);
        SecurityEvent::factory()->create(['event_type' => 'login_failed', 'email' => 'other@example.com']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/system/security-events?search=findme');

        $response->assertOk();
        $response->assertSee('findme@example.com');
        $response->assertDontSee('other@example.com');
    }

    public function test_a_failed_login_persists_a_queryable_security_event(): void
    {
        $this->businessOwner();

        $this->postJson('/api/v1/login', ['email' => 'nonexistent@example.com', 'password' => 'wrong-password']);

        $this->assertDatabaseHas('security_events', [
            'event_type' => 'login_failed',
            'email' => 'nonexistent@example.com',
        ]);
    }

    // --- Database Backup ---

    public function test_business_owner_cannot_trigger_a_backup(): void
    {
        $this->actingAs($this->businessOwner())->post('/admin/system/backup')->assertForbidden();
    }

    public function test_guest_cannot_trigger_a_backup(): void
    {
        $this->post('/admin/system/backup')->assertRedirect(route('admin.login'));
    }

    /**
     * The full success/pg_dump-failure paths are covered at the service
     * level instead (tests/Unit/Services/Admin/DatabaseBackupServiceTest.php)
     * — overriding `database.default` to 'pgsql' mid-HTTP-test would make
     * the Auth guard's own subsequent user lookup try to hit a real
     * Postgres connection using the test suite's sqlite-only env values,
     * and would leak config state into whichever test runs next in this
     * process. This HTTP-level test only needs the driver-mismatch path,
     * which requires no config override at all — the suite's real default
     * connection already is sqlite, so the service must reject on its own.
     */
    public function test_backup_fails_gracefully_when_the_database_driver_is_not_postgresql(): void
    {
        $response = $this->actingAs($this->platformAdmin())->post('/admin/system/backup');

        $response->assertRedirect();
        $response->assertSessionHasErrors('backup');
    }
}
