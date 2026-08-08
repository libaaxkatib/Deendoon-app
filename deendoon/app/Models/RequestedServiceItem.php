<?php

namespace App\Models;

use Database\Factories\RequestedServiceItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): one row per Requested Service selected on a Professional
 * Collection Request (multi-select). Named `RequestedServiceItem`, not
 * `...Service`, to avoid colliding with this codebase's App\Services\
 * naming convention. No tenant_id of its own — same pattern as
 * RequestMessage.
 */
#[Fillable(['professional_collection_request_id', 'service_label'])]
class RequestedServiceItem extends Model
{
    /** @use HasFactory<RequestedServiceItemFactory> */
    use HasFactory, HasUlids;

    protected $table = 'professional_collection_request_services';

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function request(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCollectionRequest::class, 'professional_collection_request_id');
    }
}
