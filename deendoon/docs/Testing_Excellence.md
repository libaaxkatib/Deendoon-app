# Testing Excellence — Accepted Decisions & Approved Future Work

**Status:** Product Owner decisions on record (v1.9.0 — Sprint 5.1, Testing Excellence Audit).

Records the outcome of the Sprint 5.1 audit: the current testing strategy
and its production confidence are both accepted as-is, and two specific
improvements are approved for a **future** implementation sprint — not
implemented now. One further finding is accepted as a low-priority,
unscheduled improvement.

---

## Decision — Current testing strategy and production confidence accepted

The suite's architecture (Feature-test organization mapped to SRS module
boundaries), its coverage across all fifteen named module areas, its
regression-protection record against every previously-fixed defect
(N+1 queries, the authorization-envelope fix, tenant isolation, payment
calculations, promise lifecycle), its database-testing practices, and its
CI readiness (verified deterministic across two full independent runs,
365/365 passing, 950/950 assertions, no flakiness risk factors found) are
all accepted as sufficient. This was independently audited (Sprint 5.1)
with direct evidence — full test/line/method-count inventories, live
double-run determinism checks, and targeted greps across `tests/` — not
assumed from prior sprints. The findings below are targeted, evidence-based
exceptions within an otherwise-sufficient test suite, not signs that the
overall testing strategy needs to change.

---

## Approved future testing improvements

Both approved for a **future implementation sprint**. Neither is
implemented as part of this decision.

### 1. Move shared testing helpers into `TestCase` or reusable testing traits

**Current state:** `actingAsTenantUser(Tenant $tenant, string $role =
'admin'): User` is defined privately and identically in **16** separate
Feature test files; `makeDebt(Tenant $tenant, array $attributes = []):
Debt` is defined privately and identically in **8**. Verified byte-for-byte
identical across sampled files. `tests/TestCase.php` remains the
unmodified Laravel stub with no shared helper methods — the root cause of
the duplication.

**Approved change:** move both helpers into `tests/TestCase.php` (or a
dedicated trait applied by every Feature test), so each of the 16/8 call
sites is replaced by inheriting or `use`-ing the shared definition instead
of a local copy. The 16 call sites' behavior is already identical
everywhere, so this is a pure relocation — no test's asserted behavior
changes.

**Why this matters:** any future change to how a test authenticates as a
tenant user or fabricates a Debt fixture currently requires editing up to
16 places by hand, with real risk of missing one and leaving it silently
inconsistent with the rest.

**Explicitly not approved as part of this:** any change to what either
helper does today, or to any test's assertions. This is a
code-organization move within the test suite, not a test-behavior change.

### 2. Add regression tests ensuring authentication responses never expose password hashes

**Current state:** exactly one sensitive-data-exposure regression test
exists (`TenantTest::test_login_response_does_not_expose_tenant_id`,
asserting `data.user.tenant_id` is absent). No equivalent test asserts
that `/login` or `/register` response bodies never contain a `password`
field or hash. Two independent structural protections already exist in
the application code (`UserResource`'s explicit field whitelist; the
`User` model's `#[Hidden(['password', 'remember_token'])]` attribute), so
the risk today is low — but neither protection is currently guarded by a
test that would fail if a future change silently removed either one.

**Approved change:** add an explicit `assertJsonMissingPath`-style
assertion (or equivalent) to the `/login` and `/register` success-path
tests confirming no `password`/password-hash field is present anywhere in
the response body.

**Why this matters:** a narrow, low-cost regression test that directly
guards against a specific, plausible future mistake (a `UserResource`
change or a removed `#[Hidden]` attribute silently leaking credential
material) — exactly the class of test that protects meaningful business
behavior rather than merely raising a coverage percentage.

**Explicitly not approved as part of this:** any change to `UserResource`,
the `User` model, or either endpoint's actual response shape. This adds a
guard test for the existing, correct behavior — it does not change that
behavior.

---

## Accepted low-priority testing improvement (unscheduled)

The following finding from the Sprint 5.1 audit is accepted as real but
low-priority — not assigned to a specific future sprint, not rejected:

1. **Unit-test expansion** — all 365 tests remain Feature/HTTP-level; no
   business logic (balance recalculation, recovery-stage transitions) is
   currently exercised by a true isolated unit test. This is the same gap
   already recorded in `docs/Engineering_Excellence.md`'s low-priority
   list (Sprint 4.1) — Sprint 5.1 independently re-confirmed it from the
   testing-strategy angle, and it is accepted here as still real, still
   low-priority, and still unscheduled.

This does not block any release or represent a correctness risk today; it
may be picked up opportunistically — including as a byproduct of the
already-approved `ImportService` extraction (`docs/Engineering_Excellence.md`
§1), which would make the extracted import logic independently
unit-testable — without needing a dedicated sprint of its own.

---

## Source

All decisions above arise directly from the Sprint 5.1 Testing Excellence
Audit (independent audit, evidence-driven — full test/line/method-count
inventories, two live full-suite determinism runs, and targeted searches
across `tests/`, not assumed from prior sprints — see that report's
Sections 9, 10, and 14 for the full reasoning and classification behind
each). This document does not restate that evidence in full; it records
only the decisions and enough implementation-relevant detail for a future
sprint to act on the two approved items without re-reading the whole
audit first.
