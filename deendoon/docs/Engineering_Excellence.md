# Engineering Excellence — Accepted Decisions & Approved Future Work

**Status:** Product Owner decisions on record (v1.8.0 — Sprint 4.1, Engineering Excellence Audit).

Records the outcome of the Sprint 4.1 audit: the current architecture is
accepted as-is, no structural refactoring will be performed, and two
specific improvements are approved for a **future** implementation
sprint — not implemented now. Three further findings are accepted as
low-priority, unscheduled engineering improvements.

---

## Decision — Current architecture accepted; no structural refactoring

The Controller → Service → Model layering, the authorization model, the
exception-handling pattern, and the dependency-injection discipline are
accepted as correct and are **not** to be restructured. This was
independently audited (Sprint 4.1) against every Service, Controller,
Form Request, Resource, and configuration file in the codebase and found,
with evidence, to be consistently and correctly applied — see the Sprint
4.1 audit report for the full evidence trail. The findings below are
targeted, evidence-based exceptions to an otherwise-sound architecture,
not signs that the architecture itself needs to change.

---

## Approved future engineering improvements

Both approved for a **future implementation sprint**. Neither is
implemented as part of this decision.

### 1. Extract `CustomerImportController`'s business logic into a dedicated `ImportService`

**Current state:** `CustomerImportController` is the one Controller in
this codebase where real business logic — `validateRow()` (row-level
validation rules), `processRow()` (duplicate-resolution decisions and
Customer create/update), and `rowToArray()` — lives directly in the
Controller rather than a Service. Every other comparably complex flow
(Payment recording, Document generation, Collection Case management,
Admin User management) has this category of logic extracted into a
dedicated Service; this is the one exception, and it isn't documented
anywhere as a deliberate one.

**Approved change:** extract `validateRow()`, `processRow()`, and
`rowToArray()` (and the row-processing orchestration currently inline in
`commit()`) into a new `ImportService`, following the same shape every
other Service in this codebase already uses — constructor-injected
dependencies (`CustomerDuplicateDetectionService`, `AuditLogService`,
already used by the Controller today), public methods the Controller
calls directly, no change to the HTTP contract (`store()`/`commit()`'s
request/response shapes are unaffected).

**Why this matters:** consistency (this becomes the only Controller in
the codebase not following the established pattern once fixed) and
testability (import logic could then be unit-tested independently of the
full HTTP stack, closing part of the unit-test gap recorded below).

**Explicitly not approved as part of this:** any change to FR-016's
approved behavior (preview/duplicate-resolution/commit flow), validation
rules, or response shape. This is a pure code-organization move — the
tested behavior must be unchanged.

### 2. Replace the Laravel boilerplate `README.md` with a Deendoon project README

**Current state:** `README.md` (58 lines, verified) is still Laravel's
unmodified installer boilerplate — generic "About Laravel" copy, links to
Laracasts, the framework's own logo. Zero Deendoon-specific content,
despite a substantial `docs/` folder of living architecture documentation
existing one directory away, undiscoverable from the project's actual
entry point.

**Approved change:** replace it with a README that serves as the primary
developer entry point — at minimum: what Deendoon is (a multi-tenant
Smart Debt Recovery Assistant SaaS backend), local setup instructions
(the existing `composer run setup` script already does the real work —
document it), how to run the test suite (`php artisan test`,
`vendor/bin/pint`), and a pointer to `SRS/` (the frozen specification) and
`docs/` (living architecture decisions: `Security.md`,
`Tenant_Isolation.md`, `Database_Architecture.md`,
`Performance_Architecture.md`, `Domain_Events.md`, `Password_Reset.md`,
this document).

**Why this matters:** onboarding cost — the README is the first (often
only) file a new engineer or reviewer reads, and right now it actively
misdirects rather than orienting them.

---

## Accepted low-priority engineering improvements (unscheduled)

The following three findings from the Sprint 4.1 audit are accepted as
real but low-priority — not assigned to a specific future sprint, not
rejected:

1. **`env()` calls outside `config/`** — `SANCTUM_IDLE_TIMEOUT`
   (`EnsureTokenIsNotIdle`), `API_RATE_LIMIT_PER_MINUTE`
   (`AppServiceProvider`), `PASSWORD_RESET_TOKEN_EXPIRY_MINUTES`
   (`PasswordResetService`), `TRUSTED_PROXIES` (`bootstrap/app.php`).
   Verified not to cause any functional break (Laravel's `env()` reads
   the live environment regardless of config-caching state) — the value
   of fixing this is discoverability and consistency with the config
   repository, not correctness.
2. **`ReportController`'s duplicated query-building logic** —
   `agingAnalysisQuery()`/`debtsQuery()` share near-identical date-range
   filtering, and all six report methods repeat the same
   query→paginate→Resource→respond shape. A real DRY violation with no
   correctness impact today.
3. **Unit-test expansion** — all tests remain Feature/HTTP-level; no
   business logic (balance recalculation, recovery-stage transitions) is
   currently exercised by a true isolated unit test.

None of these three block any release or represent a correctness risk;
they may be picked up opportunistically whenever a future sprint touches
the affected code, without needing a dedicated sprint of their own.

---

## Source

All decisions above arise directly from the Sprint 4.1 Engineering
Excellence Audit (independent audit, evidence-driven — see that report's
Sections 8, 10, 11, and 12 for the full reasoning and classification
behind each). This document does not restate that evidence in full; it
records only the decisions and enough implementation-relevant detail for
a future sprint to act on the two approved items without re-reading the
whole audit first.
