<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\PromiseToPay;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Phase 13 — Performance Optimization. Covers the two behavior-preserving
 * changes with a real regression risk (N+1 batching could silently drift
 * from the original per-row outcome; the pagination clamp is a new input
 * boundary) rather than re-testing business logic already covered
 * elsewhere (DebtTest, RecoveryWorkflowTest, AdministrationTest).
 */
class PerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function actingAsTenantUser(Tenant $tenant, string $role = 'admin'): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole($role);

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    /**
     * `risk_level` is pre-set to 'low' — the same value RiskLevelService
     * would itself compute for a brand-new Customer with no qualifying
     * events — so the Sprint 2B lazy recalculation this endpoint now also
     * performs is a guaranteed no-op (no UPDATE/audit-log write) here. That
     * keeps this helper's query cost isolated to what these tests actually
     * guard (Promise-to-Pay batching); Risk Level's own write cost, which
     * genuinely scales with the number of Customers whose label actually
     * changes, is covered separately in RiskLevelServiceTest/
     * RiskLevelEngineTest instead of being conflated with this regression
     * guard.
     */
    private function makeDebt(Tenant $tenant, array $attributes = []): Debt
    {
        // Business Owner Backend Completion (pre-Phase 5): credit_score/
        // credit_score_band pre-seeded at CreditScoreService's baseline
        // (70/'fair', the exact value a Debt with no promises/cases/
        // requests and a future due date computes to) for the same reason
        // risk_level is pre-seeded to 'low' — keeps CreditScoreService's
        // write a no-op here too, so this file's query-count guards test
        // genuine N+1 SELECT prevention, not legitimate first-time-write cost.
        $customer = Customer::factory()->for($tenant, 'tenant')->create([
            'credit_limit' => 5000, 'risk_level' => 'low', 'credit_score' => 70, 'credit_score_band' => 'fair',
        ]);

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    // --- Debt index: batched Promise-to-Pay refresh produces the same outcome as the per-debt version ---

    public function test_debts_index_breaks_overdue_promises_across_multiple_debts_on_one_page(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);

        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);

        $promiseA = PromiseToPay::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create([
            'promised_date' => now()->subDays(2)->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $user->id,
        ]);
        $promiseB = PromiseToPay::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->create([
            'promised_date' => now()->subDays(5)->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $user->id,
        ]);

        $this->getJson('/api/v1/debts')->assertStatus(200);

        $this->assertSame('broken', $promiseA->fresh()->status);
        $this->assertSame('broken', $promiseB->fresh()->status);
        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debtA->id, 'action_type' => 'promise_broken']);
        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debtB->id, 'action_type' => 'promise_broken']);
    }

    public function test_debts_index_creates_due_today_notifications_across_multiple_debts_on_one_page(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);

        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);

        $promiseA = PromiseToPay::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create([
            'promised_date' => now()->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $user->id,
        ]);
        $promiseB = PromiseToPay::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->create([
            'promised_date' => now()->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $user->id,
        ]);

        $this->getJson('/api/v1/debts')->assertStatus(200);

        $this->assertDatabaseHas('notifications', ['related_entity_type' => 'promise_to_pay', 'related_entity_id' => $promiseA->id]);
        $this->assertDatabaseHas('notifications', ['related_entity_type' => 'promise_to_pay', 'related_entity_id' => $promiseB->id]);

        // notifyOnce guard still holds under batching: a second index() call must not duplicate either notification.
        $this->getJson('/api/v1/debts')->assertStatus(200);
        $this->assertSame(1, DB::table('notifications')->where('related_entity_id', $promiseA->id)->count());
        $this->assertSame(1, DB::table('notifications')->where('related_entity_id', $promiseB->id)->count());
    }

    // --- Query-count regressions guarding the N+1 fixes ---

    public function test_debts_index_query_count_does_not_scale_with_page_size(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $fewDebts = 2;
        $manyDebts = 10;

        for ($i = 0; $i < $manyDebts; $i++) {
            $this->makeDebt($tenant);
        }

        DB::enableQueryLog();
        $this->getJson("/api/v1/debts?perPage={$fewDebts}")->assertStatus(200);
        $fewCount = count(DB::getQueryLog());
        DB::flushQueryLog();

        $this->getJson("/api/v1/debts?perPage={$manyDebts}")->assertStatus(200);
        $manyCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Before the Phase 13 fix, refreshBrokenPromises/refreshDuePromises each
        // issued one query per Debt on the page — query count would scale
        // linearly with page size. After batching, it should not.
        $this->assertLessThanOrEqual($fewCount + 3, $manyCount);
    }

    public function test_admin_users_index_query_count_does_not_scale_with_user_count(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        for ($i = 0; $i < 8; $i++) {
            $staff = User::factory()->create();
            $staff->tenant()->associate($tenant);
            $staff->save();
            $staff->assignRole('admin');
        }

        DB::enableQueryLog();
        $this->getJson('/api/v1/admin/users')->assertStatus(200);
        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Before the eager-load fix, AdminUserResource's `roles` access would
        // issue one extra query per listed user (9 users -> 9+ extra queries).
        $this->assertLessThan(15, $queryCount);
    }

    // --- Pagination clamp ---

    public function test_perpage_is_clamped_to_a_sane_maximum(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        for ($i = 0; $i < 5; $i++) {
            Customer::factory()->for($tenant, 'tenant')->create();
        }

        $response = $this->getJson('/api/v1/customers?perPage=999999');

        $response->assertStatus(200);
        $this->assertSame(100, $response->json('data.pagination.per_page'));
    }

    public function test_perpage_default_is_unchanged(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers');

        $response->assertStatus(200);
        $this->assertSame(15, $response->json('data.pagination.per_page'));
    }
}
