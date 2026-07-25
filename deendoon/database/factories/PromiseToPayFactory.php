<?php

namespace Database\Factories;

use App\Models\PromiseToPay;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PromiseToPay>
 */
class PromiseToPayFactory extends Factory
{
    protected $model = PromiseToPay::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'promised_date' => now()->addDays(7)->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $this->faker->numberBetween(1, 999999),
        ];
    }
}
