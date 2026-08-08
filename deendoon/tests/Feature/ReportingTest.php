<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\Reminder;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReportingTest extends TestCase
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

        // Backend Completion Roadmap (Phase 4.4): reporting endpoints now
        // require analytics_enabled (the Free Plan explicitly excludes
        // it) — give every tenant in this file a plan that includes it,
        // centralized here rather than in each of the ~30 test methods.
        if (! TenantSubscription::where('tenant_id', $tenant->id)->exists()) {
            $plan = SubscriptionPlan::factory()->create(['analytics_enabled' => true]);
            TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();
        }

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    private function actingAsPlatformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        Sanctum::actingAs($admin, ['*']);

        return $admin;
    }

    private function makeDebt(Tenant $tenant, array $attributes = []): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    // --- Dashboard KPIs (FR-053) ---

    public function test_admin_can_view_dashboard_kpis(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => [
                'scope', 'period', 'total_outstanding_amount', 'total_collected_period',
                'recovery_rate', 'total_overdue_debts' => ['count', 'value'],
                'customers_over_credit_limit', 'active_collection_cases',
            ]]);
    }

    public function test_total_outstanding_amount_sums_remaining_balance_of_open_debts(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['remaining_balance' => 500, 'debt_status' => 'pending']);
        $this->makeDebt($tenant, ['remaining_balance' => 300, 'debt_status' => 'overdue']);
        $this->makeDebt($tenant, ['remaining_balance' => 0, 'debt_status' => 'paid']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.total_outstanding_amount', '800.00');
    }

    public function test_total_collected_period_sums_payments_within_the_selected_period(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 100, 'payment_date' => now()->toDateString()]);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 200, 'payment_date' => now()->subYears(2)->toDateString()]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis?period=day');

        $response->assertJsonPath('data.total_collected_period', '100.00');
    }

    public function test_total_overdue_debts_counts_and_values_overdue_debts(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['debt_status' => 'overdue', 'remaining_balance' => 250]);
        $this->makeDebt($tenant, ['debt_status' => 'overdue', 'remaining_balance' => 150]);
        $this->makeDebt($tenant, ['debt_status' => 'pending', 'remaining_balance' => 999]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.total_overdue_debts.count', 2)
            ->assertJsonPath('data.total_overdue_debts.value', '400.00');
    }

    public function test_total_overdue_debts_includes_a_debt_whose_stored_status_has_not_been_lazily_refreshed(): void
    {
        // FR-021 (Business Owner Backend Completion): a Debt past its due
        // date but never individually viewed via DebtController::show()
        // still has stored debt_status = 'pending' — the Dashboard KPI
        // must still count it as overdue (Debt::scopeEffectivelyOverdue()).
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['debt_status' => 'pending', 'due_date' => now()->subDays(5)->toDateString(), 'remaining_balance' => 300]);
        $this->makeDebt($tenant, ['debt_status' => 'pending', 'due_date' => now()->addDays(10)->toDateString(), 'remaining_balance' => 999]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.total_overdue_debts.count', 1)
            ->assertJsonPath('data.total_overdue_debts.value', '300.00');
    }

    public function test_customers_over_credit_limit_counts_correctly(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 1000, 'outstanding_balance' => 1500]);
        Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 1000, 'outstanding_balance' => 500]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.customers_over_credit_limit', 1);
    }

    public function test_high_risk_customers_counts_correctly(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.high_risk_customers', 2);
    }

    public function test_high_risk_customers_respects_tenant_isolation(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        Customer::factory()->for($tenantA, 'tenant')->create(['risk_level' => 'high']);
        Customer::factory()->for($tenantB, 'tenant')->create(['risk_level' => 'high']);
        Customer::factory()->for($tenantB, 'tenant')->create(['risk_level' => 'high']);
        $this->actingAsTenantUser($tenantA);

        $this->getJson('/api/v1/dashboard/kpis')->assertJsonPath('data.high_risk_customers', 1);
    }

    // --- Today's Overview (§4.3 — reuses Reminder Center's summary) ---

    public function test_todays_overview_matches_reminder_center_summary(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        Reminder::factory()->for($tenant, 'tenant')->dueToday()->create([
            'related_entity_type' => 'debt', 'related_entity_id' => $debt->id, 'type' => 'payment_due',
        ]);

        $dashboardResponse = $this->getJson('/api/v1/dashboard/todays-overview');
        $reminderCenterResponse = $this->getJson('/api/v1/reminders/summary');

        $dashboardResponse->assertStatus(200);
        $this->assertSame($reminderCenterResponse->json('data'), $dashboardResponse->json('data'));
    }

    // --- Recent Cases (§4.5) ---

    public function test_recent_cases_returns_most_recently_active_cases_first(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseA = CollectionCase::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create();
        $this->travel(1)->minutes();
        $caseB = CollectionCase::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->create();

        $response = $this->getJson('/api/v1/dashboard/recent-cases');

        $ids = collect($response->json('data'))->pluck('id');
        $this->assertSame([$caseB->id, $caseA->id], $ids->all());
    }

    public function test_recent_cases_respects_the_limit_parameter(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        foreach (range(1, 3) as $i) {
            $debt = $this->makeDebt($tenant);
            CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        }

        $response = $this->getJson('/api/v1/dashboard/recent-cases?limit=2');

        $this->assertCount(2, $response->json('data'));
    }

    public function test_recent_cases_includes_customer_name_and_risk_level(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Somali Builders', 'risk_level' => 'high']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();

        $response = $this->getJson('/api/v1/dashboard/recent-cases');

        $response->assertJsonPath('data.0.customer_name', 'Somali Builders')
            ->assertJsonPath('data.0.risk_level', 'high');
    }

    public function test_active_collection_cases_excludes_closed_cases(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create(['case_status' => 'open']);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->closed()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.active_collection_cases', 1);
    }

    public function test_recovery_rate_divides_collected_by_amount_due_in_the_selected_period(): void
    {
        // Business Owner Backend Completion (pre-Phase 5, DD-032
        // Product Owner-approved formula): reuses the exact same
        // Collected ÷ Became Due calculation as collectionAnalytics()'s
        // Collection Rate — see test_collection_rate_divides_collected_by_
        // amount_due_in_period for the mirrored Reports-endpoint coverage.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'due_date' => now()->toDateString()]);
        $this->actingAsTenantUser($tenant);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 400, 'payment_date' => now()->toDateString()]);

        $response = $this->getJson('/api/v1/dashboard/kpis?period=day');

        $response->assertJsonPath('data.recovery_rate', 40);
    }

    public function test_recovery_rate_is_zero_when_nothing_became_due_in_the_period(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/dashboard/kpis')->assertJsonPath('data.recovery_rate', 0);
    }

    /**
     * Sprint 17B — dashboard/kpis folds in BusinessHealthService's own
     * result rather than a second, divergent calculation; still Neutral
     * Baseline today since DD-032/Outstanding Exposure remain unresolved.
     */
    public function test_dashboard_kpis_includes_business_health(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.business_health.status', 'neutral_baseline')
            ->assertJsonPath('data.business_health.score', null);
    }

    /**
     * `Mobile_UI_V1_Frozen.md` §4.1: Business Health is "Visible to
     * Business Owner" only — no system-wide definition exists for it, so
     * the Platform Administrator's system-wide KPI view omits it entirely
     * rather than computing something meaningless.
     */
    public function test_platform_admin_kpis_omit_business_health(): void
    {
        $this->actingAsPlatformAdmin();

        $this->getJson('/api/v1/dashboard/kpis')->assertJsonPath('data.business_health', null);
    }

    public function test_platform_admin_sees_system_wide_kpis(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $this->makeDebt($tenantA, ['debt_status' => 'overdue', 'remaining_balance' => 100]);
        $this->makeDebt($tenantB, ['debt_status' => 'overdue', 'remaining_balance' => 200]);

        $this->actingAsPlatformAdmin();
        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertStatus(200)
            ->assertJsonPath('data.scope', 'system')
            ->assertJsonPath('data.total_overdue_debts.count', 2);
    }

    public function test_tenant_user_sees_only_their_own_tenant_kpis(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $this->makeDebt($tenantA, ['debt_status' => 'overdue', 'remaining_balance' => 100]);
        $this->makeDebt($tenantB, ['debt_status' => 'overdue', 'remaining_balance' => 200]);

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/dashboard/kpis');

        $response->assertJsonPath('data.scope', 'tenant')
            ->assertJsonPath('data.total_overdue_debts.count', 1)
            ->assertJsonPath('data.total_overdue_debts.value', '100.00');
    }

    public function test_invalid_period_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/dashboard/kpis?period=fortnight')->assertStatus(422);
    }

    // --- Aging Analysis (FR-054) ---

    public function test_admin_can_view_aging_analysis(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/aging-analysis');

        $response->assertStatus(200)->assertJsonStructure(['data' => ['buckets', 'debts', 'pagination']]);
    }

    public function test_debt_not_yet_due_is_in_the_current_bucket(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['due_date' => now()->addDays(10)->toDateString(), 'remaining_balance' => 100]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/aging-analysis');

        $response->assertJsonPath('data.buckets.current.count', 1);
    }

    public function test_debt_overdue_by_15_days_is_in_the_1_30_bucket(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['due_date' => now()->subDays(15)->toDateString(), 'debt_status' => 'overdue', 'remaining_balance' => 100]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/aging-analysis')->assertJsonPath('data.buckets.1_30.count', 1);
    }

    public function test_debt_overdue_by_45_days_is_in_the_31_60_bucket(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['due_date' => now()->subDays(45)->toDateString(), 'debt_status' => 'overdue', 'remaining_balance' => 100]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/aging-analysis')->assertJsonPath('data.buckets.31_60.count', 1);
    }

    public function test_debt_overdue_by_75_days_is_in_the_61_90_bucket(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['due_date' => now()->subDays(75)->toDateString(), 'debt_status' => 'overdue', 'remaining_balance' => 100]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/aging-analysis')->assertJsonPath('data.buckets.61_90.count', 1);
    }

    public function test_debt_overdue_by_100_days_is_in_the_over_90_bucket(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['due_date' => now()->subDays(100)->toDateString(), 'debt_status' => 'overdue', 'remaining_balance' => 100]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/aging-analysis')->assertJsonPath('data.buckets.over_90.count', 1);
    }

    public function test_bucket_value_uses_remaining_balance_not_original_amount(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['due_date' => now()->subDays(10)->toDateString(), 'debt_status' => 'overdue', 'amount' => 1000, 'remaining_balance' => 400]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/aging-analysis')->assertJsonPath('data.buckets.1_30.total_remaining_balance', '400.00');
    }

    public function test_paid_debts_are_excluded_from_aging_analysis(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['due_date' => now()->subDays(10)->toDateString(), 'debt_status' => 'paid', 'remaining_balance' => 0]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/aging-analysis');

        $total = collect($response->json('data.buckets'))->sum('count');
        $this->assertSame(0, $total);
    }

    public function test_aging_analysis_can_be_filtered_by_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtA = $this->makeDebt($tenant);
        $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/reports/aging-analysis?customer_id={$debtA->customer_id}");

        $this->assertCount(1, $response->json('data.debts'));
    }

    // --- Standard Reports (FR-055) ---

    public function test_admin_can_view_customers_report(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/customers')->assertStatus(200)->assertJsonStructure(['data' => ['customers', 'pagination']]);
    }

    public function test_admin_can_view_debts_report(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/debts')->assertStatus(200)->assertJsonStructure(['data' => ['debts', 'pagination']]);
    }

    public function test_admin_can_view_collection_cases_report(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/collection-cases')->assertStatus(200)->assertJsonStructure(['data' => ['collection_cases', 'pagination']]);
    }

    public function test_admin_can_view_payments_report(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/payments')->assertStatus(200)->assertJsonStructure(['data' => ['payments', 'pagination']]);
    }

    public function test_admin_can_view_credit_risk_report(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low', 'credit_score' => 700]);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/credit-risk')->assertStatus(200)->assertJsonStructure(['data' => ['customers', 'pagination']]);
    }

    public function test_archived_customers_are_excluded_by_default_from_the_customers_report(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->archived()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/customers');

        $this->assertCount(0, $response->json('data.customers'));
    }

    // --- Filters (FR-056) ---

    public function test_customers_report_can_be_filtered_by_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['customer_status' => 'active']);
        Customer::factory()->for($tenant, 'tenant')->create(['customer_status' => 'inactive']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/customers?customer_status=inactive');

        $this->assertCount(1, $response->json('data.customers'));
    }

    public function test_debts_report_can_be_filtered_by_status_and_recovery_stage(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['debt_status' => 'overdue', 'recovery_stage' => 2]);
        $this->makeDebt($tenant, ['debt_status' => 'pending', 'recovery_stage' => 1]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/debts?status=overdue&recoveryStage=2');

        $this->assertCount(1, $response->json('data.debts'));
    }

    public function test_debts_report_status_overdue_filter_includes_a_debt_whose_stored_status_has_not_been_lazily_refreshed(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['debt_status' => 'pending', 'due_date' => now()->subDays(5)->toDateString()]);
        $this->makeDebt($tenant, ['debt_status' => 'pending', 'due_date' => now()->addDays(10)->toDateString()]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/debts?status=overdue');

        $this->assertCount(1, $response->json('data.debts'));
    }

    public function test_debts_report_status_filter_for_a_non_overdue_status_still_matches_exactly(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant, ['debt_status' => 'pending']);
        $this->makeDebt($tenant, ['debt_status' => 'partial_paid']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/debts?status=pending');

        $this->assertCount(1, $response->json('data.debts'));
    }

    public function test_collection_cases_report_can_be_filtered_by_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create(['case_status' => 'open']);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->closed()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/collection-cases?status=closed');

        $this->assertCount(1, $response->json('data.collection_cases'));
    }

    // --- Collection Analytics (docs/Mobile_UI_V1_Frozen.md §5.4) ---

    public function test_collection_rate_divides_collected_by_amount_due_in_period(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'due_date' => now()->toDateString()]);
        $this->actingAsTenantUser($tenant);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 400, 'payment_date' => now()->toDateString()]);

        $response = $this->getJson('/api/v1/reports/collection-analytics?dateFrom='.now()->startOfMonth()->toDateString().'&dateTo='.now()->toDateString());

        $response->assertStatus(200)
            ->assertJsonPath('data.collection_rate', 40)
            ->assertJsonPath('data.total_collected', '400.00');
    }

    public function test_average_days_computed_from_debts_paid_within_the_period(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, [
            'amount' => 500, 'remaining_balance' => 0, 'debt_status' => 'paid',
            'due_date' => now()->subDays(10)->toDateString(),
        ]);
        $this->actingAsTenantUser($tenant);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'amount' => 500, 'payment_date' => now()->toDateString(),
        ]);

        $response = $this->getJson('/api/v1/reports/collection-analytics?dateFrom='.now()->subDays(30)->toDateString().'&dateTo='.now()->toDateString());

        $response->assertStatus(200)->assertJsonPath('data.average_days', 10);
    }

    public function test_collection_analytics_defaults_to_the_current_month(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/collection-analytics')
            ->assertStatus(200)
            ->assertJsonStructure(['data' => ['collection_rate', 'total_collected', 'average_days']]);
    }

    // --- Risk Distribution (docs/Mobile_UI_V1_Frozen.md §5.6) ---

    public function test_risk_distribution_returns_counts_and_percentages(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/risk-distribution');

        $response->assertStatus(200);
        $segments = collect($response->json('data.segments'))->keyBy('risk_level');
        $this->assertSame(1, $segments['high']['customer_count']);
        $this->assertSame(2, $segments['low']['customer_count']);
        $this->assertEqualsWithDelta(33.33, $segments['high']['percentage'], 0.01);
    }

    public function test_risk_distribution_excludes_unclassified_customers_from_the_percentage_base(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => null]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reports/risk-distribution');

        $segments = collect($response->json('data.segments'))->keyBy('risk_level');
        $this->assertEquals(100, $segments['high']['percentage']);
    }

    // --- Collections Trend (docs/Mobile_UI_V1_Frozen.md §5.3) ---

    public function test_collections_trend_returns_one_point_per_day(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'amount' => 250, 'payment_date' => now()->subDay()->toDateString(),
        ]);

        $response = $this->getJson('/api/v1/reports/collections-trend?dateFrom='.now()->subDays(2)->toDateString().'&dateTo='.now()->toDateString().'&metric=collected_amount');

        $response->assertStatus(200)->assertJsonPath('data.metric', 'collected_amount');
        $series = collect($response->json('data.series'))->keyBy('date');
        $this->assertSame('250.00', $series[now()->subDay()->toDateString()]['value']);
        $this->assertSame('0.00', $series[now()->subDays(2)->toDateString()]['value']);
    }

    public function test_collections_trend_rejects_an_unsupported_metric(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/collections-trend?dateFrom='.now()->subDays(2)->toDateString().'&dateTo='.now()->toDateString().'&metric=outstanding_amount')
            ->assertStatus(422);
    }

    // --- Export (FR-057) ---

    public function test_admin_can_export_customers_report_as_csv(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->get('/api/v1/reports/customers/export?format=csv');

        $response->assertStatus(200);
    }

    public function test_admin_can_export_debts_report_as_excel(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->get('/api/v1/reports/debts/export?format=excel');

        $response->assertStatus(200);
    }

    public function test_admin_can_export_aging_analysis_as_pdf(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->get('/api/v1/reports/aging-analysis/export?format=pdf');

        $response->assertStatus(200);
        $this->assertSame('application/pdf', $response->headers->get('content-type'));
    }

    public function test_export_requires_a_valid_format(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/customers/export?format=word')->assertStatus(422);
    }

    public function test_export_of_an_unknown_report_type_returns_404(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/reports/not-a-real-report/export?format=csv')->assertStatus(404);
    }

    // --- Export size limit (Business Owner Backend Completion, pre-Phase 5) ---

    public function test_export_is_rejected_when_the_filtered_dataset_exceeds_the_configured_row_limit(): void
    {
        putenv('REPORT_EXPORT_MAX_ROWS=2');

        try {
            $tenant = Tenant::create(['business_name' => 'Acme Co']);
            Customer::factory()->for($tenant, 'tenant')->count(3)->create();
            $this->actingAsTenantUser($tenant);

            $response = $this->getJson('/api/v1/reports/customers/export?format=csv');

            $response->assertStatus(422)->assertJson(['success' => false]);
        } finally {
            putenv('REPORT_EXPORT_MAX_ROWS');
        }
    }

    public function test_export_succeeds_when_the_filtered_dataset_is_within_the_configured_row_limit(): void
    {
        putenv('REPORT_EXPORT_MAX_ROWS=2');

        try {
            $tenant = Tenant::create(['business_name' => 'Acme Co']);
            Customer::factory()->for($tenant, 'tenant')->count(2)->create();
            $this->actingAsTenantUser($tenant);

            $this->get('/api/v1/reports/customers/export?format=csv')->assertStatus(200);
        } finally {
            putenv('REPORT_EXPORT_MAX_ROWS');
        }
    }

    public function test_export_row_limit_defaults_to_20000_when_unconfigured(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->get('/api/v1/reports/customers/export?format=csv')->assertStatus(200);
    }

    // --- Authentication / Authorization / Tenant isolation ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/dashboard/kpis')->assertStatus(401);
        $this->getJson('/api/v1/reports/aging-analysis')->assertStatus(401);
        $this->getJson('/api/v1/reports/customers')->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_view_reports(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, null);

        $this->getJson('/api/v1/dashboard/kpis')->assertStatus(403);
        $this->getJson('/api/v1/reports/customers')->assertStatus(403);
    }

    public function test_reports_respect_tenant_isolation(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        Customer::factory()->for($tenantA, 'tenant')->create(['name' => 'Customer A']);
        Customer::factory()->for($tenantB, 'tenant')->create(['name' => 'Customer B']);

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/reports/customers');

        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Customer A'));
        $this->assertFalse($names->contains('Customer B'));
    }
}
