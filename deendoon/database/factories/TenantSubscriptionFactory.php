<?php

namespace Database\Factories;

use App\Models\TenantSubscription;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TenantSubscription>
 *
 * `tenant_id`/`plan_id` are deliberately not defaulted here, matching
 * every other factory in this codebase (CustomerFactory, DebtFactory,
 * ProfessionalCollectionRequestFactory) — always set explicitly via
 * `->for($tenant, 'tenant')`/`->for($plan, 'plan')` in tests.
 */
class TenantSubscriptionFactory extends Factory
{
    protected $model = TenantSubscription::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'status' => 'trialing',
            'started_at' => now(),
            'trial_started_at' => now(),
            'trial_ends_at' => now()->addDays(7),
        ];
    }

    public function active(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'active',
            'trial_started_at' => null,
            'trial_ends_at' => null,
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'expired',
            'trial_started_at' => null,
            'trial_ends_at' => null,
            'expires_at' => now()->subDay(),
        ]);
    }
}
