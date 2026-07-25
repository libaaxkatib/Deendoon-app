<?php

namespace Database\Factories;

use App\Models\DemandLetter;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<DemandLetter>
 */
class DemandLetterFactory extends Factory
{
    protected $model = DemandLetter::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'template_type' => 'first_reminder',
            'reference_number' => 'DL-'.str_pad((string) $this->faker->unique()->numberBetween(1, 999999), 6, '0', STR_PAD_LEFT),
            'generated_at' => now(),
            'file_path' => 'documents/test/demand_letters/'.$this->faker->uuid().'.pdf',
        ];
    }
}
