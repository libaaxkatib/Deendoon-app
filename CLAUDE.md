# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository shape

This is a monorepo with two independently-deployed applications sharing one product spec:

```
Deendoon-app/
├── SRS/              # Product spec (01-11) — the single source of truth for WHAT the product does
├── docs/             # Cross-project governance (versioning/approval process for SRS + engineering docs)
├── deendoon/         # Laravel 13 / PHP 8.4 backend API
│   ├── CLAUDE.md     # Engineering constitution for THIS backend — read it before backend work
│   └── docs/         # Engineering module specs & decision records (Business Health, Risk Level, RBAC amendments)
└── mobile/           # Flutter 3.44 app (the only client — "Customer Mobile App" in SRS terms)
```

**`SRS/01_Project_Overview.md` through `SRS/10_Acceptance_Criteria.md` is the authoritative product spec** — business rules, RBAC, database design, API design, UI/UX. Nothing in this file or in `deendoon/CLAUDE.md` overrides it; where a doc and the code disagree, treat that as a bug to flag, not license to reinterpret either one.

**`deendoon/CLAUDE.md` is the backend's own engineering constitution** (how to work, not what to build) — read it before making backend changes. It also embeds the Laravel Boost guidelines (package versions, Pint formatting, Boost MCP tools) that apply project-wide for PHP work. There is a matching `laravel-best-practices` skill scoped to `deendoon/` — invoke it for any controller/model/migration/policy/service work.

There is no equivalent Flutter-side CLAUDE.md; the architecture notes below are the closest thing.

## Commands

### Backend (`deendoon/`)

PHP is **not** on PATH in this environment — use the full binary path (Laravel Herd), or substitute your own `php` if different:

```bash
PHP="/c/Users/hp/.config/herd/bin/php84/php.exe"
```

```bash
cd deendoon

# Install / setup (installs composer + npm deps, copies .env, migrates, builds assets)
composer run setup

# Run the full test suite (PHPUnit, sqlite in-memory — see phpunit.xml)
"$PHP" artisan test
# or: composer run test

# Run one test file / one test by name
"$PHP" artisan test tests/Feature/ReminderTest.php
"$PHP" artisan test --filter=test_admin_can_check_in_on_a_reminder

# Run a single new/changed migration without re-running the whole set
"$PHP" artisan migrate --path=database/migrations/<file>.php

# Format PHP (run after any PHP edit, before finishing)
vendor/bin/pint --dirty --format agent

# Local dev server + queue worker + Vite, concurrently
composer run dev

# Inspect routes (useful before assuming an endpoint doesn't exist)
"$PHP" artisan route:list
```

Dev/prod DB is **PostgreSQL** (`.env` default); the test suite runs against **SQLite in-memory** (`phpunit.xml`), so don't assume Postgres-specific SQL works in a migration without checking both.

### Mobile (`mobile/`)

```bash
cd mobile
flutter pub get

# Static analysis — must be 0 issues before considering work done
flutter analyze

# Full test suite
flutter test

# One file / one test by name
flutter test test/features/reminders/presentation/screens/reminder_detail_screen_test.dart
flutter test test/path/to/file_test.dart --plain-name "exact or partial test name"

# Run the app against a local backend (default baseUrl points at 10.0.2.2, the
# Android emulator's host-loopback address — override for a real device/iOS sim)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

There's no `.env` convention on the Flutter side — all runtime config is `--dart-define`, read via `lib/core/config/env.dart`.

## Architecture

### Two-account RBAC model — read this before touching any authorization code

Version 1 has exactly two account types (`SRS/08_Security_and_RBAC.md` §5, amended 2026-07-31 — supersedes an earlier 6-role design you may still see referenced in older comments/tests):

- **Business Owner** (`admin` role, tenant-scoped) — one per tenant, full access within that tenant (Customers/Debts/Payments/Cases/Documents/Reports/Admin). This is the Flutter app's only user.
- **Platform Administrator** (`deendoon_platform_administrator`, `tenant_id IS NULL`) — the only cross-tenant actor, and only for Professional Collection Requests. Not a superuser grant; every other capability is denied by the tenant-scoping described below.

There is no Operations Manager / Finance / Support / Viewer / Collection Officer *login* role — retired. `collection_officer` now names an internal Deendoon Recovery Team responsibility, not an authenticatable account.

### Multi-tenancy: `BelongsToTenant` trait (`deendoon/app/Models/Concerns/BelongsToTenant.php`)

Almost every Eloquent model uses this trait. It adds a global scope filtering every query to the authenticated user's `tenant_id`, and auto-assigns `tenant_id` on create. Two things that are easy to get wrong:

- **It fails closed for a null-tenant user** (the Platform Administrator): the scope becomes `WHERE tenant_id IS NULL`, which no tenant-owned row ever satisfies — this is deliberate, not a bug.
- **It resolves `Auth::guard('sanctum')->user()`, which only works inside an active HTTP request.** Calling `->fresh()` on a model instance from a test *after* the HTTP call has returned can silently return unscoped/wrong results. When a feature test needs to verify persistence, re-fetch through a real second HTTP request (e.g. a follow-up `GET`) instead of `$model->fresh()`.
- `tenant_id` must never be in a model's `Fillable` list — this trait is the only path that's allowed to set it.

The one deliberate exception is `ProfessionalCollectionRequest`, scoped by hand to support the Platform Administrator's cross-tenant review — don't use it as a template for anything else.

### Backend request flow

`Route (routes/api.php) → Controller → Form Request → Service → Model/Eloquent → Resource → Policy`. Routes are flat (no versioned controller namespace beyond the `v1` URL prefix), RESTful, noun-based. Controllers call `$this->authorize()` against a Policy; business logic and multi-step orchestration live in `app/Services`, not controllers. Reused across the codebase:

- **ULID primary keys** (`HasUlids`) everywhere, not auto-increment ints.
- **`#[Fillable([...])]` PHP attribute**, not the classic `protected $fillable` property — check this when a mass-assigned field silently doesn't save; a missing entry here fails silently rather than throwing.
- **System-computed fields are deliberately excluded from Fillable** (e.g. `Customer::risk_level`, `Customer::is_read_only`) and set only via direct property assignment + `save()`, or bulk query-builder `UPDATE`, from their owning service — never through mass assignment, so no other code path can override them.
- **No true Eloquent polymorphism** (`morphTo`/`morphMany`) anywhere in this codebase — it's a deliberate, documented convention. Polymorphic-shaped concepts (`AuditLog`, `DocumentEvent`, `Reminder.related_entity_type/id`) use plain `type` + `id` string/ULID columns instead. Attachments follow the same convention as three separate same-shape tables (`customer_attachments`/`debt_attachments`/`collection_case_attachments`) rather than one polymorphic table — match this pattern rather than introducing real polymorphism.
- **Sequential per-tenant reference numbers** (`DBT-000001`, `RCT-000001`, etc.) come from `ReferenceNumberService`, which row-locks (`lockForUpdate()`) a per-tenant counter — reuse it for any new numbered entity rather than inventing a second numbering scheme.
- **The four generated-document types** (Receipt, DemandLetter, Statement, Invoice) share one generic polymorphic-by-ID flow through `DocumentController` (`GET/POST /documents/{id}*` — show/download/history/share) on top of their own dedicated generation endpoints and Policies — don't special-case one document type in the generic layer.
- Receipts are **only** ever created as an automatic side effect of recording a Payment — there is no manual "Generate Receipt" endpoint, and none should be added without an explicit product decision.

### Mobile app structure

Feature-first under `mobile/lib/features/<feature>/{domain,data,presentation}`, plus `mobile/lib/core/` (network, theme, widgets, utils shared across features) and `mobile/lib/app/` (app shell, `GoRouter` route table). Data flow: `*_api.dart` (raw Dio call) → `*_repository.dart` (wraps Dio exceptions into `ApiException`) → Riverpod `Provider`/`FutureProvider`/`AsyncNotifierProvider` → `ConsumerWidget`/`ConsumerStatefulWidget` screen. Every repository follows the same `_guard<T>` try/catch-and-rethrow-as-`ApiException` pattern — copy it rather than inventing a new error-handling shape.

- `dioProvider` (`core/network/dio_client.dart`) attaches the bearer token via `AuthInterceptor`, which forces a logout on a **mid-session** 401 (never on a public endpoint's own 401, e.g. bad-password login).
- Routing uses flat `GoRoute` entries in `app/router/app_router.dart`; typed cross-route data goes through `context.push(path, extra: SomeTypedClass(...))`, not raw maps — see `ReminderEntityPreset` or `AddCaseReviewInput` for the pattern.
- Backend truth flows one way: the Flutter app **never** reimplements a business rule already enforced server-side (e.g. it doesn't guess at read-only/RBAC state client-side beyond disabling a button as a UX nicety — the server 403 is always the real enforcement).
- **Platform-channel plugins (`file_picker`, `image_picker`, `path_provider`) are wrapped behind an overridable `Provider<Future<T> Function()>`** (see `attachmentFilePickerProvider`/`attachmentCameraProvider` in `features/attachments/presentation/providers/attachment_providers.dart`) specifically so widget tests can override them with a fake — the platform channel doesn't exist in the test sandbox. Follow this pattern for any new plugin call that a widget test needs to exercise; on-device file writes (e.g. the actual `path_provider` save step) are accepted as untested territory throughout this codebase rather than faked.
- Widget tests that pump a screen taller than the default test viewport must set `tester.view.physicalSize`/`devicePixelRatio` (see any `_pumpScreen` helper) or off-screen list children won't materialize in the widget tree.

## Conventions

- Git: conventional commits (`feat(scope): ...`, `fix(scope): ...`, `docs(scope): ...`), committed directly to `main` in normal practice (long-lived `feature/*` branches exist only for large, explicitly-scoped efforts). A monorepo commit commonly spans both `deendoon/` and `mobile/` together when a feature needs both sides.
- Terminology: use "Business Owner" and "Platform Administrator" (never "Super Admin" alone — it's ambiguous between the two, and conflating them is a real security-bug class per `SRS/08`).
