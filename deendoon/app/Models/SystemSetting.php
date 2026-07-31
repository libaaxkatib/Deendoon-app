<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\SystemSettingFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * 06 §6.8: one row per tenant (FR-069). Administration configures; it
 * never itself executes a workflow using these values (recovery-timing,
 * notification-settings, and collection-threshold fields currently have
 * no consumer since their owning modules' automation was never built —
 * see the Final Report).
 */
#[Fillable([
    'default_credit_limit', 'credit_limit_reminder_enabled', 'soft_limit_warning_threshold',
    'whatsapp_reminder_days', 'sms_reminder_days', 'call_reminder_days',
    'professional_collection_threshold_days', 'notification_settings',
    'long_outstanding_debt_days',
])]
class SystemSetting extends Model
{
    /** @use HasFactory<SystemSettingFactory> */
    use BelongsToTenant, HasFactory, HasUlids;

    public $timestamps = false;

    /**
     * Mirrors the column DEFAULT (migration
     * 2026_08_11_090000_add_long_outstanding_debt_days_to_system_settings_table.php)
     * so a freshly-created, unsaved-and-unrefreshed instance already reads
     * 90 — matching AdminSettingsService::systemSettingsFor()'s pattern of
     * returning the instance it just saved without a refresh().
     */
    protected $attributes = [
        'long_outstanding_debt_days' => 90,
    ];

    protected function casts(): array
    {
        return [
            'default_credit_limit' => 'decimal:2',
            'credit_limit_reminder_enabled' => 'boolean',
            'soft_limit_warning_threshold' => 'decimal:2',
            'whatsapp_reminder_days' => 'array',
            'sms_reminder_days' => 'array',
            'call_reminder_days' => 'array',
            'professional_collection_threshold_days' => 'integer',
            'notification_settings' => 'array',
            'long_outstanding_debt_days' => 'integer',
            'updated_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
