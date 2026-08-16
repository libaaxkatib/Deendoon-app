<?php

namespace App\Models;

use Database\Factories\TenantFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['business_name', 'logo_path', 'address', 'contact_email', 'contact_phone'])]
class Tenant extends Model
{
    /** @use HasFactory<TenantFactory> */
    use HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'suspended_at' => 'datetime',
        ];
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    /**
     * Admin Panel — Business Management. `status` is system-computed
     * (Platform Administrator action only), deliberately excluded from
     * Fillable per this project's convention — set only via these two
     * methods, never mass assignment.
     */
    public function suspend(?string $reason = null): void
    {
        $this->status = 'suspended';
        $this->suspended_at = now();
        $this->suspended_reason = $reason;
        $this->save();
    }

    public function activate(): void
    {
        $this->status = 'active';
        $this->suspended_at = null;
        $this->suspended_reason = null;
        $this->save();
    }

    /**
     * Backend Completion Roadmap, Phase 3.2. One row per tenant (enforced
     * by `tenant_subscriptions.tenant_id`'s unique index — see the
     * Phase 3.1 migration).
     */
    public function subscription(): HasOne
    {
        return $this->hasOne(TenantSubscription::class);
    }

    public function subscriptionChangeRequests(): HasMany
    {
        return $this->hasMany(SubscriptionChangeRequest::class);
    }

    public function storageAddons(): HasMany
    {
        return $this->hasMany(StorageAddon::class);
    }
}
