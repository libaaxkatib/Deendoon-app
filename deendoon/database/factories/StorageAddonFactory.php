<?php

namespace Database\Factories;

use App\Models\StorageAddon;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<StorageAddon>
 *
 * `tenant_id` is deliberately not defaulted here — always set explicitly
 * via `->create(['tenant_id' => ...])` in tests, matching every other
 * factory in this codebase.
 */
class StorageAddonFactory extends Factory
{
    protected $model = StorageAddon::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'storage_package' => '10gb',
            'storage_size' => 10,
            'monthly_price' => 2,
            'status' => 'pending',
        ];
    }

    public function active(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'active',
            'started_at' => now(),
        ]);
    }
}
