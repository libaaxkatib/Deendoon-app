<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateCompanyProfileRequest;
use App\Http\Requests\UpdateSystemPreferencesRequest;
use App\Http\Resources\CompanyProfileResource;
use App\Http\Resources\DocumentTemplateResource;
use App\Http\Resources\SystemSettingResource;
use App\Services\AdminSettingsService;
use App\Services\DocumentService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

/**
 * FR-068 (Company Profile & Branding) and FR-069 (System Preferences,
 * including Document Templates). Administration is Super Admin-only (08
 * §5) — reuses the existing `admin-only` Gate rather than a new Policy,
 * matching CalendarController's precedent of gating a non-per-instance
 * action directly through Gate::authorize.
 */
class AdminSettingsController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly AdminSettingsService $settings,
        private readonly DocumentService $documents,
    ) {}

    public function companyProfile(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');

        return $this->successResponse(new CompanyProfileResource($request->user()->tenant));
    }

    public function updateCompanyProfile(UpdateCompanyProfileRequest $request): JsonResponse
    {
        Gate::authorize('admin-only');

        // Backend Completion Roadmap (Phase 4.2, Storage Limit
        // Enforcement): only gated when a logo is actually being
        // uploaded — a text-only Company Profile edit (business_name,
        // address, etc.) is not itself an upload and must keep working
        // even for a tenant already at their storage limit ("Only NEW
        // uploads are blocked"). Reuses DocumentService::assertCanUpload()
        // — the same check the four document-generation endpoints use —
        // rather than a second copy of the usage/allowance comparison.
        //
        // Product Owner-directed race fix: the check and the actual
        // write must share one transaction, otherwise assertCanUpload()'s
        // lockForUpdate() is acquired and released with nothing left to
        // protect (see DocumentService::assertCanUpload()'s docblock) —
        // wrapping both calls here is what actually holds the lock
        // through the write, the same way DocumentService::
        // renderAndSave() does for document generation.
        $tenant = DB::transaction(function () use ($request) {
            if ($request->hasFile('logo')) {
                $this->documents->assertCanUpload($request->user()->tenant);
            }

            return $this->settings->updateCompanyProfile(
                $request->user()->tenant,
                $request->validated(),
                $request->file('logo'),
                $request->user(),
            );
        });

        return $this->successResponse(new CompanyProfileResource($tenant), 'Company Profile updated successfully');
    }

    public function preferences(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');

        $tenantId = $request->user()->tenant_id;

        return $this->successResponse([
            'system_settings' => new SystemSettingResource($this->settings->systemSettingsFor($tenantId)),
            'document_templates' => DocumentTemplateResource::collection($this->settings->documentTemplatesFor($tenantId)),
        ]);
    }

    public function updatePreferences(UpdateSystemPreferencesRequest $request): JsonResponse
    {
        Gate::authorize('admin-only');

        $tenantId = $request->user()->tenant_id;
        $settings = $this->settings->updatePreferences($tenantId, $request->safe()->except('document_templates'), $request->user());

        if ($request->filled('document_templates')) {
            $this->settings->updateDocumentTemplates($tenantId, $request->validated('document_templates'), $request->user());
        }

        return $this->successResponse([
            'system_settings' => new SystemSettingResource($settings),
            'document_templates' => DocumentTemplateResource::collection($this->settings->documentTemplatesFor($tenantId)),
        ], 'System Preferences updated successfully');
    }
}
