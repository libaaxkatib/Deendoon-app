<?php

namespace Database\Factories;

use App\Models\DocumentEvent;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<DocumentEvent>
 */
class DocumentEventFactory extends Factory
{
    protected $model = DocumentEvent::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'document_type' => 'receipt',
            'document_id' => (string) $this->faker->ulid(),
            'event_type' => 'generated',
            'occurred_at' => now(),
        ];
    }
}
