<?php

namespace App\Models\Concerns;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

/**
 * Applies mandatory tenant isolation (Product Owner Decision 1) to every
 * query against the model, and auto-assigns tenant_id from the
 * authenticated user on creation. tenant_id must never be settable via
 * mass assignment (never in the model's Fillable list) — this trait is
 * the only path by which it is set.
 *
 * Fails closed for a null-tenant actor (Module 7's Deendoon Platform
 * Administrator, `08_Security_and_RBAC.md` §5): the filter is applied
 * whenever ANY user is authenticated, using their tenant_id verbatim. For
 * a null-tenant user this becomes `WHERE tenant_id IS NULL`, which no
 * tenant-owned row ever satisfies — correctly hiding every tenant's data
 * by default, matching 08 Principle 3 ("fail closed") and 06 §2's
 * explicit statement that the Platform Administrator's access "is not a
 * platform-wide superuser grant." The one narrow, explicit exception
 * (Professional Collection Requests) is deliberately NOT modeled via this
 * trait — see ProfessionalCollectionRequest, which is scoped by hand.
 */
trait BelongsToTenant
{
    protected static function bootBelongsToTenant(): void
    {
        static::addGlobalScope('tenant', function (Builder $builder) {
            $user = Auth::guard('sanctum')->user();

            if ($user) {
                $builder->where($builder->getModel()->getTable().'.tenant_id', $user->tenant_id);
            }
        });

        static::creating(function (Model $model) {
            if (empty($model->tenant_id)) {
                $user = Auth::guard('sanctum')->user();

                if ($user && $user->tenant_id) {
                    $model->tenant_id = $user->tenant_id;
                }
            }
        });
    }
}
