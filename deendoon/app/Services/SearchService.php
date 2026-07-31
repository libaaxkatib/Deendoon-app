<?php

namespace App\Services;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Payment;
use App\Models\Receipt;
use App\Models\Statement;
use App\Models\User;
use Illuminate\Support\Collection;

/**
 * FR-063 — read-only aggregation across the entity types the Feature
 * Freeze names (Customer, Debt, Payment, Receipt/DemandLetter/Statement,
 * Collection Case). Per-entity-type RBAC (E2: an entity type a user
 * cannot view is omitted entirely, not filtered after retrieval) reuses
 * each entity's existing Policy — no new authorization rule is invented.
 * Payment has no dedicated Policy anywhere in the project (PaymentController
 * authorizes via Debt's policy instead); Search applies the same
 * Business Owner (`admin`) check every other Policy in this project
 * already encodes, rather than adding a Policy class whose only consumer
 * would be this one read-only aggregation.
 *
 * Result cap (10 per entity type) and match fields are documented
 * judgment calls — FR-063's own text defers pagination, ranking, and
 * default sorting to `04_Business_Rules.md` as unresolved Open Items.
 */
class SearchService
{
    private const LIMIT_PER_TYPE = 10;

    public function search(User $user, string $term, bool $includeArchived): Collection
    {
        $like = '%'.mb_strtolower($term).'%';
        $results = collect();

        if ($user->can('viewAny', Customer::class)) {
            $query = Customer::query();
            if ($includeArchived) {
                $query->withTrashed();
            }
            $results->put('customers', $query->where(function ($q) use ($like) {
                $q->whereRaw('LOWER(name) LIKE ?', [$like])->orWhereRaw('LOWER(phone) LIKE ?', [$like]);
            })->limit(self::LIMIT_PER_TYPE)->get());
        }

        if ($user->can('viewAny', Debt::class)) {
            $query = Debt::query();
            if ($includeArchived) {
                $query->withTrashed();
            }
            $results->put('debts', $query->whereRaw('LOWER(reference_number) LIKE ?', [$like])
                ->limit(self::LIMIT_PER_TYPE)->get());
        }

        if ($user->hasRole('admin')) {
            $results->put('payments', Payment::whereRaw('LOWER(reference_notes) LIKE ?', [$like])
                ->limit(self::LIMIT_PER_TYPE)->get());
        }

        if ($user->can('viewAny', Receipt::class)) {
            $results->put('receipts', Receipt::whereRaw('LOWER(reference_number) LIKE ?', [$like])
                ->limit(self::LIMIT_PER_TYPE)->get());
        }

        if ($user->can('viewAny', DemandLetter::class)) {
            $results->put('demand_letters', DemandLetter::whereRaw('LOWER(reference_number) LIKE ?', [$like])
                ->limit(self::LIMIT_PER_TYPE)->get());
        }

        if ($user->can('viewAny', Statement::class)) {
            $results->put('statements', Statement::whereRaw('LOWER(reference_number) LIKE ?', [$like])
                ->limit(self::LIMIT_PER_TYPE)->get());
        }

        if ($user->can('viewAny', CollectionCase::class)) {
            $results->put('collection_cases', CollectionCase::whereRaw('LOWER(reference_number) LIKE ?', [$like])
                ->limit(self::LIMIT_PER_TYPE)->get());
        }

        return $results;
    }
}
