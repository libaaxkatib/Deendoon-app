<?php

namespace Database\Factories;

use App\Models\ProfessionalCollectionRequest;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfessionalCollectionRequest>
 */
class ProfessionalCollectionRequestFactory extends Factory
{
    protected $model = ProfessionalCollectionRequest::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'status' => 'submitted',
            'submitted_by_user_id' => (string) $this->faker->numberBetween(1, 999999),
        ];
    }
}
