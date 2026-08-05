<?php

namespace Tests\Unit\Services;

use App\Events\CreditLimitReached;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Services\CustomerBalanceService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

/**
 * Backend Completion Audit (Phase 2 — Testing Debt): direct coverage of
 * CustomerBalanceService against BRL-022 ("Sum of Remaining Balance across
 * all open Debts, where open = not Paid/Cancelled/Written Off; archived
 * debts still count") and FR-028 (Credit Limit Reached). No HTTP layer
 * involved — model state is built directly via factories, matching this
 * project's existing "recompute-from-source" Unit testing convention
 * (see RiskLevelServiceTest).
 */
class CustomerBalanceServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): CustomerBalanceService
    {
        return app(CustomerBalanceService::class);
    }

    private function customer(Tenant $tenant, array $attributes = []): Customer
    {
        return Customer::factory()->for($tenant, 'tenant')->create($attributes);
    }

    private function debt(Tenant $tenant, Customer $customer, array $attributes = []): Debt
    {
        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    // --- Outstanding balance: basic sum ---

    public function test_outstanding_balance_is_the_remaining_balance_of_a_single_open_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);

        $this->service()->recalculate($customer);

        $this->assertSame('500.00', $customer->fresh()->outstanding_balance);
    }

    public function test_outstanding_balance_reflects_a_partial_payment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        // Amount 500, 200 already paid -> remaining_balance 300 (mirrors
        // PaymentService::recalculateDebt()'s amount - totalPaid).
        $this->debt($tenant, $customer, ['debt_status' => 'partial_paid', 'amount' => 500, 'remaining_balance' => 300]);

        $this->service()->recalculate($customer);

        $this->assertSame('300.00', $customer->fresh()->outstanding_balance);
    }

    // --- Terminal statuses excluded entirely (not summed as zero) ---

    public function test_paid_debt_is_excluded_from_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'amount' => 300, 'remaining_balance' => 0]);

        $this->service()->recalculate($customer);

        $this->assertSame('500.00', $customer->fresh()->outstanding_balance);
    }

    public function test_cancelled_debt_is_excluded_from_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);
        $this->debt($tenant, $customer, ['debt_status' => 'cancelled', 'amount' => 300, 'remaining_balance' => 300]);

        $this->service()->recalculate($customer);

        $this->assertSame('500.00', $customer->fresh()->outstanding_balance);
    }

    public function test_written_off_debt_is_excluded_from_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);
        $this->debt($tenant, $customer, ['debt_status' => 'written_off', 'amount' => 300, 'remaining_balance' => 300]);

        $this->service()->recalculate($customer);

        $this->assertSame('500.00', $customer->fresh()->outstanding_balance);
    }

    /**
     * Models what PaymentService::recalculateDebt() actually produces on
     * overpayment: `remaining_balance = amount - totalPaid` is uncapped
     * (DD-016 unresolved, "succeeds unconditionally"), but `debt_status`
     * becomes 'paid' the moment totalPaid >= amount — in the same write.
     * So an overpaid Debt is always excluded by status before its
     * (possibly negative) remaining_balance value could ever be summed.
     */
    public function test_an_overpaid_debt_is_excluded_despite_its_negative_remaining_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'amount' => 300, 'remaining_balance' => -50]);

        $this->service()->recalculate($customer);

        $this->assertSame('500.00', $customer->fresh()->outstanding_balance);
    }

    // --- Multiple debts / multiple open balances ---

    public function test_outstanding_balance_sums_multiple_open_debts_and_ignores_excluded_ones(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);
        $this->debt($tenant, $customer, ['debt_status' => 'partial_paid', 'amount' => 400, 'remaining_balance' => 150]);
        $this->debt($tenant, $customer, ['debt_status' => 'paid', 'amount' => 200, 'remaining_balance' => 0]);
        $this->debt($tenant, $customer, ['debt_status' => 'cancelled', 'amount' => 100, 'remaining_balance' => 100]);

        $this->service()->recalculate($customer);

        $this->assertSame('650.00', $customer->fresh()->outstanding_balance);
    }

    public function test_a_customer_with_no_debts_has_zero_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);

        $this->service()->recalculate($customer);

        $this->assertSame('0.00', $customer->fresh()->outstanding_balance);
    }

    // --- Archived (soft-deleted) debts: BRL-022 Notes, DD-007 ---

    public function test_an_archived_but_non_terminal_debt_still_counts(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $debt = $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);
        $debt->delete();

        $this->service()->recalculate($customer);

        $this->assertSame('500.00', $customer->fresh()->outstanding_balance);
    }

    public function test_an_archived_and_paid_debt_is_still_excluded(): void
    {
        // Archiving does not override the terminal-status exclusion.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 10000]);
        $debt = $this->debt($tenant, $customer, ['debt_status' => 'paid', 'amount' => 500, 'remaining_balance' => 0]);
        $debt->delete();

        $this->service()->recalculate($customer);

        $this->assertSame('0.00', $customer->fresh()->outstanding_balance);
    }

    // --- FR-028: Credit Limit Reached event ---

    public function test_credit_limit_reached_is_dispatched_when_outstanding_balance_meets_the_limit(): void
    {
        Event::fake([CreditLimitReached::class]);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 500]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);

        $this->service()->recalculate($customer);

        Event::assertDispatched(CreditLimitReached::class, fn (CreditLimitReached $event): bool => $event->customer->is($customer));
    }

    public function test_credit_limit_reached_is_dispatched_when_outstanding_balance_exceeds_the_limit(): void
    {
        Event::fake([CreditLimitReached::class]);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 400]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);

        $this->service()->recalculate($customer);

        Event::assertDispatched(CreditLimitReached::class);
    }

    public function test_credit_limit_reached_is_not_dispatched_when_outstanding_balance_is_below_the_limit(): void
    {
        Event::fake([CreditLimitReached::class]);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->customer($tenant, ['credit_limit' => 501]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);

        $this->service()->recalculate($customer);

        Event::assertNotDispatched(CreditLimitReached::class);
    }

    // --- Recompute-from-source: overwrites stale stored state ---

    public function test_recalculate_overwrites_a_stale_stored_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        // Deliberately wrong stored value, proving recalculate() fully
        // recomputes rather than trusting/adjusting the existing column.
        $customer = $this->customer($tenant, ['credit_limit' => 10000, 'outstanding_balance' => 99999]);
        $this->debt($tenant, $customer, ['debt_status' => 'pending', 'amount' => 500, 'remaining_balance' => 500]);

        $this->service()->recalculate($customer);

        $this->assertSame('500.00', $customer->fresh()->outstanding_balance);
    }
}
