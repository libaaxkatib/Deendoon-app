<?php

namespace Database\Factories;

use App\Models\Statement;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Statement>
 */
class StatementFactory extends Factory
{
    protected $model = Statement::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'reference_number' => 'ST-'.str_pad((string) $this->faker->unique()->numberBetween(1, 999999), 6, '0', STR_PAD_LEFT),
            'generated_at' => now(),
            'file_path' => 'documents/test/statements/'.$this->faker->uuid().'.pdf',
        ];
    }
}
