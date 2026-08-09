<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Final Product Completion Roadmap, P1.6 — a generic file attachment on a
 * Collection Case. `tenant_id` is never fillable — set exclusively by
 * {@see BelongsToTenant}.
 */
#[Fillable(['collection_case_id', 'uploaded_by_user_id', 'file_path', 'original_filename', 'mime_type', 'file_size', 'description'])]
class CollectionCaseAttachment extends Model
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

    public function collectionCase(): BelongsTo
    {
        return $this->belongsTo(CollectionCase::class);
    }

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }
}
