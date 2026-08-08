<?php

namespace App\Models;

use App\Enums\DocumentType;
use Database\Factories\ProfessionalCollectionRequestDocumentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): a pure link to an EXISTING Receipt/DemandLetter/Statement/
 * Invoice row — (document_type, document_id), no file_path/file_size of
 * its own, no duplication of the underlying file. Mirrors DocumentEvent's
 * existing polymorphic-by-convention design (no FK on document_id, since
 * it can point at any of four different tables).
 */
#[Fillable(['professional_collection_request_id', 'document_type', 'document_id'])]
class ProfessionalCollectionRequestDocument extends Model
{
    /** @use HasFactory<ProfessionalCollectionRequestDocumentFactory> */
    use HasFactory, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'document_type' => DocumentType::class,
            'created_at' => 'datetime',
        ];
    }

    public function request(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCollectionRequest::class, 'professional_collection_request_id');
    }
}
