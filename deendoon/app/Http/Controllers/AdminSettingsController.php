<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateCompanyProfileRequest;
use App\Http\Requests\UpdateSystemPreferencesRequest;
use App\Http\Resources\CompanyProfileResource;
use App\Http\Resources\DocumentTemplateResource;
use App\Http\Resources\SystemSettingResource;
use App\Services\AdminSettingsService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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

    public function __construct(private readonly AdminSettingsService $settings) {}

    public function companyProfile(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');

        return $this->successResponse(new CompanyProfileResource($request->user()->tenant));
    }

    public function updateCompanyProfile(UpdateCompanyProfileRequest $request): JsonResponse
    {
        Gate::authorize('admin-only');

        $tenant = $this->settings->updateCompanyProfile(
            $request->user()->tenant,
            $request->validated(),
            $request->file('logo'),
            $request->user(),
        );

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
