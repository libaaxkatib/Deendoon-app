<?php

namespace Database\Factories;

use App\Models\SubscriptionChangeRequest;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SubscriptionChangeRequest>
 *
 * `tenant_id`/`requested_plan_id`/`current_plan_id` are deliberately not
 * defaulted here — always set explicitly via `->create(['tenant_id' =>
 * ...])`/`->for()` in tests, matching every other factory in this codebase.
 */
class SubscriptionChangeRequestFactory extends Factory
{
    protected $model = SubscriptionChangeRequest::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'status' => 'pending',
            'requested_at' => now(),
        ];
    }
}
