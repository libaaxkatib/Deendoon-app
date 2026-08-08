<?php

namespace Database\Factories;

use App\Enums\ProfessionalCollectionTimelineEventType;
use App\Models\ProfessionalCollectionTimelineEvent;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfessionalCollectionTimelineEvent>
 */
class ProfessionalCollectionTimelineEventFactory extends Factory
{
    protected $model = ProfessionalCollectionTimelineEvent::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'event_type' => ProfessionalCollectionTimelineEventType::PendingReview,
            'occurred_at' => now(),
            'notes' => $this->faker->sentence(),
        ];
    }
}
