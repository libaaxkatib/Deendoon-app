<?php

namespace Tests\Feature\Admin;

use App\Enums\AuditAction;
use App\Models\AuditLog;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use LogicException;
use Tests\TestCase;

class AdminAuditLogTest extends TestCase
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
        $this->get('/admin/audit-logs')->assertRedirect(route('admin.login'));
    }

    public function test_a_business_owner_is_forbidden(): void
    {
        $this->actingAs($this->businessOwner(Tenant::factory()->create()))->get('/admin/audit-logs')->assertForbidden();
    }

    public function test_platform_administrator_can_view_the_page(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSee('Audit Logs');
    }

    // --- Cross-tenant visibility ---

    public function test_entries_across_multiple_businesses_are_all_visible(): void
    {
        $tenantA = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $tenantB = Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);
        AuditLog::factory()->create(['tenant_id' => $tenantA->id, 'action' => AuditAction::Created->value, 'entity_type' => 'customer']);
        AuditLog::factory()->create(['tenant_id' => $tenantB->id, 'action' => AuditAction::Created->value, 'entity_type' => 'customer']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
    }

    // --- Filters ---

    public function test_can_filter_by_action(): void
    {
        $tenant = Tenant::factory()->create();
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'action' => AuditAction::Created->value, 'reason' => 'Created row']);
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'action' => AuditAction::Archived->value, 'reason' => 'Archived row']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs?action=archived');

        $response->assertOk();
        $response->assertSee('Archived row');
        $response->assertDontSee('Created row');
    }

    public function test_can_filter_by_entity_type(): void
    {
        $tenant = Tenant::factory()->create();
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'entity_type' => 'customer', 'reason' => 'Customer row']);
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'entity_type' => 'debt', 'reason' => 'Debt row']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs?entity_type=debt');

        $response->assertOk();
        $response->assertSee('Debt row');
        $response->assertDontSee('Customer row');
    }

    public function test_can_filter_by_business(): void
    {
        // Both business names always appear once regardless of filter (the
        // tenant picker dropdown lists every business) — the filter's
        // actual effect is verified via each row's own distinct reason.
        $tenantA = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $tenantB = Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);
        AuditLog::factory()->create(['tenant_id' => $tenantA->id, 'reason' => 'Hodan row']);
        AuditLog::factory()->create(['tenant_id' => $tenantB->id, 'reason' => 'Barwaqo row']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs?tenant_id='.$tenantA->id);

        $response->assertOk();
        $response->assertSee('Hodan row');
        $response->assertDontSee('Barwaqo row');
    }

    public function test_can_filter_by_date_range(): void
    {
        $tenant = Tenant::factory()->create();
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'reason' => 'Inside range', 'occurred_at' => '2026-06-15 10:00:00']);
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'reason' => 'Outside range', 'occurred_at' => '2026-01-01 10:00:00']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs?date_from=2026-06-01&date_to=2026-06-30');

        $response->assertOk();
        $response->assertSee('Inside range');
        $response->assertDontSee('Outside range');
    }

    public function test_search_matches_reason(): void
    {
        $tenant = Tenant::factory()->create();
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'reason' => 'Suspended for repeated non-payment']);
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'reason' => 'Reactivated by Platform Administrator']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs?search=non-payment');

        $response->assertOk();
        $response->assertSee('Suspended for repeated non-payment');
        $response->assertDontSee('Reactivated by Platform Administrator');
    }

    // --- Pagination & ordering ---

    public function test_pagination_shows_next_when_more_than_twenty_five_entries(): void
    {
        AuditLog::factory()->count(26)->create();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSee('Next');
    }

    public function test_results_are_ordered_newest_first(): void
    {
        $tenant = Tenant::factory()->create();
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'reason' => 'Older entry', 'occurred_at' => now()->subDays(5)]);
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'reason' => 'Newer entry', 'occurred_at' => now()]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSeeInOrder(['Newer entry', 'Older entry']);
    }

    // --- Reason displayed verbatim (Decision 1) ---

    public function test_reason_is_displayed_verbatim(): void
    {
        $tenant = Tenant::factory()->create();
        AuditLog::factory()->create([
            'tenant_id' => $tenant->id,
            'reason' => 'Suspended: repeated non-payment on 3 consecutive invoices',
        ]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSee('Suspended: repeated non-payment on 3 consecutive invoices');
    }

    // --- Actor name resolution (CHAR(26) padding regression) ---

    /**
     * audit_log.user_id is CHAR(26); PostgreSQL right-pads a short stored
     * value (e.g. a bigint id) with trailing spaces on SELECT — the same
     * issue proven and fixed for Announcement::sentByUserId(). SQLite, the
     * test driver, never pads CHAR columns, so this simulates the exact
     * stored shape a real PostgreSQL round-trip produces.
     */
    public function test_actor_name_resolves_correctly_even_when_the_stored_id_is_padded(): void
    {
        $admin = $this->platformAdmin();
        $tenant = Tenant::factory()->create();
        DB::table('audit_log')->insert([
            'id' => (string) Str::ulid(),
            'tenant_id' => $tenant->id,
            'user_id' => $admin->id.str_repeat(' ', 26 - strlen((string) $admin->id)),
            'action' => AuditAction::Login->value,
            'entity_type' => 'user',
            'entity_id' => (string) $admin->id,
            'reason' => null,
            'occurred_at' => now(),
        ]);

        $response = $this->actingAs($admin)->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSee($admin->name);
        $response->assertDontSee('Unknown');
    }

    /**
     * An actor who has since been deactivated (User uses SoftDeletes) must
     * still be identifiable in the audit trail — the action genuinely
     * happened. The default Eloquent query excludes trashed rows, so this
     * guards against a regression that would silently start showing
     * "Unknown" for every archived user's past actions.
     */
    public function test_actor_name_resolves_for_a_since_archived_user(): void
    {
        $tenant = Tenant::factory()->create();
        $archivedActor = User::factory()->create(['name' => 'Formerly Active Admin']);
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'user_id' => (string) $archivedActor->id]);
        $archivedActor->delete();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSee('Formerly Active Admin');
        $response->assertDontSee('Unknown');
    }

    public function test_a_system_attributed_entry_with_no_actor_shows_system_not_unknown(): void
    {
        $tenant = Tenant::factory()->create();
        AuditLog::factory()->create(['tenant_id' => $tenant->id, 'user_id' => null, 'action' => AuditAction::StatusChanged->value]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/audit-logs');

        $response->assertOk();
        $response->assertSee('System');
        $response->assertDontSee('Unknown');
    }

    // --- Immutability unchanged (regression) ---

    public function test_audit_log_records_remain_immutable(): void
    {
        $log = AuditLog::factory()->create();

        $this->expectException(LogicException::class);
        $log->update(['reason' => 'tampered']);
    }

    public function test_audit_log_records_still_cannot_be_deleted(): void
    {
        $log = AuditLog::factory()->create();

        $this->expectException(LogicException::class);
        $log->delete();
    }
}
