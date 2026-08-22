<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\PlatformPaymentSetting;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Manual Mobile-Money Subscription Payment Flow (Product Owner decision):
 * reads and updates the single platform-level destination mobile-money
 * number. Only the Deendoon Platform Administrator may call
 * {@see update()} (enforced by the caller's `Gate::authorize('platform-admin-only')`,
 * matching every other write in the Subscription domain); {@see current()}
 * is read by the Business Owner-facing API to populate the "Send Money"
 * step, so it carries no such restriction itself.
 */
class PlatformPaymentSettingsService
{
    public function __construct(private readonly AuditLogService $auditLog) {}

    public function current(): ?PlatformPaymentSetting
    {
        return PlatformPaymentSetting::first();
    }

    /**
     * Upserts the single row (there is never more than one) and records an
     * audit entry — the same lockForUpdate()-inside-a-transaction shape
     * used throughout this domain's other single-row-per-scope writes.
     */
    public function update(string $destinationNumber, User $actor): PlatformPaymentSetting
    {
        return DB::transaction(function () use ($destinationNumber, $actor) {
            $setting = PlatformPaymentSetting::lockForUpdate()->first();

            if ($setting === null) {
                $setting = new PlatformPaymentSetting(['destination_mobile_money_number' => $destinationNumber]);
            } else {
                $setting->destination_mobile_money_number = $destinationNumber;
            }

            $setting->updated_by = $actor->id;
            $setting->updated_at = now();
            $setting->save();

            $this->auditLog->record(
                AuditAction::PlatformPaymentDestinationChanged,
                'platform_payment_setting',
                $setting->id,
                $actor,
                "destination_mobile_money_number changed to {$destinationNumber}",
            );

            return $setting;
        });
    }
}
