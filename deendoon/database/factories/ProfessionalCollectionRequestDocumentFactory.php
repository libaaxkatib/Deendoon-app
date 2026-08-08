<?php

namespace Database\Factories;

use App\Enums\DocumentType;
use App\Models\ProfessionalCollectionRequestDocument;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<ProfessionalCollectionRequestDocument>
 */
class ProfessionalCollectionRequestDocumentFactory extends Factory
{
    protected $model = ProfessionalCollectionRequestDocument::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'document_type' => DocumentType::Receipt,
            'document_id' => (string) Str::ulid(),
        ];
    }
}
