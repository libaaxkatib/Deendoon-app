<?php

namespace Database\Factories;

use App\Models\Announcement;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Announcement>
 */
class AnnouncementFactory extends Factory
{
    protected $model = Announcement::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title' => $this->faker->sentence(4),
            'message' => $this->faker->paragraph(),
            'scope' => 'all',
            'recipient_count' => $this->faker->numberBetween(1, 20),
            'sent_by_user_id' => (string) $this->faker->numberBetween(1, 999999),
            'sent_at' => now(),
        ];
    }
}
