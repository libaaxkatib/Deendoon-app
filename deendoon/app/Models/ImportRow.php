<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Deliberately has no tenant_id (06_Database_Design.md §6.2 defines none)
 * and therefore no BelongsToTenant scope. Tenant isolation is inherited
 * relationally: rows must only ever be reached through an already
 * tenant-scoped ImportBatch (ImportBatch::rows()), never queried directly.
 */
#[Fillable([
    'batch_id', 'row_number', 'row_data', 'validation_status',
    'validation_errors', 'duplicate_match_customer_id', 'resolution', 'resulting_customer_id',
])]
class ImportRow extends Model
{
    use HasUlids;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'row_data' => 'array',
            'validation_errors' => 'array',
        ];
    }

    public function batch(): BelongsTo
    {
        return $this->belongsTo(ImportBatch::class, 'batch_id');
    }

    public function duplicateMatchCustomer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'duplicate_match_customer_id');
    }

    public function resultingCustomer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'resulting_customer_id');
    }
}
