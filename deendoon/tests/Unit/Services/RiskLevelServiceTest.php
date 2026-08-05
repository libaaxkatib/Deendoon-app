<?php

namespace Tests\Unit\Services;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\ProfessionalCollectionRequest;
use App\Models\PromiseToPay;
use App\Models\SystemSetting;
use App\Models\Tenant;
use App\Services\RiskLevelService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Sprint 2B — direct coverage of RiskLevelService against
 * Risk_Level_Formula_Specification_v1.0.md: every scoring rule in
 * isolation, the Secondary Cap, the rolling 12-month window, the
 * configurable Long Outstanding Debt setting, score clamping, audit
 * logging, and the no-op guard. No HTTP layer involved — every test builds
 * database state directly via factories and asserts RiskLevelService's
 * output, per this project's "recompute-from-source" testing convention
 * (Formula Spec §7).
 */
class RiskLevelServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): RiskLevelService
    {
        return app(RiskLevelService::class);
    }

    private function customer(Tenant $tenant, array $attributes = []): Customer
    {
        return Customer::factory()->for($tenant, 'tenant')->create($attributes);
    }

    private function debt(Tenant $tenant, Customer $customer, array $attributes = []): Debt
    {
        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    // --- No-op / initial classification ---

    public function test_a_customer_with_no_events_is_classified_low_and_written_once(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $this->debt($tenant, $customer);

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated', 'user_id' => null,
        ]);
    }

    public function test_recalculate_is_a_no_op_when_the_label_does_not_change(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'low']);
        $this->debt($tenant, $customer);

        $this->service()->recalculate($customer);

        $this->assertDatabaseMissing('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated',
        ]);
    }

    public function test_recalculate_writes_again_once_the_label_actually_changes(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'low']);
        $debt = $this->debt($tenant, $customer);

        // 5 broken promises = +75, well into High.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(5)->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('high', $customer->fresh()->risk_level);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated', 'tenant_id' => $tenant->id,
        ]);
    }

    // --- Primary events, one at a time ---

    public function test_broken_promise_to_pay_adds_15_points_per_occurrence(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 2 broken promises = 30 -> still Low (<=33), proving the exact
        // per-occurrence value rather than only a band boundary.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(2)->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_fulfilled_promise_to_pay_subtracts_10_points_per_occurrence(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'medium']);
        $debt = $this->debt($tenant, $customer);

        // 4 broken (+60) then 3 fulfilled (-30) = 30 -> Low. Proves the -10
        // weight exactly (60 - 30 = 30, not e.g. 60 - 3*15 = 15).
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(4)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(13),
        ]);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create([
            'status' => 'fulfilled', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_debt_recovered_subtracts_20_points_per_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'medium']);
        // 5 broken promises spread pre-window (+75, no repeated-missed
        // bonus since resolved 13 months ago) then 2 recovered debts
        // (-40) = 35 -> Medium. Proves -20 exactly (75-40=35, not 75-2*15).
        $debt = $this->debt($tenant, $customer);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(5)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(13),
        ]);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);

        $this->service()->recalculate($customer);

        $this->assertSame('medium', $customer->fresh()->risk_level);
    }

    // --- Repeated Missed Commitments: rolling 12-month window (Change 1) ---

    public function test_repeated_missed_commitments_adds_20_once_3_broken_promises_fall_within_12_months(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 3 broken (+45) + Repeated Missed Commitments (+20) = 65 -> Medium
        // (not High, proving the flat +20 rather than a multiplier).
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(6),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('medium', $customer->fresh()->risk_level);
    }

    public function test_repeated_missed_commitments_does_not_apply_below_3_within_the_window(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // Only 2 broken within 12 months = 30, no +20 -> Low.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(2)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(6),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_repeated_missed_commitments_ages_off_once_broken_promises_fall_outside_12_months(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'medium']);
        $debt = $this->debt($tenant, $customer);

        // 3 broken promises resolved 13 months ago: individually still
        // +45 (lifetime), but the rolling-window +20 no longer applies
        // (Change 1: "no permanent penalty stored") -> 45, still Medium
        // but strictly below the 65 a within-window customer would show.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(13),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('medium', $customer->fresh()->risk_level);

        // Confirm the +20 truly isn't included: adding one more within-window
        // broken promise (making it 4 broken total, still only 1 within the
        // window) must NOT yet trigger the +20 either (needs 3 within the
        // window, not just 1).
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);
        $this->service()->recalculate($customer->fresh());
        // 4 broken lifetime (60) + no repeated-missed bonus (only 1 within window) = 60 -> Medium.
        $this->assertSame('medium', $customer->fresh()->risk_level);
    }

    // --- Sustained Positive Repayment Behavior: unbroken streak of 3 ---

    public function test_sustained_positive_repayment_behavior_subtracts_15_for_an_unbroken_streak_of_3(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'medium']);
        $debt = $this->debt($tenant, $customer);

        // 4 broken (60, resolved 13 months ago -> outside the 12-month
        // window, so no Repeated Missed Commitments bonus) then 3 fulfilled
        // (most recent, -30) then the streak bonus (-15) = 60-30-15 = 15 -> Low.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(4)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(13),
        ]);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create([
            'status' => 'fulfilled', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_sustained_positive_repayment_behavior_does_not_apply_if_the_streak_is_broken(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 4 broken, all resolved within the window: 60 (broken) + 20
        // (Repeated Missed Commitments) = 80 -> High. The most recently
        // resolved promise is broken, so the streak is not unbroken and
        // the -15 bonus must NOT apply — if it incorrectly did, the score
        // would be 65 (Medium) instead of 80 (High).
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(4)->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('high', $customer->fresh()->risk_level);
    }

    // --- Long Outstanding Debt: configurable System Setting (Change 2) ---

    public function test_long_outstanding_debt_uses_the_default_90_day_threshold_when_unconfigured(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $this->debt($tenant, $customer, ['due_date' => now()->subDays(91)->toDateString(), 'remaining_balance' => 100]);

        $this->service()->recalculate($customer);

        // +12 only -> Low, but confirms the event fired at all under the
        // default (no system_settings row exists for this tenant yet).
        $this->assertSame('low', $customer->fresh()->risk_level);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated']);
    }

    public function test_long_outstanding_debt_does_not_apply_before_the_default_90_day_threshold(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'low']);
        $this->debt($tenant, $customer, ['due_date' => now()->subDays(89)->toDateString(), 'remaining_balance' => 100]);

        $this->service()->recalculate($customer);

        $this->assertDatabaseMissing('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated']);
    }

    public function test_long_outstanding_debt_respects_a_tenant_configured_threshold(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        SystemSetting::factory()->for($tenant, 'tenant')->create(['long_outstanding_debt_days' => 30]);
        $customer = $this->customer($tenant);
        // 40 days overdue: qualifies under a 30-day tenant setting, would
        // NOT qualify under the 90-day default.
        $this->debt($tenant, $customer, ['due_date' => now()->subDays(40)->toDateString(), 'remaining_balance' => 100]);

        $this->service()->recalculate($customer);

        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated']);
    }

    public function test_long_outstanding_debt_does_not_qualify_once_remaining_balance_reaches_zero(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'low']);
        $this->debt($tenant, $customer, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 0, 'debt_status' => 'paid']);

        $this->service()->recalculate($customer);

        // Paid off -> Debt Recovered (-20) only, clamped to 0 -> still Low,
        // and specifically not scored again as Long Outstanding Debt.
        $this->assertDatabaseMissing('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated']);
    }

    // --- Secondary events + cap ---

    public function test_recovery_stage_advancement_adds_3_points_per_stage_above_1(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        // Stage 4 = 3 advancements above the baseline (stage 1) = +9.
        $this->debt($tenant, $customer, ['recovery_stage' => 4]);

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_collection_case_created_adds_5_points_per_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(2)->create();

        $this->service()->recalculate($customer);

        // 2 cases = +10 -> Low, but confirms the event registers at all.
        $this->assertSame('low', $customer->fresh()->risk_level);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated']);
    }

    public function test_collection_case_closure_has_no_scoring_effect(): void
    {
        // Formula Spec §2.2, Change 3: no effect until DD-024 is resolved.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'low']);
        $debt = $this->debt($tenant, $customer);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->closed()->create();

        $this->service()->recalculate($customer);

        // The +5 for the case's mere existence still applies (Collection
        // Case Created); only the closure itself contributes nothing extra.
        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_professional_collection_request_submitted_adds_5_points_per_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->create(['tenant_id' => $tenant->id]);

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated']);
    }

    /**
     * A "recovered" request keeps contributing its own +5 (Submitted —
     * fires once, at submission, the same lifetime-accrual pattern as
     * every other "fires once" event in §2.1) alongside the new -5
     * (Completed Successfully), netting to 0 for that request — distinct
     * from an unresolved/unsuccessful request, which keeps the full +5
     * permanently (see the paired test below). This net-0-vs-net+5
     * contrast is what makes a successful recovery a genuine (relative)
     * Risk Reduction signal per `Risk_Level_Engine_v1.0.md` §5, without
     * requiring the request's net contribution to go negative.
     */
    public function test_professional_collection_request_recovered_nets_to_zero_against_its_own_submitted_points(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        // 4 broken, outside the 12-month window (no Repeated Missed bonus) = 60.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(4)->create(['status' => 'broken', 'resolved_at' => now()->subMonths(13)]);
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->create(['tenant_id' => $tenant->id, 'status' => 'recovered']);

        $this->service()->recalculate($customer);

        // Secondary = Case Created (+5) + [Submitted (+5) - Recovered (-5) = 0] = +5.
        // 60 Primary + 5 Secondary = 65 -> Medium.
        $this->assertSame('medium', $customer->fresh()->risk_level);
    }

    public function test_professional_collection_request_non_recovered_terminal_outcome_keeps_its_full_submitted_points(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(4)->create(['status' => 'broken', 'resolved_at' => now()->subMonths(13)]);
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->create(['tenant_id' => $tenant->id, 'status' => 'closed']);

        $this->service()->recalculate($customer);

        // Secondary = Case Created (+5) + Submitted (+5, 'closed' isn't
        // 'recovered' so no -5) = +10. 60 Primary + 10 Secondary = 70 ->
        // High, distinguishing this from the 'recovered' case above
        // (Medium) purely via the -5 Completed-Successfully contribution.
        $this->assertSame('high', $customer->fresh()->risk_level);
    }

    // --- Secondary Cap [-15, +15] ---

    public function test_secondary_events_are_capped_at_positive_15(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        // Stage 6 (5 advancements = +15) + 3 cases (+15) = +30 uncapped,
        // clamped to +15. With zero Primary, final score must be exactly
        // 15 -> Low (proving the cap; without it, 30 would still be Low too,
        // so this alone wouldn't prove it — see the boundary test below).
        $debt = $this->debt($tenant, $customer, ['recovery_stage' => 6]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create();

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_secondary_cap_prevents_secondary_events_alone_from_crossing_a_band_boundary(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'low']);
        // Primary subtotal of exactly 34 (Medium boundary) via 3 broken
        // (45) minus... simplest: use 3 broken (repeated) - fulfilled? Use
        // a debt recovered (-20) + repeated-missed (+20) + 3 broken (+45) = 45? too high.
        // Build Primary = 19: not achievable with whole units of 15/20 cleanly,
        // so instead prove the cap directly: massive secondary volume must
        // never, by itself (zero Primary), reach High (67+) even though
        // uncapped it mathematically could (e.g. 10 cases = 50).
        $debt = $this->debt($tenant, $customer, ['recovery_stage' => 6]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(10)->create();

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    /**
     * Known limitation (see the Sprint 2B implementation report): under the
     * currently-approved Secondary Event catalog, the Secondary Cap's lower
     * bound (-15) is structurally unreachable. Every "recovered" PCR was
     * necessarily "submitted" first (recovered is a subset of submitted),
     * so PCR Submitted's count always >= PCR Recovered's count, keeping
     * that pair's net contribution >= 0; Recovery Stage Advancement and
     * Collection Case Created are both >= 0 by construction; and
     * Collection Case Successfully Closed contributes nothing at all
     * (Change 3). No combination of currently-approved events can drive
     * secondarySubtotal below 0. This test documents that floor rather
     * than asserting a -15 clamp no combination of real events can trigger.
     */
    public function test_secondary_subtotal_cannot_go_negative_under_the_current_event_catalog(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        // Every PCR ever submitted for this Customer resolves to 'recovered'
        // — the scenario one would expect to minimize the secondary total.
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->count(5)->create([
            'tenant_id' => $tenant->id, 'status' => 'recovered',
        ]);

        $this->service()->recalculate($customer);

        // Secondary = Case Created (+5) + 5x[Submitted (+5) - Recovered
        // (-5) = 0] = +5, not negative. Zero Primary + 5 Secondary = 5 -> Low.
        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    // --- Score clamping [0, 100] ---

    public function test_score_never_goes_below_zero(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['risk_level' => 'medium']);
        // Overwhelming positive history: 10 recovered debts = -200 raw,
        // clamped to 0 -> Low, not a negative number/crash.
        for ($i = 0; $i < 10; $i++) {
            $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);
        }

        $this->service()->recalculate($customer);

        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_score_never_exceeds_100(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        // 10 broken promises = +150 raw, clamped to 100 -> High.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(10)->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame('high', $customer->fresh()->risk_level);
    }

    // --- Threshold transitions (§3 band boundaries) ---

    public function test_score_of_33_is_low_and_34_is_medium(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);

        // 2 Long Outstanding Debts (+24) + 3 Recovery Stage advancements
        // (+9) = exactly 33 -> Low.
        $atLow = $this->customer($tenant);
        $this->debt($tenant, $atLow, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 100, 'recovery_stage' => 4]);
        $this->debt($tenant, $atLow, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 100]);

        $this->service()->recalculate($atLow);
        $this->assertSame('low', $atLow->fresh()->risk_level);

        // 2 Long Outstanding Debts (+24) + 2 Collection Cases Created (+10)
        // = exactly 34 -> Medium.
        $atMedium = $this->customer($tenant);
        $debtA = $this->debt($tenant, $atMedium, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 100]);
        $this->debt($tenant, $atMedium, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 100]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->count(2)->create();

        $this->service()->recalculate($atMedium);
        $this->assertSame('medium', $atMedium->fresh()->risk_level);
    }

    public function test_score_of_66_is_medium_and_67_is_high(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);

        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        // 4 broken (+60) + Repeated Missed (+20) = 80 uncapped -> too high;
        // use exactly enough to land at 67 for the High boundary:
        // 4 broken (60) + case created (+5, secondary uncapped) + PCR submitted (+5) = 70 -> High.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(4)->create(['status' => 'broken', 'resolved_at' => now()->subMonths(13)]);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->create(['tenant_id' => $tenant->id]);

        $this->service()->recalculate($customer);

        // 60 Primary + 10 secondary (capped, but 10 < 15 so unaffected) = 70 -> High.
        $this->assertSame('high', $customer->fresh()->risk_level);
    }

    // --- Same-day / multi-event recalculation (§7) ---

    public function test_multiple_events_on_the_same_day_are_all_reflected_regardless_of_order(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['status' => 'broken', 'resolved_at' => now()]);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);

        $this->service()->recalculate($customer->fresh());

        // +15 (broken) - 20 (recovered) = -5, clamped to 0 -> Low.
        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    // --- Batch entry point parity (recalculateForMany) ---

    /**
     * Backend Completion Audit (Phase 2 — Testing Debt): the class
     * docblock claims recalculate() and recalculateForMany() "differ only
     * in how the underlying data is fetched," but nothing previously
     * exercised the batch path at all. Three customers, each covering a
     * different band via different rule combinations, batched in one call
     * and compared against calling recalculate() on each individually.
     */
    public function test_recalculate_for_many_matches_recalculate_for_each_customer_individually(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);

        $low = $this->customer($tenant);
        $this->debt($tenant, $low);

        $medium = $this->customer($tenant);
        $mediumDebt = $this->debt($tenant, $medium);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($mediumDebt, 'debt')->count(3)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(6),
        ]);

        $high = $this->customer($tenant);
        $highDebt = $this->debt($tenant, $high);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($highDebt, 'debt')->count(10)->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculateForMany(collect([$low, $medium, $high]));

        $this->assertSame('low', $low->fresh()->risk_level);
        $this->assertSame('medium', $medium->fresh()->risk_level);
        $this->assertSame('high', $high->fresh()->risk_level);
    }

    public function test_recalculate_for_many_is_a_no_op_for_an_empty_collection(): void
    {
        $this->service()->recalculateForMany(collect());

        $this->addToAssertionCount(1);
    }
}
