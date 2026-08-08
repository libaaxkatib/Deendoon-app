<?php

namespace Database\Factories;

use App\Models\StorageAddonRejectionReason;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<StorageAddonRejectionReason>
 */
class StorageAddonRejectionReasonFactory extends Factory
{
    protected $model = StorageAddonRejectionReason::class;

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
