<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\ReferenceDataCategory;
use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Payment;
use App\Models\ReferenceData;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Collection;

/**
 * FR-070 — storage only; business validation for how these values are
 * applied remains owned by the consuming module (Main Flow step 4), so
 * this does not wire Risk Level/Payment Method/Collection Outcome input
 * validation in Modules 4/6/7 to read from here (see the Final Report's
 * Future Review Notes). The one piece of consuming-module awareness this
 * service does need is the Product Owner ruling on FR-070 E2: deactivating
 * a value currently referenced by an existing record is blocked.
 */
class ReferenceDataService
{
    public function __construct(private readonly AuditLogService $auditLog) {}

    public function forCategory(string $tenantId, ReferenceDataCategory $category): Collection
    {
        return ReferenceData::where('tenant_id', $tenantId)
            ->where('category', $category->value)
            ->orderBy('sort_order')
            ->get();
    }

    /**
     * @param  array<int, array{id?: string, value_label: string, sort_order?: int, is_active?: bool}>  $values
     */
    public function updateCategory(string $tenantId, ReferenceDataCategory $category, array $values, User $actor): Collection
    {
        foreach ($values as $entry) {
            $item = isset($entry['id'])
                ? ReferenceData::where('tenant_id', $tenantId)->where('id', $entry['id'])->first()
                : null;

            $deactivating = $item && $item->is_active && ($entry['is_active'] ?? true) === false;

            if ($deactivating && $this->isValueInUse($tenantId, $category, $item->value_label)) {
                throw new HttpResponseException(response()->json([
                    'success' => false,
                    'message' => "The value '{$item->value_label}' is currently in use and cannot be removed.",
                    'data' => null,
                    'errors' => null,
                ], 409));
            }

            if (! $item) {
                $item = new ReferenceData(['category' => $category->value]);
                $item->tenant_id = $tenantId;
                $item->created_at = now();
            }

            $item->value_label = $entry['value_label'];
            $item->sort_order = $entry['sort_order'] ?? $item->sort_order ?? 0;
            $item->is_active = $entry['is_active'] ?? $item->is_active ?? true;
            $item->save();
        }

        $this->auditLog->record(AuditAction::Edited, 'reference_data', $tenantId, $actor, null, $tenantId);

        return $this->forCategory($tenantId, $category);
    }

    private function isValueInUse(string $tenantId, ReferenceDataCategory $category, string $valueLabel): bool
    {
        return match ($category) {
            ReferenceDataCategory::RiskLevel => Customer::withTrashed()
                ->where('tenant_id', $tenantId)->where('risk_level', $valueLabel)->exists(),
            ReferenceDataCategory::PaymentMethod => Payment::where('tenant_id', $tenantId)
                ->where('payment_method', $valueLabel)->exists(),
            ReferenceDataCategory::CollectionOutcome => CollectionCase::where('tenant_id', $tenantId)
                ->where('closure_outcome', $valueLabel)->exists(),
        };
    }
}
