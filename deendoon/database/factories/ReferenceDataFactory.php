<?php

namespace Database\Factories;

use App\Models\ReferenceData;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ReferenceData>
 */
class ReferenceDataFactory extends Factory
{
    protected $model = ReferenceData::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'category' => 'risk_level',
            'value_label' => $this->faker->word(),
            'sort_order' => 0,
            'is_active' => true,
            'created_at' => now(),
        ];
    }
}
