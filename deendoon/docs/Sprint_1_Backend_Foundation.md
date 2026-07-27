# Sprint 1 — Backend Foundation

**Source of truth:**
- `docs/Mobile_UI_V1_Frozen.md`
- `docs/Backend_v2.1_UI_Mapping.md`
- `docs/Backend_v2.1_REST_API_Specification.md`
- `docs/Backend_v2.1_Database_Alignment.md`
- Git tag: `v1.0-architecture-complete`

**Implementation baseline:** the existing Deendoon Laravel application, not
a blank project. Per Product Owner direction, this sprint audited the
current codebase against the four approved documents above, reused every
existing component that already satisfies them, and implemented only what
was genuinely missing. No existing table, model, middleware, service, or
endpoint was rebuilt, renamed, or duplicated.

---

# 1. Laravel Project Structure

**Audit result: already satisfied — reused as-is, no changes.**

The existing project already follows a conventional, consistent Laravel
structure that matches every layer the approved architecture documents
require:

| Layer | Location | Convention |
|---|---|---|
| Controllers | `app/Http/Controllers/` | One per resource/module, thin — delegates to a Service |
| Services | `app/Services/` | Owns business logic; Controllers never contain it directly |
| Form Requests | `app/Http/Requests/` | One per validated action (39 already exist) |
| Resources | `app/Http/Resources/` | One per API-exposed entity (19 already exist) |
| Policies | `app/Policies/` | One per authorizable model (9 already exist) |
| Models | `app/Models/` | Eloquent models, tenant-scoped via a shared trait |
| Middleware | `app/Http/Middleware/` | Custom cross-cutting concerns only |
| Enums | `app/Enums/` | Fixed classification values (e.g., audit actions, document types) |
| Traits | `app/Traits/` | Shared behavior (e.g., the API response envelope) |
| Routes | `routes/api.php`, `routes/console.php`, `routes/web.php` | API routes versioned under `v1` |

**Naming conventions already in use, carried forward:** singular
PascalCase for models (`Customer`, `Debt`), `{Model}Controller` /
`{Model}Resource` / `{Model}Policy` for their respective layers,
`{Verb}{Model}Request` for Form Requests (e.g., `LoginRequest`).

**Layer responsibilities (already established, unchanged):** Controller →
Service → Model. Controllers authorize the request and shape the HTTP
response; Services own business rules and orchestrate model writes;
Models represent persisted state and tenant scoping only. No Repository
layer exists, and none is introduced — this project's Service layer
already serves that purpose, and adding a Repository layer on top would
duplicate functionality the Service layer already provides.

---

# 2. Environment Configuration

**Audit result: already satisfied — reused as-is, no changes.**

`.env.example` already documents every environment variable this
foundation depends on, with no secret values committed. No new variables
were required by anything in scope for this sprint.

| Variable | Purpose | Dev default | Staging/Production expectation |
|---|---|---|---|
| `APP_ENV` | Environment name | `local` | `staging` \| `production` |
| `APP_DEBUG` | Error detail exposure | `true` | Must be `false` |
| `APP_URL` | Base application URL | `http://localhost` | The real public URL |
| `APP_KEY` | Encryption key | Generated per install | Generated per install, never shared across environments |
| `DB_CONNECTION` / `DB_HOST` / `DB_PORT` / `DB_DATABASE` / `DB_USERNAME` / `DB_PASSWORD` | Database connection | Local PostgreSQL | Environment-specific credentials |
| `DB_SSLMODE` | Database connection encryption | `prefer` | Should be enforced in production |
| `SESSION_DRIVER` / `SESSION_SECURE_COOKIE` | Session storage | `database` | `SESSION_SECURE_COOKIE=true` behind HTTPS |
| `QUEUE_CONNECTION` | Queue driver | `database` | Unchanged — no queue worker is required by the approved architecture |
| `CACHE_STORE` | Cache driver | `database` | Environment-specific |
| `CORS_ALLOWED_ORIGINS` | Allowed browser origins | Empty (fail closed) | The real Flutter/web origins |
| `SANCTUM_IDLE_TIMEOUT` | Sliding token idle window, minutes | `60` | Per Product Owner policy |
| `API_RATE_LIMIT_PER_MINUTE` | General API throttle | `60` | Per Product Owner policy |
| `TRUSTED_PROXIES` | Reverse-proxy trust | Unset (trust nothing) | The real load balancer IP/CIDR |
| `LOG_CHANNEL` / `LOG_LEVEL` | Logging | `stack` / `debug` | `LOG_LEVEL` should be raised in production |

This table matches the environment configuration already audited and
approved in `docs/Production_Readiness.md` from the prior Backend
Excellence phase; no new variable was introduced for Sprint 1.

---

# 3. Authentication Foundation

**Audit result: Login and Logout already satisfied — reused as-is.
Refresh Token was genuinely missing — implemented this sprint.**

## What already existed

`app/Http/Controllers/AuthController.php` already implements `login()`
and `logout()` exactly as the approved API specification's intent
requires: `login()` verifies credentials, issues a Sanctum personal
access token, and records an audit log entry; `logout()` revokes the
caller's current token and records an audit log entry. Both are reused
unchanged.

## Reconciling the approved API Specification with the existing token model

`Backend_v2.1_REST_API_Specification.md` §2 describes a conceptually
distinct `access_token` / `refresh_token` pair with an `expires_in`
value. The existing, already-approved authentication implementation uses
a single Sanctum bearer token instead, combined with a sliding idle
timeout (`EnsureTokenIsNotIdle`) that deletes the token outright once it
goes idle past `SANCTUM_IDLE_TIMEOUT`. These are two different models,
and reconciling them required a decision, made per the Product Owner's
explicit direction that the existing codebase is the implementation
baseline:

- **No second token type was introduced.** Sanctum has no built-in
  refresh-token concept, and introducing one would mean either a new
  token table or a new column on the existing one — a schema change not
  required by any approved document, purely to match a field name.
- **No existing response field was renamed.** `login()` and `register()`
  already return `{ user, token }`; changing this to `{ access_token,
  refresh_token, expires_in }` would break every existing caller of an
  endpoint that already works in production, for no functional gain.
- **Refresh is implemented as token rotation**, reusing the exact
  mechanism `login()`/`register()` already use (`createToken('auth_token')
  ->plainTextToken`) and returning the same `{ user, token }` shape. A
  caller with a still-valid (not yet idle-expired) token exchanges it for
  a fresh one, resetting the idle window, without re-entering credentials
  — the same functional outcome the approved specification's refresh
  endpoint exists to provide, delivered through the existing token model
  rather than a new one.

## What was implemented

- **`AuthController::refresh()`** (`app/Http/Controllers/AuthController.php`)
  — deletes the caller's current token and issues a new one via the
  authenticated user already resolved by `auth:sanctum`.
- **Route:** `POST /api/v1/refresh`, added to the existing
  `auth:sanctum`-protected route group in `routes/api.php`, immediately
  alongside the existing `logout` route — not under a new `/auth/`
  sub-path, to stay consistent with every other existing auth route
  (`/api/v1/login`, `/api/v1/logout`, etc.), none of which use that
  prefix.
- **Tests:** `tests/Feature/Auth/RefreshTokenTest.php` — 4 tests
  covering successful refresh, old-token invalidation (asserted against
  the database directly, consistent with this suite's documented
  Sanctum guard-caching behavior in same-method sequential requests),
  the new token authenticating successfully, and the unauthenticated
  rejection case. All pass; the full existing suite (369 tests) passes
  unchanged alongside them.

No Form Request was added for `refresh()` — the endpoint takes no
request body, only the caller's existing bearer token, so no new
validation rules were needed.

---

# 4. Authorization

**Audit result: already satisfied — reused as-is, no changes.**

## Roles

The existing `database/seeders/RoleSeeder.php` already seeds five roles
via `spatie/laravel-permission`: `admin`, `sales_finance`, `customer`,
`collection_officer`, `deendoon_platform_administrator`. The three roles
named throughout the approved v2.1 documents map directly onto three of
these — they are the same roles under business-facing names, not new
roles to create:

| v2.1 document role name | Existing seeded role |
|---|---|
| Business Owner/Administrator | `admin` |
| Sales & Finance Staff | `sales_finance` |
| Collections Staff | `collection_officer` |

The remaining two existing roles (`customer`, `deendoon_platform_
administrator`) are not referenced anywhere in `Mobile_UI_V1_Frozen.md`,
because the frozen mobile UI has no customer-facing or platform-admin
screens. Per this sprint's explicit instruction not to duplicate or
remove existing functionality, both roles are left exactly as they are —
they simply have no new permission grants added under this UI, since
none is required.

## Permissions

Authorization is already implemented as `Gate::define()` closures
(`admin-only`, `sales-finance-only`, `customer-only`, `view-reports`,
`view-dashboard`) plus per-model `Policy` classes registered in
`AppServiceProvider::boot()`, checked via `Gate::authorize()` /
`$this->authorize()` in Controllers. This already satisfies every
Permissions requirement in `Backend_v2.1_UI_Mapping.md` §10 (each
expressed as "any of" a role list) — no additional granular permission
system is required or introduced.

## Middleware strategy

The existing project deliberately authorizes at the Controller/Policy
layer, not via route-level `role:`/`permission:` middleware — this was
independently reviewed and confirmed correct in a prior Engineering
Excellence audit (`docs/Engineering_Excellence.md`), and is retained here
as "one consistent architecture" rather than introducing a second,
parallel authorization style for new endpoints.

---

# 5. Database Foundation

**Audit result: already satisfied for everything in this sprint's scope
— reused as-is, no changes.**

The following tables, required by `Backend_v2.1_Database_Alignment.md`'s
foundation-level entities (Tenants, Users, Auth Tokens), already exist
via existing migrations:

| Table | Migration | Status |
|---|---|---|
| `users` | `0001_01_01_000000_create_users_table.php` | Exists |
| `tenants` | `2026_07_25_140000_create_tenants_table.php` | Exists |
| `users.tenant_id` | `2026_07_25_140100_add_tenant_id_to_users_table.php` | Exists |
| `personal_access_tokens` (Auth Tokens) | `2026_07_25_054131_create_personal_access_tokens_table.php` | Exists |
| `permission`/`role` tables (RBAC) | `2026_07_25_095446_create_permission_tables.php` | Exists |
| `audit_log` | `2026_07_26_090000_create_audit_log_table.php` | Exists |

Every business-module table required by `Backend_v2.1_Database_Alignment.md`
§3 for Customers, Debts, Payments, Cases, Reminders, and Documents
already exists as well, but implementing or modifying any of them is
explicitly out of scope for this sprint per the Sprint 1 instructions
("Do not implement Customers/Cases/Reminders/Documents") — they are
noted here only to confirm nothing in this sprint's foundation scope
required a new migration.

**Seeders:** `database/seeders/RoleSeeder.php` already seeds every role
this sprint's Authorization section depends on; `DatabaseSeeder.php`
already invokes it. No change.

**Factories:** `database/factories/UserFactory.php` already exists and is
already used throughout the test suite (including the new
`RefreshTokenTest`). No change.

No migration, seeder, or factory was added in this sprint.

---

# 6. Base Application Architecture

**Audit result: already satisfied — reused as-is, no changes.**

| Component | Status | Evidence |
|---|---|---|
| Controllers | Reused | `app/Http/Controllers/Controller.php` base class (uses `AuthorizesRequests`), extended by every controller including `AuthController` |
| Services | Reused | `app/Services/` — e.g., `AuditLogService`, `SecurityEventLogger`, `PasswordResetService`, all consumed by `AuthController` |
| Repositories | Not used, by design | Confirmed as a deliberate, correct choice in the prior Engineering Excellence audit — the Service layer already fulfills this role; not introduced |
| Requests | Reused | `app/Http/Requests/` — `LoginRequest`, `RegisterRequest`, etc.; no new Request needed for `refresh()` |
| Resources | Reused | `app/Http/Resources/UserResource.php`, reused unchanged in the new `refresh()` response |
| Policies | Reused | `app/Policies/` — none needed for this sprint's one new endpoint, since `refresh()` acts only on the caller's own token |
| Middleware | Reused | `EnsureTokenIsNotIdle`, `SecurityHeaders`, both already registered globally in `bootstrap/app.php` |
| Jobs | Not used, by design | No `ShouldQueue` job exists anywhere in the project, consistent with the already-approved fully-synchronous architecture decision (`docs/Performance_Architecture.md`); nothing in this sprint's scope requires one |
| Events | Reused pattern, no new event added | `CreditLimitReached`/`PromiseBroken` remain the established pattern for future business-module work; this sprint's `refresh()` action has no approved-document requirement to fire a domain event |

One consistent architecture — Controller → Service → Model, with
Form Requests for validation and Resources for output shaping — is
retained throughout; the new `refresh()` endpoint follows it exactly.

---

# 7. API Foundation

**Audit result: already satisfied — reused as-is, no changes.**

| Requirement | Status | Evidence |
|---|---|---|
| API Versioning | Already implemented | `routes/api.php` already wraps every route in `Route::prefix('v1')`, matching `Backend_v2.1_REST_API_Specification.md` §12's `/api/v1/` requirement exactly |
| Standard Response Format | Already implemented | `app/Traits/ApiResponse.php` already provides the `{ success, message, data, errors }` envelope via `successResponse()`/`errorResponse()`, used by `AuthController` and every other controller; the new `refresh()` method uses it unchanged |
| Error Handling | Already implemented | `bootstrap/app.php` already normalizes `ValidationException`, `AuthenticationException`, `ThrottleRequestsException`, and `AccessDeniedHttpException` onto the same envelope — matching `Backend_v2.1_REST_API_Specification.md` §9 exactly |
| Validation Strategy | Already implemented | Form Requests validate every request body; `refresh()` needed none, since it takes no input |
| Pagination Strategy | Already implemented | The existing `paginationMeta()` pattern (current_page/per_page/total/last_page) already matches `Backend_v2.1_REST_API_Specification.md` §10 exactly |

No change was required anywhere in this section — the existing API
foundation already matches the approved specification's contract.

---

# 8. Storage Foundation

**Audit result: already satisfied — reused as-is, no changes.**

`config/filesystems.php` already defines `local`, `public`, and `s3`
disks, satisfying "Local Storage, Public Storage, Future Cloud Storage
compatibility" without any provider-specific implementation being forced
— the `s3` disk is configured but not required to be active. Nothing in
this sprint's foundation scope (Authentication, Authorization, API
plumbing) touches file storage; the Documents module's own storage
behavior is explicitly out of scope for this sprint and is already
tracked separately in `docs/Production_Readiness.md`.

---

# 9. Logging & Audit Foundation

**Audit result: already satisfied — reused as-is, no changes.**

- **Application Logging:** `config/logging.php` already defines `stack`,
  `single`, `daily`, `slack`, and `papertrail` channels.
- **Audit Logging:** a dedicated `security` channel already exists
  (`storage/logs/security.log`), alongside `app/Models/AuditLog.php`,
  `app/Services/AuditLogService.php`, and the `App\Enums\AuditAction`
  enum. `AuthController::login()` and `logout()` already record `Login`/
  `Logout` audit entries via this service. `refresh()` deliberately does
  **not** add a new audit entry: no approved document requires token
  refresh to be an audited event (`Backend_v2.1_Database_Alignment.md`
  §8 scopes audit requirements to Case Activity, Document Events, and
  Sent Messages only), and adding one would have required a new
  `AuditAction` enum case and a corresponding change to the existing
  `audit_log.action` check constraint — a database change not required
  by anything in scope.
- **Exception Logging:** already handled by Laravel's default exception
  reporting through the configured log channels; unchanged.

---

# 10. Sprint Deliverables

- [x] Audited all ten foundation areas against the four approved
      architecture documents.
- [x] Confirmed Laravel Project Structure, Environment Configuration,
      Authorization, Database Foundation, Base Application Architecture,
      API Foundation, Storage Foundation, and Logging & Audit Foundation
      are already fully satisfied by the existing codebase — no changes
      made to any of them.
- [x] Identified the one genuine gap: a Refresh Token endpoint.
- [x] Implemented `AuthController::refresh()`.
- [x] Added the `POST /api/v1/refresh` route to the existing
      authenticated route group.
- [x] Documented the reconciliation between the approved API
      specification's access/refresh-token model and the existing,
      already-approved single-bearer-token model.
- [x] Documented the role-name mapping between the v2.1 architecture
      documents' business-facing role names and the existing seeded
      roles.
- [x] Added `tests/Feature/Auth/RefreshTokenTest.php` (4 tests).
- [x] Ran the full existing test suite (369 tests, 962 assertions) —
      100% passing, zero regressions.

---

## Sprint Status

**Completed**

- Full ten-area foundation audit against the approved v2.1 architecture.
- Refresh Token endpoint implemented, tested, and verified alongside the
  full existing test suite with zero regressions.
- Role-name and token-model reconciliation documented for future sprints
  to reference, so this decision is not re-litigated per module.

**Pending Sprint 2**

- No foundation work is deferred — everything identified as missing in
  this sprint was implemented. Sprint 2 begins directly on business-module
  implementation (Customers, Debts, Cases — Sprint 1 of
  `Backend_v2.1_UI_Mapping.md` §13's roadmap), per that document's
  approved, unmodified priority order.

**Estimated implementation readiness**

Foundation is 100% implementation-ready. No architectural blocker,
missing dependency, or unresolved reconciliation remains between the four
approved documents and the existing codebase for anything in this
sprint's scope.
