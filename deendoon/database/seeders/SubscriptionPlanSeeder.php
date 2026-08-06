<?php

namespace Database\Seeders;

use App\Models\SubscriptionPlan;
use Illuminate\Database\Seeder;

/**
 * Backend Completion Roadmap, Phase 3.5 (Product Owner decision): the 5
 * approved Subscription Plans, with their exact approved limits/pricing.
 * `updateOrCreate` keyed by `name` (unique — Phase 3.1 schema), matching
 * MessageTemplateSeeder's established idempotency pattern: re-running
 * this seeder refreshes values rather than creating duplicates, safe
 * here for the same reason it's safe there — there is no plan-editing
 * UI, so no row can have been hand-customized away from these values.
 *
 * `customer_limit` is omitted (stays null, its column default) for
 * Trial and Corporate — the approved "Unlimited customers" — never a
 * magic number.
 */
class SubscriptionPlanSeeder extends Seeder
{
    /**
     * @return array<int, array{name: string, monthly_price: float, customer_limit: int|null, storage_limit: int, analytics_enabled: bool}>
     */
    private function plans(): array
    {
        return [
            [
                'name' => 'Trial',
                'monthly_price' => 0,
                'customer_limit' => null,
                'storage_limit' => 10,
                'analytics_enabled' => true,
            ],
            [
                'name' => 'Free',
                'monthly_price' => 0,
                'customer_limit' => 2,
                'storage_limit' => 10,
                'analytics_enabled' => false,
            ],
            [
                'name' => 'Small Business',
                'monthly_price' => 5,
                'customer_limit' => 110,
                'storage_limit' => 25,
                'analytics_enabled' => true,
            ],
            [
                'name' => 'Medium Business',
                'monthly_price' => 8,
                'customer_limit' => 250,
                'storage_limit' => 50,
                'analytics_enabled' => true,
            ],
            [
                'name' => 'Corporate',
                'monthly_price' => 20,
                'customer_limit' => null,
                'storage_limit' => 100,
                'analytics_enabled' => true,
            ],
        ];
    }

    public function run(): void
    {
        foreach ($this->plans() as $plan) {
            SubscriptionPlan::updateOrCreate(
                ['name' => $plan['name']],
                [
                    'monthly_price' => $plan['monthly_price'],
                    'customer_limit' => $plan['customer_limit'],
                    'storage_limit' => $plan['storage_limit'],
                    'analytics_enabled' => $plan['analytics_enabled'],
                    'active' => true,
                ],
            );
        }
    }
}
