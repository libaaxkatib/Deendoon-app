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
 */
trait BelongsToTenant
{
    protected static function bootBelongsToTenant(): void
    {
        static::addGlobalScope('tenant', function (Builder $builder) {
            $user = Auth::guard('sanctum')->user();

            if ($user && $user->tenant_id) {
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
