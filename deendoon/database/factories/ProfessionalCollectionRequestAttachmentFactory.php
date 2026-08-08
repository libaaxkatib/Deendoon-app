<?php

namespace Database\Factories;

use App\Models\ProfessionalCollectionRequestAttachment;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfessionalCollectionRequestAttachment>
 */
class ProfessionalCollectionRequestAttachmentFactory extends Factory
{
    protected $model = ProfessionalCollectionRequestAttachment::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'file_path' => 'documents/test/pcr-attachments/'.$this->faker->uuid().'.pdf',
            'original_filename' => $this->faker->word().'.pdf',
            'mime_type' => 'application/pdf',
            'file_size' => $this->faker->numberBetween(1000, 500000),
        ];
    }
}
