# Role Model Audit — SRS vs. Implementation

**Date:** 2026-07-30
**Status: Historical record.** The Product Owner rejected this document's own recommendation (adopt the SRS's 7-role model) in favor of a much simpler two-account-type model — see `RBAC_Architecture_Amendment_Proposal.md` (Revision 2, approved and implemented 2026-07-31). This document's factual findings (what was implemented as of 2026-07-30) remain accurate as a record of the state before that decision.
**Trigger:** Pre-implementation review for Sprint 17 ("Security & RBAC Foundation" — building `GET /me`, FR-006). Before sizing that sprint, a conflict was found between the approved SRS's RBAC model and the actually implemented role model. Per the Engineering Constitution's Rule Precedence and "stop on conflict" requirements, this audit exists to make the conflict precise before any decision is made.
**Scope of this document:** analysis only. No code was modified. No SRS document was modified. No roles were reseeded. This document does not recommend a *specific* mechanical fix — it isolates every difference and offers a recommendation on which model should become the single source of truth, per your request.

---

## 1. Current Implementation

### 1.1 Roles actually seeded

`database/seeders/RoleSeeder.php` — exactly **5 roles**, via `spatie/laravel-permission`, guard `web`, created idempotently with `Role::firstOrCreate()`:

```
admin, sales_finance, customer, collection_officer, deendoon_platform_administrator
```

The seeder's own docblock states this is a layered, interim construction: an original **three-role set** (`admin`, `sales_finance`, `customer`) with two more added later specifically for Module 7 (Professional Collection) — `collection_officer` (because FR-041 E2 names Collection Officer by role) and `deendoon_platform_administrator` (because FR-072–076 require a distinct, non-tenant `tenant_id = NULL` actor). The docblock explicitly calls the original three "the interim admin/sales_finance simplification."

### 1.2 Policies (11 files) — exact role checks

| Policy | Methods | Role check |
|---|---|---|
| `CustomerPolicy` | viewAny, view, create, update, archive, restore, import, viewCreditScore, updateRiskLevel, generateDocuments | `hasAnyRole(['admin', 'sales_finance'])` |
| `DebtPolicy` | viewAny, view, create, update, archive, restore, manageRecovery, recordPayment, escalate, generateDocuments | `hasAnyRole(['admin', 'sales_finance'])` |
| `CollectionCasePolicy` | viewAny, view, manage | `hasAnyRole(['admin', 'sales_finance'])` |
| `ReceiptPolicy` | viewAny, view | `hasAnyRole(['admin', 'sales_finance'])` |
| `DemandLetterPolicy` | viewAny, view | `hasAnyRole(['admin', 'sales_finance'])` |
| `InvoicePolicy` | viewAny, view | `hasAnyRole(['admin', 'sales_finance'])` |
| `StatementPolicy` | viewAny, view | `hasAnyRole(['admin', 'sales_finance'])` |
| `ReminderPolicy` | viewAny, view, create, complete, send | `hasAnyRole(['admin', 'sales_finance', 'collection_officer'])` |
| `ReminderPolicy` | update, delete | `hasAnyRole(['admin', 'sales_finance'])` **OR** requester is the reminder's own creator |
| `NotificationPolicy` | view | Pure ownership — `recipient_user_id === $user->id` (no role check at all) |
| `UserPolicy` | viewAny, view, create, update, deactivate, assignRole | `hasRole('admin')` only (the one admin-exclusive policy); `view`/`update`/`deactivate`/`assignRole` additionally require same-tenant match |
| `ProfessionalCollectionRequestPolicy` | submit | `hasAnyRole(['admin', 'sales_finance'])` |
| `ProfessionalCollectionRequestPolicy` | view, postMessage | `isPlatformAdmin()` (tenant_id null + `deendoon_platform_administrator`) **OR** `hasAnyRole(['admin', 'sales_finance'])` |
| `ProfessionalCollectionRequestPolicy` | transitionStatus, close | `isPlatformAdmin()` **only** |

**Roles actually referenced anywhere in a Policy:** `admin`, `sales_finance`, `collection_officer`, `deendoon_platform_administrator`. **`customer` is never referenced by any Policy.**

### 1.3 Gates (`AppServiceProvider::boot()`, not tied to a model)

```php
Gate::define('admin-only',         fn ($u) => $u->hasRole('admin'));
Gate::define('sales-finance-only', fn ($u) => $u->hasRole('sales_finance'));
Gate::define('customer-only',      fn ($u) => $u->hasRole('customer'));
Gate::define('view-reports',       fn ($u) => $u->hasAnyRole(['admin', 'sales_finance']));
Gate::define('view-dashboard',     fn ($u) => $u->hasAnyRole(['admin', 'sales_finance'])
                                              || ($u->tenant_id === null && $u->hasRole('deendoon_platform_administrator')));
```

**Verified directly (grep across the entire `app/` tree and `routes/`): `customer-only` is never called anywhere except its own definition.** No controller, no route, no other Gate references it. Assigning a user the `customer` role today unlocks **zero** capability in this application — it is a fully inert role.

### 1.4 Middleware

No role- or permission-checking middleware exists. There is no `middleware('role:...')`/`middleware('permission:...')` anywhere in `routes/api.php` (verified). All authorization happens inside Controllers via `$this->authorize()` / `Gate::authorize()`, resolving to the Policies/Gates above.

### 1.5 Role-assignment API behavior

- `PATCH /admin/users/{user}/role` → `AdminUserController::updateRole()` → `UserPolicy::assignRole` (admin, same-tenant) → `AssignUserRoleRequest`.
- `AssignUserRoleRequest` and `CreateUserRequest` both validate the `role` field against a **hardcoded** PHP whitelist: `Rule::in(['admin', 'sales_finance', 'customer', 'collection_officer'])`. `deendoon_platform_administrator` is deliberately excluded from this list (it's never assignable through the tenant admin UI — consistent with it being a distinct platform-level actor).
- Assignment is single-role: `AdminUserService::assignRole()` calls `$user->syncRoles([$role])` (replace, not add).

### 1.6 Tests

`tests/Feature/Auth/RoleAuthorizationTest.php` is the authoritative test of the role model as currently understood by the codebase itself:

- `test_role_seeder_creates_exactly_the_five_approved_roles()` — asserts exactly 5 rows in `roles`, matching the 5 named above. The test's own name calls this "the five approved roles."
- Confirms idempotent seeding, role assignment, gate-allow/deny behavior for `admin`, `sales_finance`, `customer` specifically, and that protected routes require authentication regardless of role.
- No test references `super_admin`, `operations_manager`, `finance`, `support`, or `viewer` anywhere in the test suite (confirmed by the same search that found this file — those five SRS role names do not appear anywhere in `tests/`).

### 1.7 Database schema (actual)

Roles are stored in **spatie/laravel-permission's own tables** (`2026_07_25_095446_create_permission_tables.php`, non-teams variant): `roles` (`id` bigint, `name`, `guard_name`), `permissions`, `model_has_roles` (polymorphic `model_type`/`model_id`, not a dedicated `user_id`/`role_id` pair), `model_has_permissions`, `role_has_permissions`. `permissions` and the `model_has_permissions`/`role_has_permissions` tables are installed but have zero references anywhere in application code — every authorization check in this codebase is role-based (`hasRole`/`hasAnyRole`), never permission-based.

---

## 2. SRS Role Model

### 2.1 Expected roles — `SRS/08_Security_and_RBAC.md` §5 (verbatim table)

| Role (`06` `roles.name`) | Tenant-Scoped? | Approved Actor | Typical Capability |
|---|---|---|---|
| `super_admin` (**Tenant Super Admin**) | Yes | BA-001, Business Owner / SME Operator | Full access within the tenant: Customers, Debts, Payments, Collection Cases, Documents, Reports/Dashboard, and Administration (Module 12). May submit a Professional Collection Request; cannot review/action another tenant's Request. |
| `operations_manager` | Yes | BA-002, Operations Manager | Day-to-day recovery oversight: Customers, Debts, Recovery Workflow, Payment visibility, Collection Case assignment (FR-041) and management, Reports/Dashboard. Administration (Module 12) is **not** part of this role's default scope. |
| `collection_officer` | Yes | BA-003, Collection Officer | Executes follow-up/collection actions on assigned Customers/Debts/Cases — Manual Reminders (FR-030), Promise to Pay (FR-031), Collection Activity (FR-044). FR-041 E2 restricts Case assignment *to* this role by name. |
| `finance` | Yes | BA-004, Finance Staff | Payments (FR-034–039), Receipts/Statements (FR-047, FR-049), financial reporting (FR-055 credit-risk/payment reports). Not a collection-workflow role by default. |
| `support` | Yes | BA-005, Support Staff | Limited operational access — view Customers/Debts, assist with non-financial actions. Explicitly "not a financial decision-maker" — Payment recording and Credit Limit changes are outside its default scope. |
| `viewer` | Yes | BA-006, Viewer | Read-only across every module this role can see; no create/update/archive/close action anywhere. |
| `deendoon_platform_administrator` (**Deendoon Platform Administrator**) | **No** | BA-008 | Reviews/transitions/closes Professional Collection Requests across every tenant — the one cross-tenant capability in V1. No access to any tenant's Customers/Debts/Payments/Administration outside a relationship-scoped submitted Request. |

**Exactly seven roles: six tenant-scoped + one platform-level.** The SRS's own consistency check (§5) explicitly states every row traces to an approved Business Actor (`02_Business_Requirements.md` §2.2) and an approved role name (`06_Database_Design.md` §6.1) — "no role, and no capability beyond what's textually supported by those two documents, was added."

### 2.2 Expected schema — `SRS/06_Database_Design.md` §6.1

A **dedicated, purpose-built schema**, not a third-party package's tables:

- **`roles`** — fixed lookup table. Columns include `is_tenant_scoped BOOLEAN NOT NULL DEFAULT TRUE` (`FALSE` only for `deendoon_platform_administrator`). "Seeded with exactly seven rows at deployment; no FR provides a create/edit/delete path for this table."
- **`user_roles`** — dedicated join table (`user_id` FK, `role_id` FK, `assigned_at` timestamp), modeled many-to-many "deliberately... whether a user may hold more than one Role is DD-039 (unresolved)... single-role is simply 'the application enforces at most one row per user_id' — without a future schema migration. Do not read the many-to-many *shape* as confirmation that multi-role is approved."
- No `permissions` table, no `model_has_roles`/`role_has_permissions` — the SRS's model has no concept of a separate granular-permission table; "permission set" in FR-006 refers to the fixed capability matrix associated with each of the 7 roles (§5's table), not a database-level permission entity.

### 2.3 Business Actors — `SRS/02_Business_Requirements.md` §2.2

| Actor | Name | Description |
|---|---|---|
| BA-001 | Business Owner / SME Operator | Primary user; owns the tenant; manages customers, debts, recovery activity |
| BA-002 | Operations Manager | Oversees day-to-day recovery operations |
| BA-003 | Collection Officer | Executes follow-up/collection actions on assigned customers/debts |
| BA-004 | Finance Staff | Manages payments, receipts, statements, financial reporting |
| BA-005 | Support Staff | Limited operational access; not a financial decision-maker |
| BA-006 | Viewer | Read-only, typically for oversight/audit |
| BA-007 | **Customer (Debtor)** | **External actor; owes money to the business; receives reminders and documents. Does not use the Customer Mobile App.** |
| BA-008 | Deendoon Platform Administrator (Super Admin) | Operates the Super Admin Web Panel at the true platform level; the only Deendoon-side actor in V1 |

**BA-007 is explicitly not a system user** — it's the tenant's own debtor/customer (a data subject the system tracks), not an actor who authenticates into the app. The SRS's §5 role table (2.1 above) has no role for BA-007 at all, consistent with this — BA-007 is excluded from the 7 approved roles by design, not by omission.

---

## 3. Comparison Table — Every Difference

| # | Dimension | SRS (approved) | Implementation (actual) | Match? |
|---|---|---|---|---|
| 1 | Role count | 7 | 5 | ✗ |
| 2 | `super_admin` | Present (BA-001, full tenant access incl. Administration) | Named `admin` instead — same apparent scope (only role checked against `UserPolicy`'s admin-only gate, `admin-only` Gate) but never formally mapped/confirmed as the same actor | ✗ (name) / unconfirmed (scope) |
| 3 | `operations_manager` | Present (BA-002, day-to-day recovery oversight, no Administration access) | **Does not exist.** Its described capability set (Customers/Debts/Recovery/Payments visibility/Case management/Reports) is currently granted to the interim `sales_finance` role instead (same `hasAnyRole(['admin','sales_finance'])` check used almost everywhere) | ✗ missing |
| 4 | `finance` | Present (BA-004, Payments/Receipts/Statements/financial reporting only — explicitly "not a collection-workflow role") | **Does not exist as such.** `sales_finance` covers this ground but is bundled with `operations_manager`'s entire scope too (both map to the same `hasAnyRole(['admin','sales_finance'])` check across Customer/Debt/CollectionCase/Reminder policies) — broader than SRS's `finance` definition | ✗ (renamed + scope-merged with operations_manager) |
| 5 | `support` | Present (BA-005, limited operational, view-only + non-financial actions) | **Does not exist.** No policy or gate in the codebase implements a "view but no financial action" tier | ✗ missing |
| 6 | `viewer` | Present (BA-006, fully read-only) | **Does not exist.** No read-only role/gate exists anywhere | ✗ missing |
| 7 | `collection_officer` | Present (BA-003, follow-up/collection actions on assigned entities, named explicitly in FR-041 E2) | Present, same name | ✓ exact match |
| 8 | `deendoon_platform_administrator` | Present (BA-008, cross-tenant Professional Collection Request review only) | Present, same name, same scope (`isPlatformAdmin()` = `tenant_id === null && hasRole('deendoon_platform_administrator')`) | ✓ exact match |
| 9 | `customer` role | **Does not exist in the SRS's 7-role table at all.** BA-007 ("Customer (Debtor)") is the SRS actor with a similar name, but is explicitly an *external, non-authenticating* actor — "does not use the Customer Mobile App" | Exists as a seeded, assignable role with its own `customer-only` Gate | ✗ — implementation has an extra role the SRS's RBAC model has no place for, and the Gate for it is never actually invoked anywhere (fully inert) |
| 10 | Schema | Dedicated `roles` (with `is_tenant_scoped`) + `user_roles` join table, purpose-built | spatie/laravel-permission's generic tables (`roles`, `permissions`, `model_has_roles` polymorphic, `role_has_permissions`) | ✗ |
| 11 | Permission granularity | Role = fixed capability matrix (no separate permission entity) | Package supports fine-grained `Permission` records, but **zero are used** — role-only in practice | Practically equivalent today, but the installed machinery doesn't match the SRS's simpler model either |
| 12 | Multi-role support | DD-039 explicitly unresolved; schema (many-to-many) deliberately left open either way | De facto single-role only (`syncRoles([$role])` replaces, never adds) | Not a contradiction — the implementation's choice is *within* what DD-039 leaves open — but DD-039 itself is still formally unresolved in the SRS |
| 13 | Role-assignment API whitelist | N/A (SRS doesn't define an assignment endpoint restriction beyond FR-067's general "one of the approved roles") | Hardcoded to `['admin', 'sales_finance', 'customer', 'collection_officer']` — excludes `deendoon_platform_administrator` (reasonable) but obviously doesn't include the SRS's actual 7 names either | ✗ |

---

## 4. Recommendation

**This document does not implement a fix — per your instruction, it stops at identifying the conflict precisely. The choice below is a recommendation for the Product Owner to approve, not a decision already made.**

**Recommendation: the SRS's 7-role model (`08_Security_and_RBAC.md` §5) should become the project's single source of truth going forward, with the current 5-role implementation formally treated as an incomplete, interim rollout of it — not as a competing, equally-valid model.**

Reasoning:

1. **The implementation's own documentation already frames itself as interim, not final.** The `RoleSeeder` docblock calls the original three roles "the interim admin/sales_finance simplification" — this is the codebase admitting, in its own words, that it is a placeholder, not a considered alternative to the SRS.
2. **Two of the five implemented roles are exact matches** (`collection_officer`, `deendoon_platform_administrator`) — proving the two models aren't fundamentally incompatible; they diverge specifically where the interim shortcut merged multiple SRS roles into one (`operations_manager` + `finance` → `sales_finance`) or renamed one (`super_admin` → `admin`).
3. **The `customer` role is not a reduction of scope — it's a role the approved RBAC model has no place for at all**, since its nearest-sounding SRS actor (BA-007) is explicitly not a system user. Keeping it as authoritative would mean formally approving a role the SRS's own consistency check (§5) would fail today. It is also entirely inert in current code (zero enforcement points), so removing/reclassifying it carries no functional regression risk.
4. **`support` and `viewer` represent real, described capability tiers** (non-financial operational access; pure read-only) that the current implementation cannot express at all — any user who should have only one of those tiers today must be over-granted `sales_finance` access (which includes payment recording and credit limit changes — explicitly *outside* `support`'s intended scope per BA-005). This is a live least-privilege gap, not a cosmetic naming difference.
5. **Formalizing the 5-role model instead** would require re-opening and amending `08_Security_and_RBAC.md` (and `06_Database_Design.md`'s `roles`/`user_roles` design) to retroactively match code — inverting the Constitution's own precedence (SRS governs implementation, not the reverse) and discarding the `support`/`viewer`/`operations_manager` distinctions without a recorded business reason for dropping them.

**What this implies for Sprint 17, if this recommendation is approved:** Sprint 17's scope would grow beyond "just build `GET /me`" — it would need to also close the role-model gap (at minimum: reseed the 2 missing/renamed roles correctly, split `sales_finance`'s over-broad policy grants back into `operations_manager`/`finance` per §5's actual capability table, add `support`/`viewer` tiers, and reconsider whether `customer` should be removed or redefined) before `GET /me` can honestly "resolve the user's role" against the approved model. That is a materially larger sprint than originally sized — which is exactly why this needed to surface before planning began, not after.

**No action has been taken.** Awaiting your decision on the recommendation above before any Sprint 17 planning resumes.
