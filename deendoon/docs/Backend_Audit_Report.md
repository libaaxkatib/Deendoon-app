# Deendoon Backend — Full Audit Report

**Date:** 2026-07-29
**Scope:** Complete, direct read of the Laravel backend at `deendoon/` (187 PHP files under `app/`, all 33 migrations, all 46 Form Requests, all 23 API Resources, all 11 Policies, all routes, all 26 Services, all 26 Models), cross-referenced against the Flutter mobile client (`mobile/`) and the project's own prior living documentation (`deendoon/docs/`) and frozen SRS (`SRS/01`–`11`).
**Nature of this report:** analysis only. No code was modified, refactored, or implemented as part of this audit, per instruction.
**Companion document:** [`Backend_Architecture_Reference.md`](./Backend_Architecture_Reference.md) — the permanent structural reference this audit's findings feed into. Where a section below would otherwise repeat that document's detail, it's summarized here with a pointer instead.

---

## Executive Summary

The backend is **substantially larger and more mature than the four Flutter modules currently built against it** (Auth, Customers, Debts, Collection Cases, Dashboard). It implements a second, later specification layer ("Backend v2.1," driven by a frozen mobile UI spec) on top of the original 11-document SRS — adding a Reminder Center, polymorphic Documents, Calendar, Search, Message Templates/Delivery, and full Administration — none of which the current Flutter app calls yet. The backend itself has already been through six internal "Sprint" audits (Security, Database, Performance, Engineering, Testing, Production Readiness), all concluding **GO**, with a small set of explicitly approved-but-not-yet-implemented improvements tracked in `docs/`. This audit does not find reason to disagree with those prior conclusions; it adds:

1. A complete, verified **endpoint-by-endpoint inventory** (§16) — something no single existing document currently provides in one place.
2. Two **new, previously unflagged authorization gaps** (§21) — `MessageController::templates()`/`render()` have no role/policy check at all, unlike every sibling action in the same controller.
3. A precise **backend-vs-Flutter usage gap** (§17) — most of the API surface has zero mobile consumer today, which is a fact worth tracking deliberately rather than discovering by accident later.
4. Consolidated, cross-checked **performance/N+1/duplicate-logic findings** (§18–20), largely confirming issues this project's own prior audits already found and tracked, plus one new item (repeated ad-hoc pagination-metadata construction across 7 controllers).

**No critical, previously-unknown defect was found.** The codebase is disciplined, consistently layered, and unusually well self-documented (nearly every non-trivial method has a docblock tracing to a specific FR/BRL/DD). The findings below are refinements to an already-sound system, not evidence of a system in poor shape.

---

## 1. Folder Structure

Summarized in full in [Backend_Architecture_Reference.md §2](./Backend_Architecture_Reference.md#2-folder-structure). Key audit observations:

- **No `app/Repositories/` directory exists** — this project uses Controller → Service → Eloquent Model only (see §7).
- A stray `app/Http/` directory exists at the **repository root** (`C:\Users\hp\Deendoon-app\app\Http`), one level above the actual Laravel application (`deendoon/`). It is empty of real content and appears to be leftover scaffolding unrelated to the working application — worth confirming with the team whether it can be deleted; it is not part of the Laravel app (`deendoon/`'s own `app/Http/` is the real one, verified via `composer.json`'s PSR-4 autoload root).
- `docs/` (13 files) is unusually rich for a project this size — a genuine asset, not typical technical debt. Any future work should read the relevant `docs/*.md` file before touching an area it covers, since several represent explicit Product Owner decisions that override what might otherwise look like an obvious "fix."

---

## 2. Database Schema

Full table-by-table detail in [Backend_Architecture_Reference.md §4](./Backend_Architecture_Reference.md#4-database-schema). Audit-relevant findings:

- **33 migrations, PostgreSQL-targeted**, CHECK constraints consistently guarded for pgsql-only execution (correctly degrade to Form-Request-only validation under the SQLite test driver).
- **Confirmed schema anomaly**: `reminders.related_case_id` and `sent_messages.case_id` both declare an FK to `collection_cases.id` in migrations timestamped *before* `2026_07_31_090000_create_collection_cases_table.php`. This needs verification against the actual deployed migration run order — it is either harmless (run order differs from filename order) or a latent defect that only "works" today because the test suite runs on SQLite, which doesn't enforce FK target existence at migration time. **Recommend verifying this against a real PostgreSQL migration run before the next production deploy.**
- **Confirmed promised-but-undelivered FK**: `follow_up_history.collection_case_id`'s original migration comment says an FK will be added "once the target table exists" — `collection_cases` now exists, but no later migration ever added it.
- Two schema decisions are **permanent and accepted**, not backlog items (`docs/Database_Architecture.md`): `users.id` stays `bigint` (no FK from any actor column to it, anywhere in the schema); two `system_settings` numeric columns remain without a CHECK constraint until their consuming automation is built.
- PostgreSQL Row-Level Security is **deliberately not adopted for V1** (`docs/Tenant_Isolation.md`) — application-layer isolation only.

---

## 3. Models

Full model-by-model detail in [Backend_Architecture_Reference.md §5](./Backend_Architecture_Reference.md#5-models). Audit-relevant findings:

- 26 models, 100% consistent use of PHP 8 attribute-based `#[Fillable]` and method-based `casts()` — no stray `protected $fillable`/`$casts` property style anywhere.
- **19 of 26 tenant-owned models use `BelongsToTenant`.** Of the 7 that don't, 5 have an explicit docblock justification (`Tenant`, `ImportRow`, `ProfessionalCollectionRequest`, `RequestMessage`, `PasswordResetToken`). **Two do not: `AuditLog` and `User`.** Both hold a `tenant_id` column directly (in `AuditLog`'s case, it's even in the model's own `Fillable` list). Neither model's docblock explains the omission the way the other five do. This is the single most important verification item in this report — see §21.
- `Customer::remainingCredit()` is the one true computed business-logic accessor across the entire model layer; everything else is relationships, casts, or immutability guards (`update()`/`delete()` overridden to throw on 7 document/log-shaped models).

---

## 4. Controllers

30 controllers, all thin (resolve model via route binding → authorize → delegate to Service → wrap in Resource). Verified this pattern holds with **one confirmed exception**: `CustomerImportController` contains real business logic (`validateRow()`, `processRow()`, `rowToArray()`) directly in the controller — already identified and approved for extraction into a dedicated `ImportService` in `docs/Engineering_Excellence.md`, not yet done.

Two controller-level authorization gaps found during this audit that were **not** previously documented — see §21 for detail:
- `MessageController::templates()` and `MessageController::render()` — no `$this->authorize()`/`Gate::authorize()` call at all.

One confirmed no-op endpoint: `CollectionCaseController::update()` (`PUT /collection-cases/{case}`) validates and updates nothing — `UpdateCollectionCaseRequest::rules()` is `[]`, and the controller method only re-returns the unchanged resource after a status check. Its own docblock already states no approved editable field exists yet (an open SRS gap) — this is a confirmed, intentional placeholder, not a bug, but worth flagging so a future engineer doesn't assume it's broken when they notice a `PUT` that changes nothing.

---

## 5. Services

26 service classes, full catalog and responsibilities in [Backend_Architecture_Reference.md §8](./Backend_Architecture_Reference.md#8-service-layer-26-classes). This is where all real business logic lives, consistently. Notable audit findings:

- `App\Services\Delivery\InternalWhatsAppChannel`/`InternalSmsChannel` are **confirmed stubs** — `deliver()` is a hardcoded `return 'sent'`, no HTTP client or SDK call of any kind. This is by design (an "External Integrations Policy" explicitly defers real gateway selection), not an oversight, but it means **no reminder or document share is ever actually delivered to a real phone today** — every "sent" message is simulated. Any stakeholder-facing claim about WhatsApp/SMS notifications should be qualified accordingly until a real provider is wired behind `MessageDeliveryChannel`.
- `ReferenceNumberService::next()` loads **every** existing reference number for a given tenant+prefix into memory to compute the next value — scales linearly with volume per tenant per entity type. Not a problem at current expected scale, but worth a targeted look if any single tenant accumulates a very large number of one entity type (e.g., tens of thousands of Debts).
- `SmartReminderEngine::isDueForDelivery()` issues one `exists()` query per Reminder when called in a loop (as `FireDueReminders` does) — a real, if currently small-scale, N+1 pattern (see §20).

---

## 6. Repositories

**None exist.** Confirmed via full directory listing — no `app/Repositories/` folder, no repository-interface pattern anywhere in `app/Contracts/` (the one contract that exists, `MessageDeliveryChannel`, is a delivery-channel strategy interface, not a repository). Services query Eloquent models directly. This is a **consistent, deliberate architectural choice** already accepted in `docs/Engineering_Excellence.md` — not a gap to fill.

---

## 7. Policies / Gates

Full detail in [Backend_Architecture_Reference.md §6.1](./Backend_Architecture_Reference.md#61-policies-11-one-per-protected-model). 11 policies, all explicitly registered via `Gate::policy()` in `AppServiceProvider::boot()` (no auto-discovery reliance, even though it would work). 5 raw `Gate::define()` closures for endpoints with no dedicated Eloquent model (`admin-only`, `sales-finance-only`, `customer-only`, `view-reports`, `view-dashboard`).

**Audit finding:** every policy except `NotificationPolicy` and `UserPolicy` is purely role-based (no in-class tenant-ownership check), relying entirely on the model's `BelongsToTenant` global scope to have already excluded other tenants' rows before the policy method is even reached. This is architecturally sound **as long as every query reaching a policy check went through a tenant-scoped model** — which is true today, but is a convention to actively preserve (see §10 of the Architecture Reference), not a structural guarantee.

---

## 8. Middleware

Full detail in [Backend_Architecture_Reference.md §7](./Backend_Architecture_Reference.md#7-middleware). Two custom middleware: `EnsureTokenIsNotIdle` (sliding Sanctum idle timeout, correctly `prepend()`-ed ahead of the rate limiter to avoid a documented ordering bug) and `SecurityHeaders` (additive response headers only). Both are well-reasoned and already covered by feature tests per the project's own testing audit.

**Audit finding (operational, not code):** `TRUSTED_PROXIES` is opt-in and unset by default. Every IP-keyed rate limiter in this project (login/register/forgot-password/reset-password) silently protects the load balancer's IP instead of the real client's the moment this app sits behind any reverse proxy without this being explicitly configured. This is already flagged in `docs/Security.md`'s deployment checklist — repeating it here because it's the kind of gap that's invisible until an incident makes it obvious.

---

## 9. Authentication

Full detail in [Backend_Architecture_Reference.md §6.3](./Backend_Architecture_Reference.md#63-authentication). Sanctum Bearer-token mode, Argon2id hashing, sliding idle-timeout (not Sanctum's native fixed TTL), full token-revocation coverage on logout/idle/password-reset/role-change/deactivation.

**Audit finding:** `POST /register` is public, unauthenticated, and creates a real `users` row with **no tenant assignment and no role** (verified from `AuthController::register()` — it sets only `name`/`email`/`password`; `tenant_id` isn't set because `User` doesn't use `BelongsToTenant`'s auto-fill, and no role is assigned). A user created this way can authenticate successfully but is authorized for **nothing** (every Policy/Gate in the system requires a role or a matching non-null `tenant_id`, and this account has neither). Functionally inert today, but:
- It's unclear whether this endpoint is meant to exist in production at all, given every other user-creation path (`AdminUserController::store()`) is the actual approved administrative flow (FR-066) and always assigns both a tenant and a role.
- The Flutter mapping agent confirmed `ApiEndpoints.register` is defined in the mobile app's constants but **never called** — no registration screen exists in the app's router either.
- **Recommend an explicit decision**: either document `POST /register`'s intended purpose (e.g., "first Tenant + Admin bootstrap," in which case it should probably also create the `Tenant` row and assign the `admin` role, which it currently does neither of) or gate/remove it from the public production surface.

---

## 10. Roles & Permissions

Full detail in [Backend_Architecture_Reference.md §6.2](./Backend_Architecture_Reference.md#62-roles--permissions). Five seeded roles, role-only authorization throughout.

**Audit finding:** `spatie/laravel-permission`'s `Permission` model, migration, and config are fully installed but have **zero references anywhere in application code** (confirmed by a repo-wide grep for `Permission::`/`hasPermissionTo`). This isn't inconsistent with any documentation, but a future engineer skimming `config/permission.php` and the `permissions` table could reasonably (and incorrectly) assume fine-grained permissions are in use somewhere. Worth a one-line note in onboarding material that this project's RBAC is role-only by deliberate choice.

---

## 11. API Resources

Full detail in [Backend_Architecture_Reference.md](./Backend_Architecture_Reference.md) (referenced from the Requests/Resources research). 23 Resource classes. **Confirmed: none use `whenLoaded()`, `when()`, or `mergeWhen()`** — every field is unconditionally present in every response. `CollectionCaseResource` is the only one that reaches across a relationship (`debt.customer`), and it does so via null-safe `?->` chaining relying on the controller's eager-load, not a conditional-inclusion helper — verified the controller (`CollectionCaseController::index()`/`show()`) does eager-load `debt.customer` in both places that build this Resource, so no N+1 results from this pattern today, but any **new** call site constructing a `CollectionCaseResource` without eager-loading `debt.customer` would silently trigger one query per case.

---

## 12. Validation Requests

46 FormRequest classes. **Confirmed: every single one's `authorize()` returns a bare `true`** — this project puts 100% of authorization in the Controller (via Policy/Gate), never in the Request. This is a consistent, correct pattern (Requests validate shape, Controllers/Policies decide access) — flagging it explicitly because it means a missing `$this->authorize()` call in a Controller (as found in §21) has **no second line of defense** in the Request layer.

Two Requests worth noting for future field-level work:
- `StoreReminderRequest`/`UpdateReminderRequest` validate `related_entity_id` as a plain string with no `exists:` rule against whichever table `related_entity_type` names — meaning a Reminder can be created pointing at a non-existent Customer/Debt/CollectionCase/PromiseToPay ID. Given `related_entity_type`/`related_entity_id` are polymorphic-by-convention (not a real `morphTo`), this can't be a simple `exists:` rule without a custom validator resolving the target table dynamically — flagging as a validation gap worth a deliberate decision, not silently adding one.
- `AssignUserRoleRequest`/`CreateUserRequest` validate `role` against a **hardcoded** PHP array (`['admin','sales_finance','customer','collection_officer']`) rather than checking the `roles` table dynamically. Correct today (matches the fixed, small role set), but means adding a new role in the database wouldn't automatically become assignable through this endpoint — a future engineer adding a role must remember to also update this whitelist in two Request classes.

---

## 13. Routes

`routes/web.php` contains only the default Laravel welcome page — **no web-facing routes exist for this application at all**. `routes/api.php` contains every business endpoint (~109, enumerated in full in §16), entirely under `Route::prefix('v1')`, with `auth:sanctum` wrapping everything except `register`/`login`/`forgot-password`/`reset-password`. `routes/console.php` contains only the stock `inspire` Artisan command — no `Schedule::` calls exist anywhere (see §15).

---

## 14. Events / Jobs / Notifications

Full detail in [Backend_Architecture_Reference.md §9](./Backend_Architecture_Reference.md#9-domain-events-listeners-scheduled-commands) and the project's own `docs/Domain_Events.md` (cross-checked against code during this audit and found accurate — no staleness identified).

- **2 dispatched events** (`CreditLimitReached`, `PromiseBroken`), both synchronous, neither `ShouldQueue`.
- **1 scheduled-job-shaped Artisan command** (`reminders:fire-due` / `FireDueReminders`) that is **not actually scheduled anywhere** — no `Schedule::command()` call, no `app/Console/Kernel.php` at all in this Laravel 13 app. This is a deliberate consequence of the accepted "no queue/Redis/scheduler infrastructure" decision (`docs/Performance_Architecture.md`), not an oversight, but it means **the Reminder Center's core promise — "N minutes/hours/days before due date, deliver automatically" — does not currently happen unless a human or an external cron entry invokes this command.** This is the single largest functional gap between what the frozen Mobile UI spec (`Mobile_UI_V1_Frozen.md` §7.5, §8 "Background Jobs — Reminder Scheduler") describes as required and what actually runs today. Flagging prominently since it's easy to miss (the command exists, is tested, and looks "done" until you check whether anything invokes it).
- **0 queued jobs** anywhere in the codebase (`grep -r ShouldQueue app/` returns nothing) — confirmed consistent with the accepted synchronous-architecture decision.

---

## 15. Existing API Endpoints — Full Inventory

**~109 endpoints**, grouped by module in the order they appear in `routes/api.php`. "Permission" reflects the actual role/Policy/Gate check found in the Controller (or "none — self-scoped" where the endpoint relies on a query filter rather than an explicit check). "Flutter" reflects the confirmed result of grepping the entire `mobile/lib` tree for Dio calls (see the companion Architecture Reference §1 for the tech-stack note that no other client exists in this repository).

### 15.1 Authentication (public)

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/register` | POST | Create a user account | None | None | `RegisterRequest`: name, email (unique), password (confirmed, policy default) | `UserResource` + token, 201 | **Constant defined, never called** (see §9) |
| `/login` | POST | Authenticate, issue token | None | None | `LoginRequest`: email, password | `UserResource` + token | auth |
| `/forgot-password` | POST | Request password reset | None | None | `ForgotPasswordRequest`: email | Generic message, always 200 | auth |
| `/reset-password` | POST | Complete password reset | None | None | `ResetPasswordRequest`: email, token, password (confirmed) | Generic message | auth |

### 15.2 Authentication (authenticated)

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/logout` | POST | Revoke current token | sanctum | any authenticated user | none | null | auth |
| `/refresh` | POST | Rotate current token | sanctum | any authenticated user | none | `UserResource` + new token | auth |

### 15.3 Customers

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/customers` | GET | List/search/filter customers | sanctum | `CustomerPolicy::viewAny` (admin, sales_finance) | query: search, status, riskLevel, creditScoreMin/Max, includeArchived, perPage | `CustomerResource[]` + pagination | customers |
| `/customers` | POST | Create customer | sanctum | `::create` | `StoreCustomerRequest`: name, phone, credit_limit (≥0) | `CustomerResource` + duplicate warning, 201 | not detected |
| `/customers/check-duplicate` | POST | Pre-check for likely duplicate | sanctum | `::viewAny` | `CheckCustomerDuplicateRequest`: name, phone | `{duplicate_found, warning}` | not detected |
| `/customers/import` | POST | Upload & preview bulk import | sanctum | `::import` | `ImportCustomersRequest`: file (xlsx/xls) | batch_id + parsed rows, 201 | not detected |
| `/customers/import/{batch}/commit` | POST | Commit a previewed import | sanctum | `::import` | `CommitCustomerImportRequest`: resolutions[] | per-row outcomes | not detected |
| `/customers/{customer}/restore` | POST | Restore archived customer | sanctum | `::restore` | none | `CustomerResource` | not detected |
| `/customers/{customer}` | GET | Customer detail | sanctum | `::view` | none | `CustomerResource` | customers |
| `/customers/{customer}` | PUT | Update customer | sanctum | `::update` | `UpdateCustomerRequest`: name, phone, credit_limit | `CustomerResource` + warning | not detected |
| `/customers/{customer}/archive` | POST | Soft-delete customer | sanctum | `::archive` | none | null | not detected |
| `/customers/{customer}/status` | PATCH | Change customer status | sanctum | `::update` | `UpdateCustomerStatusRequest`: customer_status (7-value enum) | `CustomerResource` | not detected |
| `/customers/{customer}/credit-profile` | GET | Credit profile view | sanctum | `::view` | none | `CustomerResource` | not detected |
| `/customers/{customer}/credit-limit` | PATCH | Change credit limit | sanctum | `::update` | `UpdateCustomerCreditLimitRequest`: credit_limit | `CustomerResource` | not detected |
| `/customers/{customer}/credit-score` | GET | Read credit score | sanctum | `::viewCreditScore` | none | `{credit_score, credit_score_band}` | not detected |
| `/customers/{customer}/risk-level` | PATCH | Change risk level | sanctum | `::updateRiskLevel` | `UpdateRiskLevelRequest`: risk_level (high/medium/low) | `CustomerResource` | not detected |
| `/customers/{customer}/debts` | POST | Create debt for customer | sanctum | `DebtPolicy::create` | `StoreDebtRequest`: amount (>0), due_date, notes | `DebtResource` + credit-limit warning, 201 | not detected |
| `/customers/{customer}/payments` | GET | Payment history across debts | sanctum | `CustomerPolicy::view` | none | `PaymentResource[]` | customers |
| `/customers/{customer}/documents` | GET | All documents for customer | sanctum | `::view` | none | combined document array | not detected |
| `/customers/{customer}/statements` | POST | Generate statement of account | sanctum | `::generateDocuments` | `GenerateStatementRequest`: (none) | `StatementResource`, 201 | not detected |

### 15.4 Debts

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/debts` | GET | List/filter debts | sanctum | `DebtPolicy::viewAny` | customer_id, status, dateFrom/To, includeArchived | `DebtResource[]` + pagination | debts |
| `/debts/{debt}` | GET | Debt detail | sanctum | `::view` | none | `DebtResource` | debts |
| `/debts/{debt}` | PUT | Update non-financial fields | sanctum | `::update` | `UpdateDebtRequest`: due_date, notes (amount deliberately excluded) | `DebtResource` | not detected |
| `/debts/{debt}/status` | PATCH | Manual status change | sanctum | `::update` | `UpdateDebtStatusRequest`: debt_status IN (cancelled, written_off) | `DebtResource` | not detected |
| `/debts/{debt}/archive` | POST | Soft-delete debt | sanctum | `::archive` | none | null | not detected |
| `/debts/{debt}/restore` | POST | Restore archived debt | sanctum | `::restore` | none | `DebtResource` | not detected |
| `/debts/{debt}/timeline` | GET | FR-024 8-stage timeline | sanctum | `::view` | none | stage array | debts |
| `/debts/{debt}/recovery-stage` | PATCH | Manual stage override | sanctum | `::update` | `UpdateDebtRecoveryStageRequest`: recovery_stage (1-6), reason (required) | `DebtResource` | not detected |
| `/debts/{debt}/followup-history` | GET | Follow-up log | sanctum | `::view` | none | `FollowUpHistoryResource[]` | not detected |
| `/debts/{debt}/reminders/whatsapp` | POST | Log manual WhatsApp reminder | sanctum | `::manageRecovery` | `SendManualReminderRequest`: details (nullable) | `DebtResource` | not detected |
| `/debts/{debt}/reminders/sms` | POST | Log manual SMS reminder | sanctum | `::manageRecovery` | same | `DebtResource` | not detected |
| `/debts/{debt}/reminders/call` | POST | Log phone call | sanctum | `::manageRecovery` | `LogCallRequest`: details (nullable) | `DebtResource` | not detected |
| `/debts/{debt}/promise-to-pay` | POST | Record promise to pay | sanctum | `::manageRecovery` | `RecordPromiseToPayRequest`: promised_date (≥today) | `PromiseToPayResource`, 201 | debts |
| `/debts/{debt}/payments` | POST | Record payment | sanctum | `::recordPayment` | `RecordPaymentRequest`: amount (>0), payment_date, payment_method, reference_notes | `PaymentResource`, 201 | debts |
| `/debts/{debt}/payments` | GET | Payment history for debt | sanctum | `::view` | none | `PaymentResource[]` | debts |
| `/debts/{debt}/collection-cases` | POST | Escalate to Collection Case | sanctum | `::escalate` | `EscalateDebtRequest`: (none) | `CollectionCaseResource`, 201 | debts |
| `/debts/{debt}/demand-letters` | POST | Generate demand letter | sanctum | `::generateDocuments` | `GenerateDemandLetterRequest`: template_type (4-value enum) | `DemandLetterResource`, 201 | not detected |
| `/debts/{debt}/invoices` | POST | Generate invoice | sanctum | `::generateDocuments` | `GenerateInvoiceRequest`: (none) | `InvoiceResource`, 201 | not detected |
| `/debts/{debt}/statements` | POST | Generate statement (debt-triggered) | sanctum | `::generateDocuments` | `GenerateStatementRequest`: (none) | `StatementResource`, 201 | not detected |
| `/debts/{debt}/documents` | GET | All documents for debt | sanctum | `::view` | none | combined document array | debts |

### 15.5 Collection Cases

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/collection-cases` | GET | List/filter/tab cases | sanctum | `CollectionCasePolicy::viewAny` | status, tab (all/high_risk/follow_up/promise_due) | `CollectionCaseResource[]` + pagination | cases |
| `/collection-cases/{case}` | GET | Case detail | sanctum | `::view` | none | `CollectionCaseResource` | cases |
| `/collection-cases/{case}/assign` | PATCH | Assign officer | sanctum | `::manage` | `AssignCollectionCaseRequest`: officer_user_id | `CollectionCaseResource` | not detected |
| `/collection-cases/{case}` | PUT | Update case (**no-op — see §4**) | sanctum | `::manage` | `UpdateCollectionCaseRequest`: (none) | `CollectionCaseResource` unchanged | not detected |
| `/collection-cases/{case}/activities` | POST | Log activity | sanctum | `::manage` | `RecordCollectionActivityRequest`: details (nullable) | `CollectionCaseResource` | cases |
| `/collection-cases/{case}/close` | POST | Close case | sanctum | `::manage` | `CloseCollectionCaseRequest`: closure_outcome | `CollectionCaseResource` | cases |
| `/collection-cases/{case}/history` | GET | Combined activity+audit history | sanctum | `::view` | none | history array | cases |
| `/collection-cases/{case}/professional-requests` | POST | Submit to Deendoon collection | sanctum | `ProfessionalCollectionRequestPolicy::submit` | `SubmitProfessionalCollectionRequestRequest`: (none) | `ProfessionalCollectionRequestResource`, 201 | not detected |

### 15.6 Professional Collection Requests

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/professional-requests` | GET | List (tenant-scoped, or all for platform admin) | sanctum | query pre-scoped by `isPlatformAdmin()` | status | `ProfessionalCollectionRequestResource[]` + pagination | not detected |
| `/professional-requests/{id}` | GET | Request detail | sanctum | `::view` (tenant owner or platform admin) | none | Resource | not detected |
| `/professional-requests/{id}/status` | PATCH | Transition status | sanctum | `::transitionStatus` (**platform admin only**) | `TransitionRequestStatusRequest`: status (8-value enum) | Resource | not detected |
| `/professional-requests/{id}/close` | POST | Close with outcome | sanctum | `::close` (**platform admin only**) | `CloseProfessionalCollectionRequestRequest`: outcome (recovered/closed) | Resource | not detected |
| `/professional-requests/{id}/messages` | GET | Conversation thread | sanctum | `::view` | none | `RequestMessageResource[]` | not detected |
| `/professional-requests/{id}/messages` | POST | Post message | sanctum | `::postMessage` | `PostRequestMessageRequest`: content | Resource, 201 | not detected |

### 15.7 Documents (Receipts, polymorphic Documents)

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/receipts/{receipt}` | GET | Receipt detail | sanctum | `ReceiptPolicy::view` | none | `ReceiptResource` | not detected |
| `/documents` | GET | Cross-type document list | sanctum | `Gate: view-reports` | type, search, page | combined array + pagination | not detected |
| `/documents/storage-usage` | GET | Per-tenant storage usage | sanctum | `Gate: view-reports` | none | usage object | not detected |
| `/documents/{id}/download` | GET | Download PDF | sanctum | `::view` (per resolved type) | none | binary stream | not detected |
| `/documents/{id}/history` | GET | Document event history | sanctum | `::view` | none | `DocumentEventResource[]` | not detected |
| `/documents/{id}/share` | POST | Share via WhatsApp/SMS | sanctum | `::view` | `DocumentShareRequest`: channel, template_id | `SentMessageResource` | not detected |
| `/documents/{id}` | GET | Document detail (polymorphic) | sanctum | `::view` | none | type-specific Resource | not detected |

### 15.8 Dashboard & Reports

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/dashboard/kpis` | GET | 6 KPI cards | sanctum | `Gate: view-dashboard` | period (day/week/month/year) | kpis object | dashboard |
| `/dashboard/todays-overview` | GET | Today's reminder summary | sanctum | `Gate: view-dashboard` | none | summary object (shared w/ Reminder Center) | dashboard |
| `/dashboard/recent-cases` | GET | Recent cases preview | sanctum | `Gate: view-dashboard` | limit | `CollectionCaseResource[]` | dashboard |
| `/reports/aging-analysis` | GET | Aging buckets + debt list | sanctum | `Gate: view-reports` | customer_id, dateFrom/To | buckets + `DebtResource[]` + pagination | not detected |
| `/reports/customers` | GET | Customers report | sanctum | `Gate: view-reports` | full customer filter set | `CustomerResource[]` + pagination | not detected |
| `/reports/debts` | GET | Debts report | sanctum | `Gate: view-reports` | full debt filter set | `DebtResource[]` + pagination | not detected |
| `/reports/collection-cases` | GET | Cases report | sanctum | `Gate: view-reports` | status | `CollectionCaseResource[]` + pagination | not detected |
| `/reports/payments` | GET | Payments report | sanctum | `Gate: view-reports` | debt_id, dateFrom/To | `PaymentResource[]` + pagination | not detected |
| `/reports/credit-risk` | GET | Credit risk report | sanctum | `Gate: view-reports` | customer filter set | `CustomerResource[]` + pagination | not detected |
| `/reports/collection-analytics` | GET | Collection rate/avg days | sanctum | `Gate: view-reports` | dateFrom/To | analytics object | not detected |
| `/reports/risk-distribution` | GET | Risk % distribution | sanctum | `Gate: view-reports` | none | distribution object | not detected |
| `/reports/collections-trend` | GET | Daily collected-amount series | sanctum | `Gate: view-reports` | dateFrom, dateTo, metric (fixed to collected_amount) | trend series | not detected |
| `/reports/{reportType}/export` | GET | Export report file | sanctum | `Gate: view-reports` | `ExportReportRequest`: format (pdf/excel/csv) | binary file | not detected |

### 15.9 Notifications

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/notifications` | GET | List own notifications | sanctum | none — self-scoped by `recipient_user_id` | type | `NotificationResource[]` + pagination | not detected |
| `/notifications/history` | GET | Full own history | sanctum | none — self-scoped | none | `NotificationResource[]` + pagination | not detected |
| `/notifications/mark-all-read` | PATCH | Mark all own as read | sanctum | none — self-scoped | none | null | not detected |
| `/notifications/{id}/read` | PATCH | Mark one as read | sanctum | `NotificationPolicy::view` (ownership) | none | `NotificationResource` | not detected |

### 15.10 Calendar

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/calendar` | GET | Aggregated due dates/promises/reminders | sanctum | `Gate: view-reports` | from, to | entries array | not detected |

### 15.11 Reminder Center

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/reminders/summary` | GET | Due-today/overdue counts | sanctum | `ReminderPolicy::viewAny` | none | summary object | not detected |
| `/reminders` | GET | List/tab-filter reminders | sanctum | `::viewAny` | tab (all/today/upcoming/overdue/completed) | `ReminderResource[]` + pagination | not detected |
| `/reminders` | POST | Create reminder | sanctum | `::create` | `StoreReminderRequest`: type, related_entity_type/id, due_date, timing_rule, delivery_methods[], amount_due?, notes? | `ReminderResource`, 201 | not detected |
| `/reminders/{reminder}` | GET | Reminder detail | sanctum | `::view` | none | `ReminderResource` | not detected |
| `/reminders/{reminder}` | PUT | Update/reschedule | sanctum | `::update` (creator or manager role) | `UpdateReminderRequest`: same fields, all `sometimes` | `ReminderResource` | not detected |
| `/reminders/{reminder}` | DELETE | Delete reminder | sanctum | `::delete` (creator or manager role) | none | null | not detected |
| `/reminders/{reminder}/complete` | PATCH | Mark completed | sanctum | `::complete` | none | `ReminderResource` | not detected |
| `/reminders/{reminder}/send` | POST | Manual immediate send | sanctum | `::send` | `SendReminderRequest`: channel, template_id | `SentMessageResource` | not detected |

### 15.12 Messages

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/message-templates` | GET | List templates | sanctum | **none — see §21** | channel (optional) | `MessageTemplateResource[]` | not detected |
| `/messages/render` | POST | Render preview | sanctum | **none — see §21** | `RenderMessageRequest`: template_id, reminder_id | rendered text object | not detected |
| `/messages/send/whatsapp` | POST | Send rendered message | sanctum | `ReminderPolicy::send` | `SendMessageRequest`: template_id, reminder_id | `SentMessageResource` | not detected |
| `/messages/send/sms` | POST | Send rendered message | sanctum | `::send` | same | `SentMessageResource` | not detected |

### 15.13 Search

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/search` | GET | Cross-entity search | sanctum | none at controller level — per-entity RBAC inside `SearchService` (documented, intentional) | `SearchRequest`: q (required), includeArchived | per-entity-type result arrays | not detected |

### 15.14 Administration

| Route | Method | Purpose | Auth | Permission | Request Validation | Response | Flutter |
|---|---|---|---|---|---|---|---|
| `/admin/users` | GET | List tenant users | sanctum | `UserPolicy::viewAny` (admin only) | includeArchived | `AdminUserResource[]` + pagination | not detected |
| `/admin/users` | POST | Create user | sanctum | `::create` | `CreateUserRequest`: name, email (unique), password (confirmed), role (4-value enum) | `AdminUserResource`, 201 | not detected |
| `/admin/users/{user}` | GET | User detail | sanctum | `::view` (same tenant) | none | `AdminUserResource` | not detected |
| `/admin/users/{user}` | PUT | Update user | sanctum | `::update` (same tenant) | `UpdateUserRequest`: name, email (unique except self), password (nullable, confirmed) | `AdminUserResource` | not detected |
| `/admin/users/{user}/deactivate` | POST | Deactivate user | sanctum | `::deactivate` (same tenant; blocks sole active admin) | none | null | not detected |
| `/admin/users/{user}/role` | PATCH | Change role | sanctum | `::assignRole` (same tenant) | `AssignUserRoleRequest`: role (4-value hardcoded enum) | `AdminUserResource` | not detected |
| `/admin/settings/company-profile` | GET | Read branding | sanctum | `Gate: admin-only` | none | `CompanyProfileResource` | not detected |
| `/admin/settings/company-profile` | PUT | Update branding | sanctum | `Gate: admin-only` | `UpdateCompanyProfileRequest`: business_name, logo (file), address, contact_email, contact_phone | `CompanyProfileResource` | not detected |
| `/admin/settings/preferences` | GET | Read system preferences | sanctum | `Gate: admin-only` | none | `SystemSettingResource` + `DocumentTemplateResource[]` | not detected |
| `/admin/settings/preferences` | PUT | Update preferences | sanctum | `Gate: admin-only` | `UpdateSystemPreferencesRequest`: ~10 fields incl. reminder-day arrays, document_templates[] | same shape | not detected |
| `/admin/reference-data/{category}` | GET | Read reference list | sanctum | `Gate: admin-only` | category (path, 3-value enum) | `ReferenceDataResource[]` | not detected |
| `/admin/reference-data/{category}` | PUT | Update reference list | sanctum | `Gate: admin-only` | `UpdateReferenceDataRequest`: values[] (id?, value_label, sort_order?, is_active?) | `ReferenceDataResource[]` | not detected |
| `/admin/audit-trail` | GET | Audit log viewer | sanctum | `Gate: admin-only` | user_id, entity_type, action, dateFrom/To | `AuditLogResource[]` + pagination | not detected |

---

## 16. Missing Endpoints

Two different kinds of "missing" apply here, and this report distinguishes them deliberately:

### 16.1 Genuinely absent capability (a real gap against the approved SRS/UI spec)

- **Automated, scheduled reminder delivery (FR-029 / Mobile UI §7.5's "Reminder Scheduler").** The command exists (`FireDueReminders`) but is registered nowhere — see §14. This is the one item in this list that represents a real functional promise not currently kept, not just an unconsumed endpoint.
- **Real SMS/WhatsApp delivery.** Both channels are internal stubs (§5). Every "sent" message today is simulated.
- **Push notification delivery.** `ReminderDeliveryMethod::Push` is a valid, selectable value on a Reminder, but no push provider (FCM/APNs/etc.) integration exists anywhere in the codebase.
- **A distinct `audit_log.action` value for automatic Recovery Stage advancement.** Currently reuses the generic `status_changed` action with a descriptive reason string — already flagged as a known SRS/enum gap in `docs/Domain_Events.md`, not new here.

### 16.2 Endpoints that exist but have no current consumer (Flutter hasn't caught up to the backend)

The large majority of the inventory in §15 — Professional Collection Requests, Documents, Reports/Analytics, Notifications, Calendar, Reminder Center, Messages, Search, and all of Administration — has **zero calls from the Flutter app today** (confirmed by a full grep of `mobile/lib`). This isn't a backend defect; it's the natural state of a backend built against a superset specification (§11.1 of the Architecture Reference) while the mobile client has only implemented its first five modules. **Recommend treating this list as the mobile team's backlog, not a backend problem** — every one of these endpoints is implemented, tested (per the project's own 365-test suite), and ready to be wired in whenever that module's Flutter screens are built.

One specific Flutter-side observation worth surfacing to that team: the router already has three placeholder nav destinations (`Analytics`, `Reminders`, a standalone `Documents` tab) with no backing screen — these map directly to backend capability that already exists and is idle.

### 16.3 A likely-unintended endpoint

`POST /register` — see §9. Recommend a decision (keep and fix, or remove) rather than leaving it in its current half-functional state.

---

## 17. Duplicate Logic

- **Pagination-metadata construction is repeated, near-identically, in at least 7 places**: `CustomerController`, `DebtController`, `CollectionCaseController`, `AdminUserController`, `AuditTrailController`, `ReportController::paginationMeta()`, `NotificationController::paginationMeta()` all build the exact same `{current_page, per_page, total, last_page}` array literal from a `LengthAwarePaginator`, sometimes inline and sometimes as a locally-duplicated private method. `App\Traits\ApiResponse` already centralizes `perPage()` for the *request* side of pagination but has no equivalent helper for the *response* side. **This is a new finding** (not previously tracked in `docs/Engineering_Excellence.md`), low-risk, and a natural candidate for a `paginationMeta($paginator): array` addition to the existing `ApiResponse` trait — consistent with how that trait already centralizes the response envelope.
- **`ReportController`'s six report methods share near-identical query→paginate→Resource→respond structure**, and `agingAnalysisQuery()`/`debtsQuery()` duplicate date-range filtering logic. Already identified and accepted as low-priority in `docs/Engineering_Excellence.md` — not new, repeated here for completeness of this audit's duplicate-logic section.
- **Two distinct "Reminder" concepts** (`ReminderController` = FR-030 manual log actions; `ReminderCenterController` = the new schedulable `reminders` entity) look like duplication at a glance but are explicitly documented in both controllers' docblocks as deliberately separate, serving different approved requirements. **Confirmed not a duplication defect** — flagging only so this isn't "cleaned up" by a future engineer who hasn't read both docblocks.
- **`CustomerImportController`'s inline business logic** duplicates the shape of what every other Service in the codebase already does externally — already tracked as an approved, not-yet-done extraction (`docs/Engineering_Excellence.md`).

---

## 18. Performance Issues

- **`DocumentController::index()` loads every matching Receipt/DemandLetter/Statement/Invoice row via `->get()` (no database-level `LIMIT`/`OFFSET`) and paginates in memory** via `->slice()`. At current data volumes this is fine; it will not scale linearly the way the DB-level-paginated endpoints elsewhere in this codebase do. This is a genuine, if currently low-impact, finding not previously called out in any existing `docs/` file.
- **`ReferenceNumberService::next()` loads every existing reference number for a tenant+prefix into memory** to compute the next sequential value (§5). Bounded per-tenant, but worth monitoring for any tenant with a very high volume of one entity type.
- **`DocumentService::generateStatement()` loads a customer's entire Debt/Payment history unbounded** — already identified and approved for a future bounding fix in `docs/Performance_Architecture.md`, not new here.
- **`PaymentService::record()` calls receipt generation from inside the same `DB::transaction()`** that holds row locks on the affected Debt/Customer — already identified and approved for a future fix (move outside the transaction) in `docs/Performance_Architecture.md`, not new here.
- **The synchronous, no-queue architecture overall** is a deliberate, evidence-based, audited Product Owner decision (`docs/Performance_Architecture.md`) — this report does not dispute it, and does not recommend introducing queue infrastructure as a default response to any finding above.

---

## 19. N+1 Query Risks

- **`SmartReminderEngine::isDueForDelivery()` issues one `exists()` query per Reminder** when `FireDueReminders` iterates its candidate set. Currently mitigated somewhat by that command's outer `doesntHave('sentMessages')` filter narrowing the candidate set first, but a genuine per-iteration query pattern once that command is ever actually scheduled (see §14/§16.1) at meaningful volume.
- **Confirmed correctly mitigated already** (worth recording as a positive finding, not just risks): `PromiseToPayService::refreshBrokenPromisesForMany()`/`refreshDuePromisesForMany()` exist specifically to replace what would otherwise be N per-Debt queries on `DebtController::index()`'s list page with one batched check — a documented, deliberate Phase-13 N+1 fix. `ReportingService::averageDaysToPay()` uses `withMax('payments', 'payment_date')` for the same reason. `CollectionCaseController` eager-loads `debt.customer` everywhere `CollectionCaseResource` is built.
- **`ReferenceDataService::updateCategory()`** issues one existence-check + one save per submitted value in a loop — bounded by admin-configured list size (small in practice), low risk, flagged only for completeness.
- **`NotificationService::notifyMany()`** issues one `INSERT` per recipient rather than a single bulk insert — low risk at expected fan-out sizes (role-based recipient sets within one tenant), but worth a look if a future tenant has an unusually large admin/sales_finance headcount.

---

## 20. Security Concerns

Ranked roughly by severity/actionability. Items already tracked in the project's own `docs/` are marked accordingly; the two `MessageController` findings are new.

1. **`MessageController::templates()` and `MessageController::render()` have no authorization check of any kind** — confirmed by direct code read, both methods contain no `$this->authorize()`/`Gate::authorize()` call, unlike `sendWhatsApp()`/`sendSms()` in the same controller (which correctly call `$this->authorize('send', $reminder)`). Practical impact is bounded — `Reminder::findOrFail()` and `MessageTemplate::query()` are both tenant-scoped via `BelongsToTenant`, so this cannot leak cross-tenant data — but it means **any authenticated user, regardless of role** (including the `customer` role, which every policy in this system treats as having no backend-actor capability) can list message templates and render a rendered-text preview for any Reminder within their own tenant. **New finding, not previously documented. Recommend adding the same `ReminderPolicy` check these methods' siblings already use.**
2. **`AuditLog` and `User` hold `tenant_id` but are not scoped by `BelongsToTenant`, with no docblock explaining why** — unlike the five other unscoped models, which all have an explicit "deliberately does not..." justification. Every current query against `User` that needs tenant filtering does so manually (verified: `AdminUserController::index()` does), but there is no structural (ORM-level) guarantee preventing a future query from forgetting to. **Recommend either adding an explanatory docblock (if the omission is intentional, matching the pattern the other five models use) or adding the trait, as a deliberate decision either way** — not left implicit.
3. **`POST /register` produces a permission-less, tenant-less user account** — see §9/§16.3. Low exploitability (the account can do nothing), but an unresolved design ambiguity worth closing.
4. **`ProfessionalCollectionRequest`'s tenant-vs-platform-admin visibility rule is hand-scoped in Controller/Policy code, with no ORM-level safety net.** Confirmed correct in every current query (`ProfessionalCollectionRequestController::resolve()`, `::index()`), but any future addition of a new query against this model must replicate that scoping by hand — flagged as a standing review item for any future PR touching this model, not a present defect.
5. **`TRUSTED_PROXIES` unset by default** — every IP-keyed rate limiter silently protects a load balancer's IP instead of the real client's the moment this app runs behind any reverse proxy without this being set. Already flagged in `docs/Security.md`'s deployment checklist; repeated here as a pre-production-deploy gate, not a code defect.
6. **spatie's `Permission` model is installed but entirely unused** (§10) — a documentation/onboarding-clarity item, not a vulnerability.
7. **PostgreSQL RLS is not adopted** — a deliberate, already-reviewed Product Owner decision (`docs/Tenant_Isolation.md`), repeated here only because "no second enforcement layer" is inherently a standing risk factor worth naming in any security-focused reading of this report, not because this audit disputes the decision.
8. **Confirmed safe, no action needed**: `.env` is correctly gitignored and not tracked by git; no secrets were found committed anywhere in the repository during this audit.

---

## 21. Code Quality

- **Exceptionally consistent, self-documenting codebase.** The overwhelming majority of non-trivial classes and methods carry docblocks that cite a specific FR/BRL/DD number and explain *why* a design choice was made, not just what it does — a genuinely unusual level of institutional-knowledge preservation for a codebase this size.
- **Controller → Service → Model layering is applied with only one confirmed exception** (`CustomerImportController`, already tracked for extraction).
- **Naming and structural conventions are uniform**: every FormRequest's `authorize()` returns `true`; every model uses attribute-based `Fillable`/method-based `casts()`; every immutable record type overrides `update()`/`delete()` identically; every enum mirrors a DB CHECK constraint 1:1.
- **One confirmed no-op endpoint** (`PUT /collection-cases/{case}`, §4) — intentional placeholder for an unresolved SRS gap, not a bug, but worth a code comment at the route-definition site (not just the Request class) so it's discoverable without opening two files.
- **Money handled correctly throughout** — `decimal` casts + `bcmath` functions everywhere currency arithmetic occurs; no floating-point currency bugs found.
- **Test suite**: 365 tests (per the project's own Sprint 5.1 audit, not independently re-run as part of this document-only audit), organized by SRS module boundary, verified deterministic across two runs. Two approved-but-unimplemented improvements already tracked (`docs/Testing_Excellence.md`): shared test helpers currently duplicated across 16/8 files, and a missing explicit regression test that login/register responses never leak a password hash (two independent structural protections already exist in code; only the guarding test is missing).

---

## 22. Technical Debt

Consolidated from this audit plus every item already tracked in `docs/Engineering_Excellence.md`, `docs/Testing_Excellence.md`, `docs/Performance_Architecture.md`, and `docs/Production_Readiness.md` — presented here as one list so future planning doesn't have to cross-reference five documents to find them all.

**Approved, not yet implemented (pre-existing, tracked in `docs/`):**
1. Extract `CustomerImportController`'s business logic into a dedicated `ImportService`.
2. Replace the still-unmodified Laravel boilerplate `README.md` with a real Deendoon project README.
3. Move receipt generation outside `PaymentService::record()`'s `DB::transaction()`.
4. Bound/stream `DocumentService::generateStatement()`'s unbounded data load.
5. Move shared test helpers (`actingAsTenantUser`, `makeDebt`) out of 16/8 duplicated private method copies into `TestCase`/a shared trait.
6. Add a regression test guarding against login/register responses ever leaking a password hash.
7. Database backup strategy, deployment runbook, log alerting/aggregation wiring, configurable document storage disk (currently hardcoded to `'local'`), and a CI pipeline — all operational/infrastructure gaps explicitly accepted as not blocking the software's own production-readiness GO verdict.

**New, surfaced by this audit:**
8. `MessageController::templates()`/`render()` missing authorization checks (§20.1).
9. `AuditLog`/`User` tenant-scoping ambiguity needs an explicit decision or docblock (§20.2).
10. `POST /register`'s half-functional, permission-less account creation needs a decision (§20.3).
11. Repeated pagination-metadata construction across 7 controllers — candidate for a shared `ApiResponse::paginationMeta()` helper (§17).
12. `DocumentController::index()`'s in-memory pagination over an unbounded `->get()` (§18).
13. `follow_up_history.collection_case_id`'s promised-but-never-added FK (§2).
14. The `reminders`/`sent_messages` → `collection_cases` FK migration-ordering anomaly needs verification against a real deploy history (§2).
15. `FireDueReminders` is fully built and tested but registered in no scheduler anywhere — the Reminder Center's automated-delivery promise is currently unfulfilled in practice (§14/§16.1).
16. The stray, empty `app/Http/` directory at the repository root (outside `deendoon/`) — likely dead scaffolding, worth confirming and removing.
17. `StoreReminderRequest`/`UpdateReminderRequest` don't validate that `related_entity_id` actually exists in whatever table `related_entity_type` names (§12).

None of the items above is severity-critical; all are refinements to an already-sound, already-audited system.
