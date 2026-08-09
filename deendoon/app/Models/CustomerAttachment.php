<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Final Product Completion Roadmap, P1.6 — a generic file attachment on a
 * Customer, distinct from the 4 system-generated Document types and from
 * Professional Collection's own attachment table. `tenant_id` is never
 * fillable — set exclusively by {@see BelongsToTenant}.
 */
#[Fillable(['customer_id', 'uploaded_by_user_id', 'file_path', 'original_filename', 'mime_type', 'file_size', 'description'])]
class CustomerAttachment extends Model
{
    use BelongsToTenant, HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'file_size' => 'integer',
            'created_at' => 'datetime',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }
}
