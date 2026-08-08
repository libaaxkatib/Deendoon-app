<?php

namespace Database\Factories;

use App\Models\SubscriptionChangeRequestRejectionReason;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SubscriptionChangeRequestRejectionReason>
 */
class SubscriptionChangeRequestRejectionReasonFactory extends Factory
{
    protected $model = SubscriptionChangeRequestRejectionReason::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'reason_label' => $this->faker->randomElement(['Payment Not Verified', 'Insufficient Payment Amount', 'Duplicate Request']),
        ];
    }
}
