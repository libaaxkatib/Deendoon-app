<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\ReferenceDataCategory;
use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Payment;
use App\Models\ProfessionalCollectionRequestReason;
use App\Models\ReferenceData;
use App\Models\RequestedServiceItem;
use App\Models\StorageAddonRejectionReason;
use App\Models\SubscriptionChangeRequestRejectionReason;
use App\Models\Tenant;
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

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * default options): the 13 approved Reason for Transfer and 13
     * approved Requested Service values, provisioned per tenant. Every
     * other Reference Data category (`risk_level`/`payment_method`/
     * `collection_outcome`) is deliberately left to the Business Owner to
     * configure via `PUT /admin/reference-data/{category}` — these two
     * are the only ones with a Product Owner-approved default list, so
     * they're the only ones provisioned automatically.
     *
     * Idempotent: looked up by tenant_id + category + value_label and
     * updated in place if found, so calling this more than once for the
     * same tenant (e.g. re-running the seeder) never creates duplicates
     * and never touches a value the Business Owner has since customized
     * under a different label — same pattern as
     * `MessageTemplateService::provisionDefaults()`.
     *
     * `tenant_id` is set via direct property assignment rather than
     * `updateOrCreate()`'s mass-assignment (`ReferenceData` deliberately
     * excludes it from Fillable, see `BelongsToTenant`).
     * `withoutGlobalScope('tenant')` guards the lookup for the same
     * reason as that method: this can run before any Sanctum user is
     * authenticated (mid-registration) or from a seeder.
     */
    public function provisionDefaults(Tenant $tenant): void
    {
        $categories = [
            [ReferenceDataCategory::TransferReason, self::defaultTransferReasons()],
            [ReferenceDataCategory::RequestedService, self::defaultRequestedServices()],
        ];

        foreach ($categories as [$category, $values]) {
            foreach ($values as $index => $valueLabel) {
                $item = ReferenceData::withoutGlobalScope('tenant')
                    ->where('tenant_id', $tenant->id)
                    ->where('category', $category->value)
                    ->where('value_label', $valueLabel)
                    ->first() ?? new ReferenceData;

                $item->tenant_id = $tenant->id;
                $item->category = $category->value;
                $item->value_label = $valueLabel;
                $item->sort_order = $index + 1;
                $item->is_active = true;
                $item->created_at ??= now();
                $item->save();
            }
        }
    }

    /**
     * @return array<int, string>
     */
    private static function defaultTransferReasons(): array
    {
        return [
            'Customer stopped answering calls',
            'Customer ignores WhatsApp messages',
            'Customer ignores SMS',
            'Customer repeatedly promises but never pays',
            'Customer disputes the debt',
            'Customer cannot be located',
            'Customer business is closed',
            'Customer intentionally delays payment',
            'Debt is high value',
            'Long overdue account',
            'Previous follow-up unsuccessful',
            'Client requested agency collection',
            'Other',
        ];
    }

    /**
     * @return array<int, string>
     */
    private static function defaultRequestedServices(): array
    {
        return [
            'Telephone Collection',
            'WhatsApp Follow-up',
            'SMS Follow-up',
            'Email Collection',
            'Payment Negotiation',
            'Settlement Negotiation',
            'Installment Arrangement',
            'Official Demand Letter',
            'Field Visit',
            'Executive Collection',
            'Skip Tracing (Locate Debtor)',
            'Legal Review',
            'Court Preparation',
        ];
    }

    /**
     * $tenantId is nullable — Subscription Approval + Storage Add-on
     * Approval (Product Owner-approved decision record, Decision 4): the
     * platform-owned (tenant_id NULL) Rejection Reason categories are
     * looked up with the Deendoon Platform Administrator's own (NULL)
     * tenant_id, matching those rows exactly. Every pre-existing category
     * remains tenant-scoped as before.
     */
    public function forCategory(?string $tenantId, ReferenceDataCategory $category): Collection
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
            // professional_collection_request_reasons/services carry no
            // tenant_id of their own (child of ProfessionalCollectionRequest,
            // which is deliberately bimodal/unscoped — see that model's
            // docblock), so tenant scoping is joined through the parent.
            ReferenceDataCategory::TransferReason => ProfessionalCollectionRequestReason::whereHas(
                'request',
                fn ($q) => $q->where('tenant_id', $tenantId),
            )->where('reason_label', $valueLabel)->exists(),
            ReferenceDataCategory::RequestedService => RequestedServiceItem::whereHas(
                'request',
                fn ($q) => $q->where('tenant_id', $tenantId),
            )->where('service_label', $valueLabel)->exists(),
            // Subscription Approval + Storage Add-on Approval (Product
            // Owner-approved decision record): platform-owned (tenant_id
            // NULL) predefined Rejection Reasons — never tenant-scoped, so
            // $tenantId is deliberately ignored here, matching every other
            // arm's "in use by its own child rows" check.
            ReferenceDataCategory::SubscriptionRejectionReason => SubscriptionChangeRequestRejectionReason::where('reason_label', $valueLabel)->exists(),
            ReferenceDataCategory::StorageRejectionReason => StorageAddonRejectionReason::where('reason_label', $valueLabel)->exists(),
        };
    }
}
