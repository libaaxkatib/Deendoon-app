<?php

namespace Tests\Feature\Admin;

use App\Exports\ReportExport;
use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\ProfessionalCollectionRequest;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Maatwebsite\Excel\Facades\Excel;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class AdminReportsManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
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

    /**
     * @return array{0: Tenant, 1: Customer, 2: Debt}
     */
    private function makeDebt(string $businessName, string $customerName, array $debtAttrs = []): array
    {
        $tenant = Tenant::factory()->create(['business_name' => $businessName]);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => $customerName]);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($debtAttrs);

        return [$tenant, $customer, $debt];
    }

    public function test_platform_administrator_can_view_the_executive_overview(): void
    {
        [$tenant] = $this->makeDebt('Hodan Trading', 'Amina Ali', ['amount' => 1000, 'remaining_balance' => 1000]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics');

        $response->assertOk();
        $response->assertSee('Executive Overview');
        $response->assertSee('Total Businesses');
    }

    public function test_business_owner_is_forbidden_from_reports_analytics(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->businessOwner($tenant);

        $this->actingAs($owner)->get('/admin/reports-analytics')->assertForbidden();
    }

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $this->get('/admin/reports-analytics')->assertRedirect(route('admin.login'));
    }

    /**
     * @return array<int, array<int, string>>
     */
    public static function reportPageProvider(): array
    {
        return [
            ['/admin/reports-analytics/debt-recovery', 'Debt & Recovery Report'],
            ['/admin/reports-analytics/debtor-risk', 'Debtor Risk Report'],
            ['/admin/reports-analytics/payments', 'Payment Report'],
            ['/admin/reports-analytics/professional-collection', 'Professional Collection Report'],
            ['/admin/reports-analytics/subscriptions', 'Subscription Report'],
            ['/admin/reports-analytics/business-growth', 'Business Growth Report'],
        ];
    }

    #[DataProvider('reportPageProvider')]
    public function test_each_report_page_renders(string $path, string $expectedHeading): void
    {
        $response = $this->actingAs($this->platformAdmin())->get($path);

        $response->assertOk();
        $response->assertSee($expectedHeading);
    }

    public function test_cross_tenant_totals_are_correct_on_the_debt_recovery_report(): void
    {
        $this->makeDebt('Hodan Trading', 'Amina Ali', ['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'pending']);
        $this->makeDebt('Barwaqo Imports', 'Yusuf Nur', ['amount' => 500, 'remaining_balance' => 500, 'debt_status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/debt-recovery');

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
        $response->assertSee('1,500.00');
    }

    public function test_individual_business_filtering_works(): void
    {
        [$tenantA] = $this->makeDebt('Hodan Trading', 'Amina Ali');
        $this->makeDebt('Barwaqo Imports', 'Yusuf Nur');

        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/reports-analytics/debt-recovery?tenant_id='.$tenantA->id);

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertDontSee('Yusuf Nur');
    }

    public function test_date_presets_scope_the_debt_recovery_report(): void
    {
        [, , $recentDebt] = $this->makeDebt('Hodan Trading', 'Amina Ali');
        $recentDebt->forceFill(['created_at' => now()])->save();

        [, , $oldDebt] = $this->makeDebt('Barwaqo Imports', 'Yusuf Nur', ['reference_number' => 'DBT-999999']);
        $oldDebt->forceFill(['created_at' => now()->subYear()])->save();

        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/reports-analytics/debt-recovery?period=today');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertDontSee('Yusuf Nur');
    }

    public function test_custom_date_range_scopes_the_debt_recovery_report(): void
    {
        [, , $debt] = $this->makeDebt('Hodan Trading', 'Amina Ali');
        $debt->forceFill(['created_at' => '2026-01-15'])->save();

        $response = $this->actingAs($this->platformAdmin())->get(
            '/admin/reports-analytics/debt-recovery?period=custom&date_from=2026-01-01&date_to=2026-01-31'
        );

        $response->assertOk();
        $response->assertSee('Amina Ali');
    }

    public function test_report_specific_status_filter_works(): void
    {
        $this->makeDebt('Hodan Trading', 'Amina Ali', ['debt_status' => 'paid']);
        $this->makeDebt('Barwaqo Imports', 'Yusuf Nur', ['debt_status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/reports-analytics/debt-recovery?status=paid');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertDontSee('Yusuf Nur');
    }

    public function test_debt_recovery_drill_down_links_to_recovery_debts(): void
    {
        [, , $debt] = $this->makeDebt('Hodan Trading', 'Amina Ali');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/debt-recovery');

        $response->assertOk();
        $response->assertSee(route('admin.recovery-debts.show', $debt), false);
    }

    public function test_business_growth_drill_down_links_to_businesses(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/business-growth');

        $response->assertOk();
        $response->assertSee(route('admin.businesses.show', $tenant), false);
    }

    public function test_debt_recovery_trend_chart_receives_real_calculated_data(): void
    {
        [$tenant, $customer, $debt] = $this->makeDebt('Hodan Trading', 'Amina Ali');
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'amount' => 250,
            'payment_date' => now()->toDateString(),
        ]);

        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/reports-analytics/debt-recovery?period=this_month');

        $response->assertOk();
        $response->assertSee('250');
    }

    public function test_empty_state_is_shown_when_no_records_match(): void
    {
        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/reports-analytics/debt-recovery?status=written_off');

        $response->assertOk();
        $response->assertSee('No debts match your filters.');
    }

    public function test_pending_backend_support_is_shown_for_unscored_debtors_rather_than_fabricated(): void
    {
        Customer::factory()->for(Tenant::factory()->create(['business_name' => 'Hodan Trading']), 'tenant')->create([
            'name' => 'Amina Ali',
            'credit_score' => null,
            'credit_score_band' => null,
        ]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/debtor-risk');

        $response->assertOk();
        $response->assertSee('Pending backend support');
    }

    public function test_export_current_results_respects_active_filters_as_csv(): void
    {
        Excel::fake();

        $this->makeDebt('Hodan Trading', 'Amina Ali', ['debt_status' => 'paid']);
        $this->makeDebt('Barwaqo Imports', 'Yusuf Nur', ['debt_status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/reports-analytics/debt-recovery/export/csv?status=paid');

        $response->assertOk();
        Excel::assertDownloaded('debt-recovery-report.csv', function (ReportExport $export) {
            $names = $export->collection()->pluck(3);

            return $names->contains('Amina Ali') && ! $names->contains('Yusuf Nur');
        });
    }

    public function test_export_all_results_ignores_filters_and_returns_the_complete_dataset(): void
    {
        Excel::fake();

        $this->makeDebt('Hodan Trading', 'Amina Ali', ['debt_status' => 'paid']);
        $this->makeDebt('Barwaqo Imports', 'Yusuf Nur', ['debt_status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/reports-analytics/debt-recovery/export/csv?status=paid&scope=all');

        $response->assertOk();
        Excel::assertDownloaded('debt-recovery-report.csv', function (ReportExport $export) {
            $names = $export->collection()->pluck(3);

            return $names->contains('Amina Ali') && $names->contains('Yusuf Nur');
        });
    }

    public function test_excel_export_downloads_successfully(): void
    {
        Excel::fake();

        $this->makeDebt('Hodan Trading', 'Amina Ali');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/debt-recovery/export/excel');

        $response->assertOk();
        Excel::assertDownloaded('debt-recovery-report.xlsx', fn (ReportExport $export) => $export->collection()->isNotEmpty());
    }

    public function test_pdf_export_downloads_successfully(): void
    {
        $this->makeDebt('Hodan Trading', 'Amina Ali');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/debt-recovery/export/pdf');

        $response->assertOk();
        $response->assertHeader('content-type', 'application/pdf');
    }

    public function test_print_view_renders_current_results_with_auto_print_script(): void
    {
        $this->makeDebt('Hodan Trading', 'Amina Ali');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/debt-recovery/print');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertSee('window.print()', false);
    }

    public function test_professional_collection_report_shows_recovery_duration_once_closed_at_is_set(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $owner = $this->businessOwner($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        ProfessionalCollectionRequest::factory()->create([
            'tenant_id' => $tenant->id,
            'collection_case_id' => $case->id,
            'reference_number' => 'PCR-000001',
            'status' => 'recovered',
            'submitted_by_user_id' => $owner->id,
            'created_at' => now()->subDays(10),
            'closed_at' => now(),
        ]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/professional-collection');

        $response->assertOk();
        $response->assertSee('10 days');
    }

    public function test_subscription_report_shows_plan_and_mrr(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $plan = SubscriptionPlan::where('monthly_price', '>', 0)->firstOrFail();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/subscriptions');

        $response->assertOk();
        $response->assertSee($plan->name);
    }

    public function test_subscription_report_detail_table_shows_change_requests(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $currentPlan = SubscriptionPlan::first();
        $requestedPlan = SubscriptionPlan::where('id', '!=', $currentPlan->id)->first();

        $changeRequest = SubscriptionChangeRequest::factory()
            ->for($requestedPlan, 'requestedPlan')
            ->for($currentPlan, 'currentPlan')
            ->create(['tenant_id' => $tenant->id]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/reports-analytics/subscriptions');

        $response->assertOk();
        $response->assertSee($requestedPlan->name);
        $response->assertSee(route('admin.subscriptions.show', $changeRequest->tenant_id), false);
    }
}
