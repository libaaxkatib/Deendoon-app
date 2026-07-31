# Backend Cleanup Plan — Version 1 RBAC Alignment

**Date:** 2026-07-30
**Status: EXECUTED (2026-07-31).** All 6 phases were implemented as approved (with the 5 revisions/adjustments the Product Owner specified — see the top of this document). Full test suite green (432/432) after implementation. Preserved as the implementation record.
**Depends on:** `Backend_V1_Alignment_Audit.md` (the classifications this plan sequences into action) and `RBAC_Architecture_Amendment_Proposal.md` Revision 2 (the approved target model).

---

## Decisions Needed Before Implementation Can Begin

These aren't technical questions — they're Product Owner calls this plan cannot proceed past without an answer:

1. **Role naming:** should the `admin` role string be renamed to something like `business_owner` for clarity, or kept as `admin` (functionally identical, just a label)? Renaming touches the seeder, every Policy check, and the role-check tests — a mechanical but non-trivial change. **Recommend keeping `admin`** unless there's a specific reason to rename, to minimize churn for a purely cosmetic change.
2. **`collection_cases.assigned_officer_user_id` column and the "assign" feature:** fully remove the column/endpoint now, or leave the column in place (unused) for now and only remove the endpoint/UI-facing capability? **Recommend leaving the column in place** (it's nullable, harmless if unused) and only removing the `assign()` endpoint/route/Request/Policy method — a column removal is a real migration with more downstream risk for no immediate benefit.
3. **`POST /register`'s fate:** this plan does not resolve it (it's a pre-existing open item, not created by the RBAC decision) — needs its own explicit decision (remove entirely, or repurpose as the one-time "create the tenant's Business Owner account" flow, which would actually give it a clear purpose it currently lacks).
4. **spatie `permissions`/`model_has_permissions`/`role_has_permissions` tables:** drop them (they're unused today and even less likely to be needed under a 2-account model), or leave the package's full table set in place for possible future use? **Recommend leaving them** — dropping unused, harmless tables is low-value cleanup that adds migration risk for no behavioral change; simpler to just stop pretending they're relevant in documentation.
5. **SRS reopening:** this plan only touches code. The SRS corrections listed in `Backend_V1_Alignment_Audit.md` §1.5 are a separate approval track (the Guardian/reopening process) — confirm whether you want that pursued in parallel, after, or not as part of this Sprint 17 unblock at all.

---

## Phase 1 — Policies & Gates (lowest risk, no schema change, fully reversible)

Order matters: simplify every role check *before* removing the roles themselves, so nothing references a role that no longer exists mid-change.

1. `CustomerPolicy`, `DebtPolicy`, `CollectionCasePolicy`, `ReceiptPolicy`, `DemandLetterPolicy`, `InvoicePolicy`, `StatementPolicy` — replace `hasAnyRole(['admin', 'sales_finance'])` with `hasRole('admin')` throughout.
2. `ReminderPolicy` — replace `hasAnyRole(['admin', 'sales_finance', 'collection_officer'])` with `hasRole('admin')`; re-examine whether the creator-or-manager branch on update/delete is still needed (likely reduces to just `hasRole('admin')`, but confirm no system process creates a Reminder under a different actor first).
3. `ProfessionalCollectionRequestPolicy::isTenantActor()` — replace `hasAnyRole(['admin', 'sales_finance'])` with `hasRole('admin')`.
4. `AppServiceProvider::boot()` — simplify `view-reports` and `view-dashboard` Gates to drop `sales_finance`.
5. Update every affected test (Feature tests asserting `sales_finance`/`collection_officer` grant access) to reflect the simplified checks.

## Phase 2 — Remove Dead Gates & Roles

1. Remove `sales-finance-only` and `customer-only` `Gate::define()` calls from `AppServiceProvider`.
2. Update `RoleSeeder.php` to seed only `admin` and `deendoon_platform_administrator` (dropping `sales_finance`, `customer`, `collection_officer`).
3. Update `RoleAuthorizationTest.php` (currently asserts "exactly the five approved roles") to assert the new count/names.
4. **Note:** this phase changes seeded data, not a migration — existing databases with users already holding a retired role need a data-migration decision (reassign or leave as an orphaned role assignment) before this ships to any non-fresh environment. Flag for confirmation before executing.

## Phase 3 — Remove Multi-User Tenant Administration

1. Remove `AdminUserController`, `AdminUserService`, `UserPolicy`.
2. Remove `CreateUserRequest`, `UpdateUserRequest`, `AssignUserRoleRequest`.
3. Remove the six `admin/users*` routes from `routes/api.php` (`GET /admin/users`, `POST /admin/users`, `GET /admin/users/{user}`, `PUT /admin/users/{user}`, `POST /admin/users/{user}/deactivate`, `PATCH /admin/users/{user}/role`).
4. Remove/update any test coverage exercising these (`AdministrationTest.php` and any user-management assertions within it).
5. Remove `Gate::policy(User::class, UserPolicy::class)` registration.

## Phase 4 — Remove Collection Case Officer Assignment

1. Remove `CollectionCaseController::assign()`, `AssignCollectionCaseRequest`.
2. Remove the `PATCH /collection-cases/{case}/assign` route.
3. Remove `CollectionCasePolicy::manage`'s use for this specific action if `manage` is otherwise still needed for update/activities/close (confirm `manage` isn't solely used for assignment before removing the whole method — it's also used by `update()`, `recordActivity()`, and `close()`, so the *method* stays; only the assignment call site goes away).
4. Leave `collection_cases.assigned_officer_user_id` in the schema, per Decision 2 above, unless told otherwise.
5. Update/remove any test asserting the assign endpoint.

## Phase 5 — Implement Sprint 17's Actual Deliverable (Simplified)

Now that the role model is settled, Sprint 17 can resume with its original, much smaller scope:

1. Implement `GET /auth/me` (FR-006) — returns the authenticated user's basic profile plus resolved role: `business_owner` or `platform_administrator`, nothing more. No permission array, no multi-role resolution logic needed.
2. This is a genuinely small endpoint under the simplified model — a fraction of the size Sprint 17 would have needed under either the SRS's 7-role model or Revision 1's tiered proposal.

## Phase 6 — Documentation Consistency

1. Update `Backend_Architecture_Reference.md` §6 (Authorization Model) to reflect the 2-role reality.
2. Update `Known_Backend_Issues.md` to close/reclassify the items addressed above (mark as Resolved rather than deleting the entries, per that document's own "update status, don't let it drift" instruction).
3. Mark `Role_Model_Audit.md` and `RBAC_Architecture_Amendment_Proposal.md` as historical record of the decision process (not delete — they're the record of how this was reached).

---

## What This Plan Does Not Do

- Does not touch Flutter in any way (out of scope for this workspace).
- Does not modify the SRS (a separate, explicitly-gated approval track per Decision 5 above).
- Does not resolve `POST /register`'s fate (Decision 3) — that needs its own answer first.
- Does not drop any database table or column (Decisions 2 and 4 both default to "leave in place" pending your confirmation).
- Does not begin until you approve — in whole or by phase.

**Awaiting your approval before any implementation begins.**
