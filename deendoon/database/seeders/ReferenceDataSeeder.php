<?php

namespace Database\Seeders;

use App\Models\Tenant;
use App\Services\ReferenceDataService;
use Illuminate\Database\Seeder;

/**
 * Professional Collection Reference Data fix — provisions the approved
 * default Reason for Transfer / Requested Service options for every
 * existing tenant. The value lists and the idempotent per-tenant
 * provisioning logic both live in
 * `ReferenceDataService::provisionDefaults()` (single source, per "Do not
 * duplicate business logic") — this seeder only supplies the loop over
 * existing tenants, same pattern as `MessageTemplateSeeder`.
 *
 * Tenants created *after* this seeder runs receive these defaults
 * automatically via `AuthController::register()` calling the same service
 * method — this seeder remains only for tenants that already existed
 * before that fix shipped (including the local dev/test tenant).
 *
 * Resolves `ReferenceDataService` via the `app()` helper rather than
 * constructor injection, matching `MessageTemplateSeeder`: `Seeder::resolve()`
 * only container-resolves child seeders when a container was explicitly
 * set on the parent, and `ProductionReadinessTest` instantiates
 * `DatabaseSeeder` directly (bypassing the container) to test its own
 * safety guard in isolation.
 */
class ReferenceDataSeeder extends Seeder
{
    public function run(): void
    {
        $referenceData = app(ReferenceDataService::class);

        Tenant::query()->each(fn (Tenant $tenant) => $referenceData->provisionDefaults($tenant));
    }
}
