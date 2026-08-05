<?php

namespace Database\Seeders;

use App\Models\Tenant;
use App\Services\MessageTemplateService;
use Illuminate\Database\Seeder;

/**
 * Deendoon V1 Reminder Workflow Update — provisions the 7 approved default
 * WhatsApp/SMS templates (Somali) for every existing tenant. The template
 * data and the idempotent per-tenant provisioning logic both live in
 * `MessageTemplateService::provisionDefaults()` (single source, per "Do
 * not duplicate business logic") — this seeder only supplies the loop
 * over existing tenants.
 *
 * Backend Completion Audit (Phase 1): tenants created *after* this seeder
 * runs now also receive these defaults automatically, via
 * `AuthController::register()` calling the same service method — this
 * seeder remains only for tenants that already existed before that fix
 * shipped.
 *
 * Resolves `MessageTemplateService` via the `app()` helper rather than
 * constructor injection: `ProductionReadinessTest` deliberately
 * instantiates `DatabaseSeeder` directly (`new DatabaseSeeder`, bypassing
 * the container) to test its own safety guard in isolation, and Laravel's
 * `Seeder::resolve()` only container-resolves child seeders when a
 * container was explicitly set on the parent — otherwise it falls back to
 * a bare `new $class`, which can't satisfy a constructor dependency.
 */
class MessageTemplateSeeder extends Seeder
{
    public function run(): void
    {
        $messageTemplates = app(MessageTemplateService::class);

        Tenant::query()->each(fn (Tenant $tenant) => $messageTemplates->provisionDefaults($tenant));
    }
}
