<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['business_name', 'logo_path', 'address', 'contact_email', 'contact_phone'])]
class Tenant extends Model
{
    use HasUlids;

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
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
