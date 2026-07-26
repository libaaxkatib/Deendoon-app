<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\DemandLetterTemplate;
use App\Models\DocumentTemplate;
use App\Models\SystemSetting;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;

/**
 * FR-068 (Company Profile & Branding) and FR-069 (System Preferences,
 * including Document Templates). Company Profile fields already live on
 * `tenants` (reused since Module 8, per 06 §3) — this service only adds
 * the administrative write path and Audit Trail entry Module 8 never
 * needed. System Preferences and Document Templates are new storage
 * (06 §6.8), one row per tenant, created lazily on first read/write —
 * `tenant_id` is never mass-assigned (not Fillable on either model,
 * matching the project-wide BelongsToTenant convention), always set via
 * explicit property assignment before save(), same pattern as
 * NotificationService.
 */
class AdminSettingsService
{
    private const LOGO_DISK = 'local';

    public function __construct(private readonly AuditLogService $auditLog) {}

    public function updateCompanyProfile(Tenant $tenant, array $data, ?UploadedFile $logo, User $actor): Tenant
    {
        $tenant->business_name = $data['business_name'];
        $tenant->address = $data['address'] ?? null;
        $tenant->contact_email = $data['contact_email'] ?? null;
        $tenant->contact_phone = $data['contact_phone'] ?? null;

        if ($logo) {
            $path = "branding/{$tenant->id}/logo.".$logo->extension();
            Storage::disk(self::LOGO_DISK)->put($path, file_get_contents($logo->getRealPath()));
            $tenant->logo_path = $path;
        }

        $tenant->save();

        $this->auditLog->record(AuditAction::Edited, 'company_settings', $tenant->id, $actor, null, $tenant->id);

        return $tenant->fresh();
    }

    public function systemSettingsFor(string $tenantId): SystemSetting
    {
        $settings = SystemSetting::where('tenant_id', $tenantId)->first();

        if ($settings) {
            return $settings;
        }

        $settings = new SystemSetting(['default_credit_limit' => 0, 'credit_limit_reminder_enabled' => true]);
        $settings->tenant_id = $tenantId;
        $settings->updated_at = now();
        $settings->save();

        return $settings;
    }

    public function updatePreferences(string $tenantId, array $data, User $actor): SystemSetting
    {
        $settings = $this->systemSettingsFor($tenantId);

        $settings->fill($data);
        $settings->updated_at = now();
        $settings->save();

        $this->auditLog->record(AuditAction::Edited, 'system_settings', $settings->id, $actor, null, $tenantId);

        return $settings->fresh();
    }

    /**
     * FR-069's "Document Templates" — all four types, each showing its
     * tenant-configured content if any, otherwise the same placeholder
     * wording Module 8 already renders by default (so this view never
     * shows a template as "empty" when generation would in fact use
     * real, existing wording).
     */
    public function documentTemplatesFor(string $tenantId): Collection
    {
        $configured = DocumentTemplate::where('tenant_id', $tenantId)->get()->keyBy('template_type');

        return collect(DemandLetterTemplate::cases())->map(function (DemandLetterTemplate $template) use ($configured) {
            $existing = $configured->get($template->value);

            return $existing ?? new DocumentTemplate([
                'template_type' => $template->value,
                'content' => $this->defaultTemplateContent($template),
            ]);
        });
    }

    /**
     * @param  array<int, array{template_type: string, content: string}>  $templates
     */
    public function updateDocumentTemplates(string $tenantId, array $templates, User $actor): void
    {
        foreach ($templates as $entry) {
            $documentTemplate = DocumentTemplate::where('tenant_id', $tenantId)
                ->where('template_type', $entry['template_type'])
                ->first();

            if (! $documentTemplate) {
                $documentTemplate = new DocumentTemplate(['template_type' => $entry['template_type']]);
                $documentTemplate->tenant_id = $tenantId;
            }

            $documentTemplate->content = $entry['content'];
            $documentTemplate->updated_at = now();
            $documentTemplate->save();
        }

        $this->auditLog->record(AuditAction::Edited, 'document_templates', $tenantId, $actor, null, $tenantId);
    }

    /**
     * Used by DocumentService at generation time — the effective content
     * for a template type, tenant-configured if set, otherwise the
     * pre-existing placeholder wording (unchanged behavior for any tenant
     * that has not customized it).
     */
    public function templateContent(string $tenantId, DemandLetterTemplate $template): string
    {
        return DocumentTemplate::where('tenant_id', $tenantId)
            ->where('template_type', $template->value)
            ->value('content') ?? $this->defaultTemplateContent($template);
    }

    private function defaultTemplateContent(DemandLetterTemplate $template): string
    {
        return match ($template) {
            DemandLetterTemplate::FirstReminder => 'This is a friendly reminder that the debt referenced below remains outstanding. Please arrange payment at your earliest convenience.',
            DemandLetterTemplate::SecondReminder => 'Our records show the debt referenced below remains unpaid despite a previous reminder. Please settle this balance promptly to avoid further action.',
            DemandLetterTemplate::FinalDemand => 'This is a final demand for payment of the debt referenced below. Failure to settle this balance may result in further collection action.',
            DemandLetterTemplate::LegalNotice => 'This notice is to inform you that the debt referenced below remains unpaid. Further action may be taken to recover this amount.',
        };
    }
}
