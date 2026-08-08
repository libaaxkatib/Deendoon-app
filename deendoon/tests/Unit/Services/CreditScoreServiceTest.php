<?php

namespace Tests\Unit\Services;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\ProfessionalCollectionRequest;
use App\Models\PromiseToPay;
use App\Models\SystemSetting;
use App\Models\Tenant;
use App\Services\CreditScoreService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Business Owner Backend Completion (pre-Phase 5) — direct coverage of
 * CreditScoreService against the Product Owner-approved formula: an exact
 * sign-inversion of RiskLevelService's already-approved point values (same
 * qualifying events, opposite direction), baseline 70, clamped [0, 100],
 * bands 90-100 Excellent / 75-89 Good / 50-74 Fair / 0-49 Poor. No HTTP
 * layer involved — every test builds database state directly via
 * factories, mirroring RiskLevelServiceTest's own structure and covering
 * the same event catalog from the Credit Score side.
 */
class CreditScoreServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): CreditScoreService
    {
        return app(CreditScoreService::class);
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

    public function test_a_customer_with_no_events_is_scored_at_baseline_and_written_once(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $this->debt($tenant, $customer);

        $this->service()->recalculate($customer);

        $customer->refresh();
        $this->assertSame(70, $customer->credit_score);
        $this->assertSame('fair', $customer->credit_score_band);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated', 'user_id' => null,
        ]);
    }

    public function test_recalculate_is_a_no_op_when_the_score_and_band_do_not_change(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_score' => 70, 'credit_score_band' => 'fair']);
        $this->debt($tenant, $customer);

        $this->service()->recalculate($customer);

        $this->assertDatabaseMissing('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated',
        ]);
    }

    public function test_recalculate_writes_again_once_the_score_actually_changes(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_score' => 70, 'credit_score_band' => 'fair']);
        $debt = $this->debt($tenant, $customer);

        // 1 recovered debt (+20) = 90 -> Excellent, a real change.
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);
        $debt->delete();

        $this->service()->recalculate($customer);

        $this->assertSame('excellent', $customer->fresh()->credit_score_band);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated', 'tenant_id' => $tenant->id,
        ]);
    }

    // --- Primary events, one at a time (exact sign-inversion of Risk Level's) ---

    public function test_broken_promise_to_pay_subtracts_15_points_per_occurrence(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 1 broken promise = 70-15 = 55 -> Fair, proving the exact
        // per-occurrence value rather than only a band boundary.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame(55, $customer->fresh()->credit_score);
        $this->assertSame('fair', $customer->fresh()->credit_score_band);
    }

    public function test_fulfilled_promise_to_pay_adds_10_points_per_occurrence(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 1 fulfilled promise = 70+10 = 80 -> Good.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'status' => 'fulfilled', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame(80, $customer->fresh()->credit_score);
        $this->assertSame('good', $customer->fresh()->credit_score_band);
    }

    public function test_debt_recovered_adds_20_points_per_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);

        // 2 recovered debts = 70+40 = 100, clamped -> Excellent.
        $this->service()->recalculate($customer);

        $this->assertSame(100, $customer->fresh()->credit_score);
        $this->assertSame('excellent', $customer->fresh()->credit_score_band);
    }

    // --- Repeated Missed Commitments: rolling 12-month window ---

    public function test_repeated_missed_commitments_subtracts_20_once_3_broken_promises_fall_within_12_months(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 3 broken (-45) + Repeated Missed Commitments (-20) = 70-65 = 5 -> Poor.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(6),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame(5, $customer->fresh()->credit_score);
        $this->assertSame('poor', $customer->fresh()->credit_score_band);
    }

    public function test_repeated_missed_commitments_does_not_apply_below_3_within_the_window(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // Only 2 broken within 12 months = 70-30 = 40, no -20 -> Poor either
        // way, so assert the exact score to prove the -20 didn't apply.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(2)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(6),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame(40, $customer->fresh()->credit_score);
    }

    public function test_repeated_missed_commitments_ages_off_once_broken_promises_fall_outside_12_months(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 3 broken promises resolved 13 months ago: still -45 (lifetime),
        // but the rolling-window -20 no longer applies -> 70-45 = 25.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(13),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame(25, $customer->fresh()->credit_score);
    }

    // --- Sustained Positive Repayment Behavior: unbroken streak of 3 ---

    public function test_sustained_positive_repayment_behavior_adds_15_for_an_unbroken_streak_of_3(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 3 fulfilled (+30) + streak bonus (+15) = 70+45 = 100 (clamped),
        // still proves the bonus applied since 3 fulfilled alone would be 100 too
        // -- combine with a broken promise to keep it under the clamp ceiling.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(13),
        ]);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create([
            'status' => 'fulfilled', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        // -15 (broken) + 30 (3 fulfilled) + 15 (streak) = 30 -> 70+30 = 100.
        $this->assertSame(100, $customer->fresh()->credit_score);
    }

    public function test_sustained_positive_repayment_behavior_does_not_apply_if_the_streak_is_broken(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);

        // 2 fulfilled then the most recent is broken: streak not unbroken,
        // so the +15 bonus must NOT apply.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(2)->create([
            'status' => 'fulfilled', 'resolved_at' => now()->subDays(2),
        ]);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        // 20 (2 fulfilled) - 15 (broken) = 5 -> 70+5 = 75, not 90 (which the
        // +15 bonus would incorrectly produce).
        $this->assertSame(75, $customer->fresh()->credit_score);
    }

    // --- Long Outstanding Debt: configurable System Setting ---

    public function test_long_outstanding_debt_uses_the_default_90_day_threshold_when_unconfigured(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $this->debt($tenant, $customer, ['due_date' => now()->subDays(91)->toDateString(), 'remaining_balance' => 100]);

        $this->service()->recalculate($customer);

        // -12 only -> 70-12 = 58, confirms the event fired under the
        // default (no system_settings row exists for this tenant yet).
        $this->assertSame(58, $customer->fresh()->credit_score);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated']);
    }

    public function test_long_outstanding_debt_does_not_apply_before_the_default_90_day_threshold(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_score' => 70, 'credit_score_band' => 'fair']);
        $this->debt($tenant, $customer, ['due_date' => now()->subDays(89)->toDateString(), 'remaining_balance' => 100]);

        $this->service()->recalculate($customer);

        $this->assertDatabaseMissing('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated']);
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

        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated']);
    }

    public function test_long_outstanding_debt_does_not_qualify_once_remaining_balance_reaches_zero(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_score' => 90, 'credit_score_band' => 'excellent']);
        $this->debt($tenant, $customer, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 0, 'debt_status' => 'paid']);

        $this->service()->recalculate($customer);

        // Paid off -> Debt Recovered (+20) only, clamped to 100 -> still
        // Excellent (unchanged), and specifically not scored again as Long
        // Outstanding Debt (which would otherwise have offset it to 88).
        $this->assertDatabaseMissing('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated']);
    }

    // --- Secondary events (exact sign-inversion) ---

    public function test_recovery_stage_advancement_subtracts_3_points_per_stage_above_1(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        // Stage 4 = 3 advancements above the baseline (stage 1) = -9.
        $this->debt($tenant, $customer, ['recovery_stage' => 4]);

        $this->service()->recalculate($customer);

        $this->assertSame(61, $customer->fresh()->credit_score);
    }

    public function test_collection_case_created_subtracts_5_points_per_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(2)->create();

        $this->service()->recalculate($customer);

        // 2 cases = -10 -> 60.
        $this->assertSame(60, $customer->fresh()->credit_score);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated']);
    }

    public function test_collection_case_closure_has_no_scoring_effect(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_score' => 65, 'credit_score_band' => 'fair']);
        $debt = $this->debt($tenant, $customer);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->closed()->create();

        $this->service()->recalculate($customer);

        // The -5 for the case's mere existence still applies; only the
        // closure itself contributes nothing extra.
        $this->assertSame(65, $customer->fresh()->credit_score);
    }

    public function test_professional_collection_request_submitted_subtracts_5_points_per_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->create(['tenant_id' => $tenant->id]);

        $this->service()->recalculate($customer);

        // Case (-5) + Submitted (-5) = 70-10 = 60.
        $this->assertSame(60, $customer->fresh()->credit_score);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'credit_score_recalculated']);
    }

    public function test_professional_collection_request_recovered_nets_to_zero_against_its_own_submitted_points(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        // 4 broken, outside the 12-month window (no Repeated Missed bonus) = -60.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(4)->create(['status' => 'broken', 'resolved_at' => now()->subMonths(13)]);
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->create(['tenant_id' => $tenant->id, 'status' => 'recovered']);

        $this->service()->recalculate($customer);

        // Secondary = Case Created (-5) + [Submitted (-5) - Recovered (+5) = 0] = -5.
        // -60 Primary - 5 Secondary = -65. 70-65 = 5 -> Poor.
        $this->assertSame(5, $customer->fresh()->credit_score);
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

        // Secondary = Case Created (-5) + Submitted (-5, 'closed' isn't
        // 'recovered' so no +5) = -10. -60 Primary - 10 Secondary = -70.
        // 70-70 = 0 -> Poor, distinguishing this from the 'recovered' case
        // above (score 5) purely via the +5 Completed-Successfully offset.
        $this->assertSame(0, $customer->fresh()->credit_score);
    }

    // --- Secondary Cap [-15, +15] ---

    public function test_secondary_events_are_capped_at_negative_15(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        // Stage 6 (5 advancements = -15) + 3 cases (-15) = -30 uncapped,
        // clamped to -15. With zero Primary, final score must be exactly
        // 55, not 40 (which the uncapped -30 would produce).
        $debt = $this->debt($tenant, $customer, ['recovery_stage' => 6]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(3)->create();

        $this->service()->recalculate($customer);

        $this->assertSame(55, $customer->fresh()->credit_score);
    }

    /**
     * Mirrors RiskLevelServiceTest's documented known limitation, inverted:
     * under the currently-approved Secondary Event catalog, every "recovered"
     * PCR was necessarily "submitted" first, so PCR Submitted's count always
     * >= PCR Recovered's count, keeping that pair's net contribution <= 0;
     * Recovery Stage Advancement and Collection Case Created are both <= 0
     * by construction; and Collection Case Closure contributes nothing.
     * No combination of currently-approved events can drive secondarySubtotal
     * above 0 — this documents that ceiling rather than asserting a +15
     * clamp no combination of real events can trigger.
     */
    public function test_secondary_subtotal_cannot_go_positive_under_the_current_event_catalog(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        ProfessionalCollectionRequest::factory()->for($case, 'collectionCase')->count(5)->create([
            'tenant_id' => $tenant->id, 'status' => 'recovered',
        ]);

        $this->service()->recalculate($customer);

        // Secondary = Case Created (-5) + 5x[Submitted (-5) - Recovered
        // (+5) = 0] = -5, not positive. Zero Primary - 5 Secondary = -5.
        // 70-5 = 65 -> Fair.
        $this->assertSame(65, $customer->fresh()->credit_score);
    }

    // --- Score clamping [0, 100] ---

    public function test_score_never_goes_below_zero(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer);
        // 10 broken promises = -150 raw, 70-150 clamped to 0 -> Poor, not a
        // negative number/crash.
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(10)->create([
            'status' => 'broken', 'resolved_at' => now(),
        ]);

        $this->service()->recalculate($customer);

        $this->assertSame(0, $customer->fresh()->credit_score);
        $this->assertSame('poor', $customer->fresh()->credit_score_band);
    }

    public function test_score_never_exceeds_100(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        // 10 recovered debts = +200 raw, 70+200 clamped to 100 -> Excellent.
        for ($i = 0; $i < 10; $i++) {
            $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);
        }

        $this->service()->recalculate($customer);

        $this->assertSame(100, $customer->fresh()->credit_score);
        $this->assertSame('excellent', $customer->fresh()->credit_score_band);
    }

    // --- Band boundaries ---

    public function test_score_of_50_is_fair_and_49_is_poor(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);

        // 1 Long Outstanding Debt (-12) + 1 Collection Case Created (-5) +
        // 1 Recovery Stage Advancement (-3) = -20. 70-20 = 50 -> Fair.
        $atFair = $this->customer($tenant);
        $fairDebt = $this->debt($tenant, $atFair, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 100, 'recovery_stage' => 2]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($fairDebt, 'debt')->create();

        $this->service()->recalculate($atFair);
        $this->assertSame(50, $atFair->fresh()->credit_score);
        $this->assertSame('fair', $atFair->fresh()->credit_score_band);

        // 1 Long Outstanding Debt (-12) + Recovery Stage Advancement to
        // stage 4 (3 advancements, -9) = -21. 70-21 = 49 -> Poor.
        $atPoor = $this->customer($tenant);
        $this->debt($tenant, $atPoor, ['due_date' => now()->subDays(200)->toDateString(), 'remaining_balance' => 100, 'recovery_stage' => 4]);

        $this->service()->recalculate($atPoor);
        $this->assertSame(49, $atPoor->fresh()->credit_score);
        $this->assertSame('poor', $atPoor->fresh()->credit_score_band);
    }

    public function test_score_of_75_is_good_and_74_is_fair(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);

        // 1 Fulfilled Promise (+10) + 1 Collection Case Created (-5) = +5.
        // 70+5 = 75 -> Good.
        $atGood = $this->customer($tenant);
        $goodDebt = $this->debt($tenant, $atGood);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($goodDebt, 'debt')->create(['status' => 'fulfilled', 'resolved_at' => now()]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($goodDebt, 'debt')->create();

        $this->service()->recalculate($atGood);
        $this->assertSame(75, $atGood->fresh()->credit_score);
        $this->assertSame('good', $atGood->fresh()->credit_score_band);

        // 1 Fulfilled Promise (+10) + Recovery Stage Advancement to stage 3
        // (2 advancements, -6) = +4. 70+4 = 74 -> Fair.
        $atFair = $this->customer($tenant);
        $fairDebt = $this->debt($tenant, $atFair, ['recovery_stage' => 3]);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($fairDebt, 'debt')->create(['status' => 'fulfilled', 'resolved_at' => now()]);

        $this->service()->recalculate($atFair);
        $this->assertSame(74, $atFair->fresh()->credit_score);
        $this->assertSame('fair', $atFair->fresh()->credit_score_band);
    }

    public function test_score_of_90_is_excellent(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        // 1 recovered debt (+20) alone = 70+20 = 90 -> Excellent.
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);

        $this->service()->recalculate($customer);

        $this->assertSame(90, $customer->fresh()->credit_score);
        $this->assertSame('excellent', $customer->fresh()->credit_score_band);
    }

    public function test_a_representative_good_band_score(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant);
        $debt = $this->debt($tenant, $customer, ['debt_status' => 'paid', 'remaining_balance' => 0]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->count(2)->create();

        // Recovered (+20) - 2 cases (-10) = +10. 70+10 = 80 -> Good.
        $this->service()->recalculate($customer);

        $this->assertSame(80, $customer->fresh()->credit_score);
        $this->assertSame('good', $customer->fresh()->credit_score_band);
    }

    // --- Batch entry point parity (recalculateForMany) ---

    public function test_recalculate_for_many_matches_recalculate_for_each_customer_individually(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);

        $fair = $this->customer($tenant);
        $this->debt($tenant, $fair);

        $poor = $this->customer($tenant);
        $poorDebt = $this->debt($tenant, $poor);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($poorDebt, 'debt')->count(3)->create([
            'status' => 'broken', 'resolved_at' => now()->subMonths(6),
        ]);

        $excellent = $this->customer($tenant);
        $this->debt($tenant, $excellent, ['debt_status' => 'paid', 'remaining_balance' => 0]);
        $this->debt($tenant, $excellent, ['debt_status' => 'paid', 'remaining_balance' => 0]);

        $this->service()->recalculateForMany(collect([$fair, $poor, $excellent]));

        $this->assertSame('fair', $fair->fresh()->credit_score_band);
        $this->assertSame('poor', $poor->fresh()->credit_score_band);
        $this->assertSame('excellent', $excellent->fresh()->credit_score_band);
    }

    public function test_recalculate_for_many_is_a_no_op_for_an_empty_collection(): void
    {
        $this->service()->recalculateForMany(collect());

        $this->addToAssertionCount(1);
    }
}
