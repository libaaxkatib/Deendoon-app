<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenantOrPlatformAdmin;
use Database\Factories\StorageAddonFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Backend Completion Roadmap, Phase 3.2 (Product Owner Decision: Option B
 * — Conditional Global Scope). Storage Add-ons are purchased separately
 * from the subscription plan, via the same manual-payment
 * request/approve/reject/activate pattern as SubscriptionChangeRequest.
 * Uses BelongsToTenantOrPlatformAdmin, for the same Platform-Administrator
 * cross-tenant review reason documented on {@see TenantSubscription}.
 * `tenant_id`/`approved_by` are excluded from Fillable and must be set
 * via direct property assignment.
 */
#[Fillable(['storage_package', 'storage_size', 'monthly_price', 'started_at', 'expires_at', 'approved_by', 'approved_at', 'status'])]
class StorageAddon extends Model
{
    /** @use HasFactory<StorageAddonFactory> */
    use BelongsToTenantOrPlatformAdmin, HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'storage_size' => 'integer',
            'monthly_price' => 'decimal:2',
            'started_at' => 'datetime',
            'expires_at' => 'datetime',
            'approved_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
