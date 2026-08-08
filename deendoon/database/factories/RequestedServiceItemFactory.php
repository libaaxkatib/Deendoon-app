<?php

namespace Database\Factories;

use App\Models\RequestedServiceItem;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<RequestedServiceItem>
 */
class RequestedServiceItemFactory extends Factory
{
    protected $model = RequestedServiceItem::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'service_label' => $this->faker->randomElement(['Field Visit', 'Legal Notice', 'Skip Tracing']),
        ];
    }
}
