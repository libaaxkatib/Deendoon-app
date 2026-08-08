<?php

namespace Database\Factories;

use App\Models\ProfessionalCollectionRequestReason;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfessionalCollectionRequestReason>
 */
class ProfessionalCollectionRequestReasonFactory extends Factory
{
    protected $model = ProfessionalCollectionRequestReason::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'reason_label' => $this->faker->randomElement(['Non-payment', 'Broken Promise', 'Unresponsive Customer']),
        ];
    }
}
