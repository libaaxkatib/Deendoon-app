# Known Backend Issues

**Date:** 2026-07-29
**Source:** Consolidated from the full backend audit ([`Backend_Audit_Report.md`](./Backend_Audit_Report.md), [`Backend_Architecture_Reference.md`](./Backend_Architecture_Reference.md)) plus this project's own prior living decisions (`docs/Engineering_Excellence.md`, `docs/Testing_Excellence.md`, `docs/Performance_Architecture.md`, `docs/Production_Readiness.md`, `docs/Database_Architecture.md`).
**Purpose:** a single, flat, actionable list — one entry per issue, each with Priority, Risk, Recommendation, and a Production go/no-go call — so future backend work doesn't require cross-referencing five documents to know what's outstanding.
**Status of this document:** point-in-time tracker. Update an entry's status (or move it to a "Resolved" section) as items are closed — don't let this drift the way a stale checklist would.

**Priority scale:** Critical (fix immediately / blocks any deploy) · High (fix soon, real user-facing or security impact) · Medium (real but bounded impact, plan it in) · Low (cosmetic/consistency, opportunistic).

---

## 1. Confirmed Bugs

Verified directly against running code — not judgment calls or open design questions.

### 1.1 `MessageController::templates()` and `render()` have no authorization check

- **Priority:** High
- **Risk:** Any authenticated user, regardless of role — including the `customer` role, which every other policy in this system treats as having zero backend-actor capability — can list message templates and render a message preview for any Reminder in their own tenant. Bounded by tenant (`Reminder`/`MessageTemplate` both use `BelongsToTenant`), so this is not a cross-tenant data leak, but it is a real, inconsistent authorization gap: the two sibling methods in the same controller (`sendWhatsApp()`/`sendSms()`) both correctly call `$this->authorize('send', $reminder)`, and these two do not.
- **Recommendation:** Add `$this->authorize('view', $reminder)` (or an equivalent `ReminderPolicy` check) to both `templates()` and `render()` in `app/Http/Controllers/MessageController.php`, matching the pattern already used two methods below it in the same file.
- **Should Fix Before Production:** **Yes**

### 1.2 `PUT /collection-cases/{case}` is a confirmed no-op endpoint

- **Priority:** Low
- **Risk:** None functionally (it changes nothing), but it's a real code-quality/documentation hazard: a client calling this endpoint expecting an update will get a 200 with the unchanged resource and no indication nothing happened. `UpdateCollectionCaseRequest::rules()` is a literal `[]`, and `CollectionCaseController::update()` only re-returns the resource after a status check.
- **Recommendation:** This is a known, already-flagged SRS gap (no approved editable field exists yet for a Collection Case) — not a bug to silently "fix" by inventing a field. Add a one-line comment at the route definition in `routes/api.php` (not just in the Request class docblock) so it's discoverable without opening two files, and consider returning a distinct signal (e.g., a `204` or an explicit "no updatable fields" message) rather than a misleadingly-normal `200` success response.
- **Should Fix Before Production:** No (behavior is intentional and safe; only the discoverability/response-shape is worth improving)

### 1.3 `POST /register` creates a permission-less, tenant-less user account

- **Status: RESOLVED (2026-07-31)** — per the RBAC Architecture Amendment (Product Owner Decision), `POST /register` now creates a Tenant and its Business Owner account (role `admin`) together, in a transaction. See `AuthController::register()`, `RegisterRequest` (now requires `business_name`), and `RBAC_Architecture_Amendment_Proposal.md` Revision 2, Decision 3.
- **Priority:** Medium
- **Risk:** `AuthController::register()` sets only `name`/`email`/`password` — no `tenant_id` (since `User` doesn't use `BelongsToTenant`'s auto-fill) and no role. The resulting account can authenticate but is authorized for nothing (every Policy/Gate in the system requires a role or a matching non-null `tenant_id`). It is functionally inert today, but it's a public, unauthenticated, rate-limited-but-otherwise-unrestricted endpoint that writes a real row to `users` for anyone who calls it — confirmed the Flutter app defines the endpoint constant but never calls it, and no registration screen exists anywhere in the mobile app's router.
- **Recommendation:** Get an explicit decision on this endpoint's intended purpose. Either (a) implement it properly — create the `Tenant` row and assign the `admin` role, if it's meant to be a self-service tenant-bootstrap flow — or (b) remove it from the public API surface entirely if all user creation is meant to go through `AdminUserController::store()` (the actual approved FR-066 flow, which always assigns both). Leaving it half-functional is the worst of the three options.
- **Should Fix Before Production:** **Yes** (as a decision, even if the decision is "remove it" — don't ship an ambiguous public endpoint that writes orphaned rows)

### 1.4 `follow_up_history.collection_case_id`'s promised foreign key was never added

- **Priority:** Low
- **Risk:** The original migration's own comment states an FK will be added "once the target table exists" (`collection_cases` didn't exist yet at authoring time). `collection_cases` now exists, but no later migration ever added the FK. The column remains an unconstrained `char(26) nullable` — referential integrity here depends entirely on application code never writing a bad ID, with no database-level backstop.
- **Recommendation:** Add a migration that adds the FK now that `collection_cases` exists, matching the pattern already used for every other cross-table reference in this schema.
- **Should Fix Before Production:** No (low likelihood of an orphaned reference in practice, but cheap to close — good candidate for the next migration touching this table)

---

## 2. Possible Bugs

Findings that need verification against a real environment/deploy history before being called confirmed defects.

### 2.1 `reminders`/`sent_messages` → `collection_cases` foreign keys declared before that table's own creation migration

- **Priority:** Medium
- **Risk:** By migration filename timestamp, `reminders.related_case_id` and `sent_messages.case_id` both declare an FK to `collection_cases.id` in migrations dated **2026-07-27**, while `collection_cases` itself isn't created until **2026-07-31**. PostgreSQL enforces FK target existence at migration time — this would fail outright on a real Postgres run unless the actual deployed run order differs from filename order. It currently "passes" in the test suite only because that suite runs on SQLite, which doesn't enforce FK target existence the same way.
- **Recommendation:** Verify against the real migration run history (`php artisan migrate:status` on an actual PostgreSQL environment, or the deployment log) that these migrations genuinely apply in an order where `collection_cases` exists first. If they don't, this needs a migration-ordering fix before the next fresh-database deploy.
- **Should Fix Before Production:** **Yes** — verify before any fresh production migration run; if already running fine in a real Postgres environment, this drops to a documentation/housekeeping note only.

### 2.2 Reminders can reference a non-existent related entity

- **Priority:** Medium
- **Risk:** `StoreReminderRequest`/`UpdateReminderRequest` validate `related_entity_id` as a plain string with no `exists:` check against whichever table `related_entity_type` names (Customer/Debt/CollectionCase/PromiseToPay). Since this is a polymorphic-by-convention pair (not a real `morphTo`), a naive `exists:` rule can't be applied directly — but as written, a client can create a Reminder pointing at an ID that doesn't exist in the named table, and nothing downstream currently validates it either.
- **Recommendation:** Add a custom validation rule (e.g., a `withValidator()` closure resolving the correct model class from `related_entity_type` and checking existence) to both Request classes. This is a deliberate gap, not an oversight per the codebase's own conventions elsewhere — treat as a decision to make, not a silent fix.
- **Should Fix Before Production:** No (bounded impact — a dangling reference just means that Reminder's detail view shows nothing for the related entity; not a security or data-corruption issue) but worth prioritizing before the Reminder Center has a real UI consumer.

### 2.3 `AuditLog` and `User` hold `tenant_id` but are not scoped by `BelongsToTenant`, with no documented reason

- **Priority:** High
- **Risk:** Five other models that skip `BelongsToTenant` all carry an explicit docblock explaining why (bimodal visibility, relational-only scoping, etc.). `AuditLog` and `User` do not — and both hold a real `tenant_id` (in `AuditLog`'s case, it's even in the model's own `Fillable` list). Every current query against `User` that needs tenant filtering does so manually (verified: `AdminUserController::index()` does), but there's no ORM-level safety net stopping a future query from forgetting to filter — and unlike the five documented exceptions, it's not clear whether this is a deliberate exception at all or simply an unaddressed gap.
- **Recommendation:** Get an explicit decision: either add `BelongsToTenant` to both models (if there's no real reason not to — `User` already has a working `tenant()` relation, so the mechanics would work), or add the same kind of explanatory docblock the other five unscoped models already have. Don't leave this ambiguous — it's the single highest-value clarification in this whole list.
- **Should Fix Before Production:** **Yes**

---

## 3. Architecture Concerns

Structural characteristics that are working as implemented today but represent real, standing risk factors or design tensions worth naming explicitly.

### 3.1 `ProfessionalCollectionRequest`'s tenant isolation has no ORM-level safety net

- **Priority:** Medium
- **Risk:** This model deliberately opts out of `BelongsToTenant` (documented, correct, bimodal tenant + cross-tenant-platform-admin visibility can't be expressed by that trait). Every current query against it correctly hand-scopes visibility in the Controller/Policy. But this means every *future* query against this model must replicate that scoping by hand — there's no structural guarantee like the global scope provides everywhere else.
- **Recommendation:** Add this model to a mandatory code-review checklist item: any new query against `ProfessionalCollectionRequest` must be reviewed against `ProfessionalCollectionRequestController::resolve()`'s existing scoping logic before merge.
- **Should Fix Before Production:** No (already correct today; this is a standing process control to maintain, not a current defect)

### 3.2 No second enforcement layer for tenant isolation (PostgreSQL RLS not adopted)

- **Priority:** Medium
- **Risk:** Tenant isolation today is application-layer only (`BelongsToTenant` global scope + Policies + server-resolved `tenant_id` + 404-masking). A single missed `tenant_id` filter anywhere has no database-level backstop. This is a deliberate, already-reviewed Product Owner decision (`docs/Tenant_Isolation.md`), not an oversight — flagged here only because "single enforcement layer" is a standing architectural risk worth naming in any consolidated issues list, independent of whether the decision itself is disputed.
- **Recommendation:** No action required unless the risk tolerance changes — the compensating process control (mandatory tenant-scoping review on every new query) is already documented and is the accepted mitigation. Revisit only if a compliance requirement or an actual incident changes the calculus.
- **Should Fix Before Production:** No (already an accepted, documented decision)

### 3.3 Message delivery (WhatsApp/SMS) is entirely simulated

- **Priority:** High (for business expectations) / Low (for code correctness — it does exactly what it's documented to do)
- **Risk:** `InternalWhatsAppChannel`/`InternalSmsChannel` are hardcoded stubs (`return 'sent'`) — no real gateway integration exists anywhere. Every "sent" reminder or shared document today is simulated, not delivered. This is by design (an explicit "External Integrations Policy" deferred real provider selection), but it's the kind of gap that's invisible in code review and only surfaces when a real user expects a real WhatsApp message to arrive.
- **Recommendation:** Before any production launch that markets WhatsApp/SMS delivery as a real feature, this must be replaced with a real provider integration behind the existing `MessageDeliveryChannel` contract (the seam is already correctly designed for this — no architecture change needed, just new implementations of the existing interface).
- **Should Fix Before Production:** **Yes** — if WhatsApp/SMS delivery is claimed as working to real users. No — if the product launches with this explicitly scoped out / in-app-only for this release.

### 3.4 Scheduled reminder delivery has no scheduler wired up

- **Priority:** High
- **Risk:** `FireDueReminders` (`reminders:fire-due`) is fully built and tested, but is registered in no scheduler anywhere — no `Schedule::command()` call exists, and there's no `app/Console/Kernel.php` at all. The Reminder Center's core promise ("N minutes/hours/days before due date, deliver automatically") does not happen unless a human or an external cron entry invokes this command manually.
- **Recommendation:** Before the Reminder Center ships to real users, wire this into a real scheduling mechanism — either an external cron entry (`php artisan reminders:fire-due` on an interval, consistent with the accepted no-Redis/no-Horizon architecture) or, if the Product Owner revisits the no-scheduler decision, Laravel's own scheduler. This is a product-completeness gap, not a code defect — the command itself works.
- **Should Fix Before Production:** **Yes** — if the Reminder Center's scheduled-delivery feature ships to real users this release. No — if scheduled (as opposed to manual) reminder delivery is explicitly out of scope for this release.

### 3.5 Two distinct "Reminder" concepts coexist in the codebase

- **Priority:** Low
- **Risk:** `ReminderController` (FR-030 manual log actions) and `ReminderCenterController` (the new schedulable `reminders` entity) look like duplicated functionality at a glance. Both are explicitly documented in their own docblocks as deliberately separate, serving genuinely different approved requirements.
- **Recommendation:** No code change needed. Add a short note to onboarding material / the architecture reference (already done in `Backend_Architecture_Reference.md §11.1`) so a future engineer doesn't "clean this up" by merging them without reading both docblocks first.
- **Should Fix Before Production:** No

### 3.6 No web admin dashboard exists in this repository

- **Priority:** Medium
- **Risk:** The original SRS's tech stack names a "React + TypeScript Super Admin Web Dashboard" as a client alongside the Flutter mobile app. No such project exists anywhere in this repository. Every Administration endpoint (`/admin/*`), Reporting endpoint, and most of the rest of the API surface has no consuming client at all today — not just "not yet built in Flutter" (§ see the companion Audit Report's §16.2), but genuinely no web client project exists to build against.
- **Recommendation:** Confirm with the team whether the web admin dashboard is still planned, has been descoped in favor of an all-Flutter approach, or exists in a separate repository not included here. This materially affects how much of the already-built backend surface (Administration, Reports, Audit Trail) will ever get a real consumer.
- **Should Fix Before Production:** No (this is a product/scope question, not a backend defect) — but worth resolving early, since it changes the priority of several "not consumed by Flutter" endpoints in the Audit Report.

### 3.7 Mixed primary-key strategy with no FK enforcement on any actor column

- **Priority:** Low
- **Risk:** `users.id` remains `bigint` while every other table uses `char(26)` ULIDs; every "who did this" column across the schema (`actor_user_id`, `created_by_user_id`, `recorded_by_user_id`, etc.) is consequently an unconstrained string with no database-enforced FK to `users.id`. This is a permanent, accepted Product Owner decision (`docs/Database_Architecture.md`), not a migration backlog item — correctness for these columns is an application-layer responsibility only.
- **Recommendation:** No action required — this is intentionally permanent. Preserve the existing compensating control (every write path sources these values from an authenticated `User` model, never raw client input) in any new code touching an actor column.
- **Should Fix Before Production:** No (already an accepted, permanent decision)

### 3.8 spatie's permission system is half-installed

- **Priority:** Low
- **Risk:** `spatie/laravel-permission`'s `Permission` model, migration, and config are fully present but have zero references in application code — authorization is role-only throughout. Not inconsistent with any documentation, but a future engineer skimming `config/permission.php` could reasonably assume fine-grained permissions are in use somewhere.
- **Recommendation:** A one-line note in onboarding/README material clarifying that RBAC in this project is role-only by deliberate choice. No code change needed.
- **Should Fix Before Production:** No

### 3.9 `risk_level`'s designed database representation may no longer match its approved architecture — Deferred Database Architecture Decision

- **Status:** Deferred — explicit Product Owner decision (2026-07-31). No change to `06_Database_Design.md` at this time. To be addressed during the Database Design review phase.
- **Priority:** Medium
- **Risk:** `06_Database_Design.md` §6 designs `customers.risk_level` as a `VARCHAR(50)`, application-validated against a tenant-configurable `reference_data` category (`DD-010`) — the same pattern used for Payment Method and Collection Outcome, i.e., a value set each tenant can customize. But the Risk Level Engine (`deendoon/docs/Risk_Level_Engine_v1.0.md`, approved 2026-07-31) fixes Risk Level as exactly three product-wide values — Low/Medium/High — with fixed semantics, calculated deterministically by a backend engine, not configured per tenant. A tenant-configurable reference-data column and a fixed, engine-calculated three-value output are two different data models; as designed today, `06`'s schema documents the former while the approved architecture requires the latter.
- **Recommendation:** During the Database Design review phase, reconcile `customers.risk_level`'s representation with the Risk Level Engine's architecture — most likely a fixed `CHECK (risk_level IN ('low','medium','high'))` constraint (matching the pattern already used for `customer_status`), rather than a `reference_data`-driven configurable column. This is a schema decision requiring Product Owner approval; it is not resolved by this entry.
- **Should Fix Before Production:** **Yes** — before Risk Level Engine implementation begins, since the column design determines how the engine can write its output.

---

## 4. Technical Debt

Already-identified, already-approved-but-not-yet-implemented items (from this project's own prior audits), plus new items surfaced by this pass.

### 4.1 `CustomerImportController` still has business logic living in the controller

- **Priority:** Medium
- **Risk:** The one confirmed exception to this codebase's otherwise-universal Controller→Service→Model layering. `validateRow()`, `processRow()`, `rowToArray()` live directly in the controller rather than a dedicated `ImportService`. No functional risk — the logic works and is tested — but it's the one place a future change is more likely to introduce inconsistency with the rest of the codebase's patterns, and it can't be unit-tested independently of the full HTTP stack.
- **Recommendation:** Extract into a new `ImportService`, following the exact shape every other Service in this codebase already uses. Already approved (`docs/Engineering_Excellence.md`) — no new decision needed, just execution.
- **Should Fix Before Production:** No (pure code-organization; the tested behavior is correct today)

### 4.2 `README.md` is still unmodified Laravel boilerplate

- **Priority:** Low
- **Risk:** Zero Deendoon-specific content in the first (often only) file a new engineer or reviewer opens, despite a substantial `docs/` folder of living architecture documentation one directory away and undiscoverable from the actual entry point.
- **Recommendation:** Replace with a README covering what Deendoon is, local setup (`composer run setup` already does the real work), how to run tests, and a pointer to `SRS/` and `docs/`. Already approved (`docs/Engineering_Excellence.md`).
- **Should Fix Before Production:** No

### 4.3 Test helper duplication across the test suite

- **Priority:** Low
- **Risk:** `actingAsTenantUser()` is duplicated identically across 16 Feature test files; `makeDebt()` across 8. Any future change to how a test authenticates or fabricates a Debt fixture requires editing up to 16 places by hand, with real risk of missing one.
- **Recommendation:** Move both into `tests/TestCase.php` or a shared trait. Already approved (`docs/Testing_Excellence.md`) — pure relocation, no behavior change.
- **Should Fix Before Production:** No

### 4.4 No regression test guards against a leaked password hash

- **Priority:** Medium
- **Risk:** Two independent structural protections already exist (`UserResource`'s field whitelist; `User`'s `#[Hidden(['password', 'remember_token'])]`), but no test currently fails if a future change silently removes either one.
- **Recommendation:** Add an explicit assertion to the `/login` and `/register` success-path tests confirming no `password`/hash field is present anywhere in the response body. Already approved (`docs/Testing_Excellence.md`).
- **Should Fix Before Production:** No, but cheap and worth doing before the next auth-related change ships.

### 4.5 Repeated pagination-metadata construction across 7 controllers

- **Priority:** Low
- **Risk:** `CustomerController`, `DebtController`, `CollectionCaseController`, `AdminUserController`, `AuditTrailController`, `ReportController`, and `NotificationController` all independently build the same `{current_page, per_page, total, last_page}` array from a paginator — some inline, some as a locally-duplicated private method. A future change to this shape (e.g., adding a `total_pages` alias) requires editing 7 places.
- **Recommendation:** Add a `paginationMeta($paginator): array` method to the existing `App\Traits\ApiResponse` trait (which already centralizes the request-side `perPage()` helper and the response envelope), and have all 7 controllers call it.
- **Should Fix Before Production:** No

### 4.6 Stray empty `app/Http/` directory at the repository root

- **Priority:** Low
- **Risk:** A directory exists at `C:\Users\hp\Deendoon-app\app\Http` — one level above the real Laravel application (`deendoon/`) — that appears to be leftover scaffolding, not part of the working app (confirmed via `composer.json`'s PSR-4 autoload root, which points at `deendoon/app/`). Harmless today, but confusing to anyone browsing the repo root.
- **Recommendation:** Confirm with the team it's unused, then delete it.
- **Should Fix Before Production:** No

### 4.7 Two `system_settings` numeric columns have no database CHECK constraint

- **Priority:** Low
- **Risk:** `professional_collection_threshold_days` and `soft_limit_warning_threshold` are validated only at the application layer (Form Request `min`/`max` rules), unlike every other enumerated/bounded numeric column in the schema. Deliberately deferred (`docs/Database_Architecture.md`) until the automation that actually consumes these values is built.
- **Recommendation:** Add the matching CHECK constraint **at the same time** as whichever future module implements the Recovery Policy escalation-threshold or soft-limit-warning automation — not before, per the existing decision's own revisit condition.
- **Should Fix Before Production:** No (already an accepted, conditionally-deferred decision — just don't forget the condition)

### 4.8 Role whitelist is hardcoded in two Form Requests instead of read from the `roles` table

- **Priority:** Low
- **Risk:** `AssignUserRoleRequest`/`CreateUserRequest` validate `role` against a hardcoded PHP array (`['admin','sales_finance','customer','collection_officer']`) rather than checking the database dynamically. Correct today; means a new role added to the `roles` table wouldn't automatically become assignable through these endpoints without also remembering to update both whitelists.
- **Recommendation:** Low priority given how rarely this role set changes — but worth a comment in both Request classes cross-referencing each other, so a future addition doesn't update one and miss the other.
- **Should Fix Before Production:** No

### 4.9 Operational/infrastructure gaps (not code defects, already tracked)

- **Priority:** High (operational, not code)
- **Risk:** No automated database backup strategy is configured or documented; no deployment runbook exists covering required production `.env` values; the `security` log channel is configured but not wired into any alerting; `DocumentService`'s storage disk is hardcoded to `'local'` rather than reading `config('filesystems.default')`, so generated documents can't be moved to durable/cloud storage without a code change; no CI pipeline exists, so the (good) test suite only runs when someone runs it by hand.
- **Recommendation:** Execute the Production Readiness checklist already defined in `docs/Production_Readiness.md` — these are explicitly accepted as not blocking the software's own GO verdict, but they do block safe real-world operation.
- **Should Fix Before Production:** **Yes**, before serving real tenant traffic — the software itself is accepted as production-ready independent of these, but these are real prerequisites to operating it safely.

---

## 5. Performance Improvements

### 5.1 Receipt generation runs inside the same DB transaction as the financial write

- **Priority:** Medium
- **Risk:** `PaymentService::record()` calls `DocumentService::generateReceipt()` (PDF rendering + disk write) from *inside* the `DB::transaction()` that also updates `debts.remaining_balance`/`debt_status` and `customers.outstanding_balance` — meaning row-level locks on those rows stay open for the duration of PDF rendering. Real only under concurrent writes to the same Debt/Customer, which is a rare access pattern for this product, but the fix is low-risk.
- **Recommendation:** Move the `generateReceipt()` call to after the transaction commits (already approved, `docs/Performance_Architecture.md`). `DocumentService::generateReceipt()` already catches its own failures and returns `null` rather than throwing, so this guarantee is preserved either way. Still fully synchronous — not a queuing change.
- **Should Fix Before Production:** No (low-risk, low-frequency trigger condition) but a good candidate for the next sprint touching `PaymentService`.

### 5.2 Statement generation loads a customer's entire history unbounded

- **Priority:** Medium
- **Risk:** `DocumentService::generateStatement()` loads `$customer->debts()->withTrashed()->get()` and `$customer->payments()->with('debt')->get()` with no limit, date range, or chunking. Statement generation is the one document type whose cost scales with a single Customer's cumulative history rather than a bounded single-transaction dataset.
- **Recommendation:** Replace the unbounded `->get()` calls with a chunked/lazy read or a defined lookback window (the correct choice is a product decision against FR-049's actual requirement, not pre-decided here). Already approved (`docs/Performance_Architecture.md`).
- **Should Fix Before Production:** No, unless a specific tenant is already known to have unusually large transaction history — otherwise a good candidate for the next sprint touching `DocumentService`.

### 5.3 `DocumentController::index()` paginates in memory over an unbounded query

- **Priority:** Medium
- **Risk:** Loads every matching Receipt/DemandLetter/Statement/Invoice row via `->get()` (no database-level `LIMIT`/`OFFSET`) across all four tables, then paginates with `->slice()` in PHP. Every other list endpoint in this codebase paginates at the database level; this one doesn't scale the same way as data volume grows.
- **Recommendation:** Redesign to paginate at the query level per type (harder given it's a cross-table union-like result) or, at minimum, cap the maximum unpaginated result size defensively until a proper fix is scheduled.
- **Should Fix Before Production:** No at current volumes, but flag for the next sprint that touches Documents — this is a new finding not yet tracked anywhere else.

### 5.4 `ReferenceNumberService::next()` loads every existing reference number into memory

- **Priority:** Low
- **Risk:** Computes the next sequential business identifier (`DBT-`, `RCT-`, etc.) by pulling **all** matching reference numbers for a tenant+prefix into memory and taking the max. Scales linearly with volume per tenant per entity type — bounded by tenant, not a problem at current expected scale.
- **Recommendation:** No immediate action; revisit if any single tenant accumulates a very large number of one entity type (tens of thousands+). A `MAX()` aggregate query would be the straightforward fix if/when needed.
- **Should Fix Before Production:** No

### 5.5 `SmartReminderEngine::isDueForDelivery()` issues one query per Reminder in a loop

- **Priority:** Low
- **Risk:** When `FireDueReminders` iterates its candidate set, this method calls `$reminder->sentMessages()->exists()` per iteration — a real N+1 pattern, partially mitigated today by the command's outer `doesntHave('sentMessages')` filter narrowing the candidate set first. Currently low-impact since the command isn't even scheduled (§3.4), but will matter once it is.
- **Recommendation:** Batch this check the same way `PromiseToPayService::refreshBrokenPromisesForMany()` already does for a comparable problem — resolve once whichever future work wires `FireDueReminders` into a real scheduler (§3.4).
- **Should Fix Before Production:** No today (command isn't scheduled); **yes, alongside §3.4** if/when it is.

### 5.6 `NotificationService::notifyMany()` issues one INSERT per recipient

- **Priority:** Low
- **Risk:** Loops over recipients calling `notify()` individually rather than a single bulk insert. Low risk at expected fan-out sizes (role-based recipient sets within one tenant), but scales linearly with recipient count.
- **Recommendation:** No immediate action; revisit only if a future tenant has an unusually large admin/sales_finance headcount making this a measurable bottleneck.
- **Should Fix Before Production:** No

---

## Summary — items that ARE "Should Fix Before Production: Yes"

For quick scanning, every item marked Yes above, in one place:

| # | Item | Section |
|---|---|---|
| 1 | `MessageController::templates()`/`render()` missing authorization | §1.1 |
| 2 | ~~`POST /register` ambiguous account-creation decision~~ — **RESOLVED 2026-07-31** | §1.3 |
| 3 | Verify `collection_cases` FK migration ordering against real deploy history | §2.1 |
| 4 | `AuditLog`/`User` tenant-scoping decision | §2.3 |
| 5 | Real WhatsApp/SMS delivery — *only if* claimed as a working feature this release | §3.3 |
| 6 | Scheduled reminder delivery wiring — *only if* scheduled delivery ships this release | §3.4 |
| 7 | Operational readiness (backup, runbook, alerting, CI) — before serving real tenant traffic | §4.9 |

Everything else in this document is real but bounded, already mitigated, or already an accepted deliberate decision — safe to sequence into ordinary future sprints rather than gating the current release.
