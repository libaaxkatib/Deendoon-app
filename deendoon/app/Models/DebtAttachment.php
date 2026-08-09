<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Final Product Completion Roadmap, P1.6 — a generic file attachment on a
 * Debt. Scan/Upload Invoice (P2.6/P2.7) reuse this table as pure storage.
 * `tenant_id` is never fillable — set exclusively by
 * {@see BelongsToTenant}.
 */
#[Fillable(['debt_id', 'uploaded_by_user_id', 'file_path', 'original_filename', 'mime_type', 'file_size', 'description'])]
class DebtAttachment extends Model
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

    public function debt(): BelongsTo
    {
        return $this->belongsTo(Debt::class);
    }

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }
}
