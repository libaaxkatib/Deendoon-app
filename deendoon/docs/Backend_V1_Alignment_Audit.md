# Backend Version 1 Alignment Audit

**Date:** 2026-07-30
**Workspace:** Deendoon Backend (Laravel/PostgreSQL/REST API only — no Flutter content)
**Trigger:** The Product Owner's approved Version 1 authentication model (exactly two account types: **Business Owner** on the Customer Mobile App, **Platform Administrator** on the Super Admin Web Dashboard; see `RBAC_Architecture_Amendment_Proposal.md` Revision 2) requires re-checking every backend construct that assumed a richer role model, plus re-classifying already-known backend findings against actual Version 1 scope.
**Status: EXECUTED (2026-07-31).** All Part 1 findings below were acted on per `Backend_Cleanup_Plan.md`'s six phases (with the Product Owner's five approved revisions). Part 2's re-classifications were also applied where in scope (§1.3's `POST /register` fix; see `Known_Backend_Issues.md` for its resolved status). Preserved as the analysis record this audit was built from.
**Scope of this audit:** two parts. Part 1 covers everything directly driven by the new 2-role architecture (roles, policies, gates, requests, controllers, SRS role content). Part 2 re-classifies the pre-existing findings from `Known_Backend_Issues.md` against actual Version 1 scope, since several of those findings interact with this same architecture decision. Modules with no RBAC or V1-scope dependency (e.g., payment calculation logic, document PDF generation mechanics) are not re-audited here — they were already covered in `Backend_Audit_Report.md`/`Known_Backend_Issues.md` and are unaffected by this decision.

---

## Part 1 — RBAC / Role-Model-Driven Findings

### 1.1 Roles & Seeders

| Item | Current state | Classification | Reasoning |
|---|---|---|---|
| `admin` role | Seeded, checked in every tenant-scoped Policy | **KEEP** (rename under review) | Becomes *the* Business Owner account's role. Whether the underlying role *string* should be renamed from `admin` to `business_owner` is a naming decision for the Cleanup Plan — the capability it grants doesn't change. |
| `sales_finance` role | Seeded, checked alongside `admin` in 8 of 11 policies | **REMOVE** | No second tenant tier exists under the approved model. Every `hasAnyRole(['admin', 'sales_finance'])` check collapses to just `hasRole('admin')` once this is gone. |
| `customer` role | Seeded, has its own `customer-only` Gate | **REMOVE** | Already recommended in `Role_Model_Audit.md` — no approved actor corresponds to it, and it's provably inert (its Gate is defined but never invoked anywhere in `app/`). |
| `collection_officer` role | Seeded, checked in `ReminderPolicy` only | **REMOVE** (as an authentication role) | Per the Product Owner's explicit correction: Collection Officer is Deendoon's own internal operational responsibility (Platform Administrator side, post-acceptance), never a tenant-side login role. |
| `deendoon_platform_administrator` role | Seeded, checked in `ProfessionalCollectionRequestPolicy`, `view-dashboard` Gate | **KEEP** | Exact match with the approved Platform Administrator account type. No change. |

### 1.2 Gates (`AppServiceProvider::boot()`)

| Gate | Current definition | Classification | Reasoning |
|---|---|---|---|
| `admin-only` | `hasRole('admin')` | **KEEP** | Becomes the general "is the Business Owner" check — still meaningful and still the correct mechanism, just no longer needs to be distinguished from a `sales_finance` counterpart. |
| `sales-finance-only` | `hasRole('sales_finance')` | **REMOVE** | Dead once `sales_finance` is removed. Confirmed used only by its own test today. |
| `customer-only` | `hasRole('customer')` | **REMOVE** | Already confirmed dead (never invoked anywhere outside its own definition and test). |
| `view-reports` | `hasAnyRole(['admin', 'sales_finance'])` | **SIMPLIFY** | Drop `sales_finance` — becomes `hasRole('admin')`, i.e., "the tenant's Business Owner." |
| `view-dashboard` | `hasAnyRole(['admin', 'sales_finance'])` OR platform-admin branch | **SIMPLIFY** | Same — drop `sales_finance` from the tenant-side clause; the platform-admin clause is unaffected. |

### 1.3 Policies (11 files)

| Policy | Current role check(s) | Classification | Reasoning |
|---|---|---|---|
| `CustomerPolicy`, `DebtPolicy`, `CollectionCasePolicy`, `ReceiptPolicy`, `DemandLetterPolicy`, `InvoicePolicy`, `StatementPolicy` (7 policies) | `hasAnyRole(['admin', 'sales_finance'])` throughout | **SIMPLIFY** | Each collapses to `hasRole('admin')`. Same authorization outcome for the tenant's one account; removes a now-meaningless role from every check. |
| `ReminderPolicy` | `hasAnyRole(['admin', 'sales_finance', 'collection_officer'])` for view/create/complete/send; `hasAnyRole(['admin','sales_finance'])` **or** creator-match for update/delete | **SIMPLIFY** | Drop `sales_finance` and `collection_officer` from both checks. The "creator-or-manager" distinction in update/delete becomes moot once there's only one possible creator (the Business Owner) — likely collapses to just `hasRole('admin')` with no ownership branch needed, pending confirmation there's no scenario where a Reminder is created by anyone else (system-side reminders don't go through this policy check). |
| `NotificationPolicy` | Pure ownership (`recipient_user_id === $user->id`), no role check | **KEEP** | Unaffected by the role model — this was never role-based. |
| `UserPolicy` | `hasRole('admin')` + same-tenant match, across viewAny/view/create/update/deactivate/assignRole | **REMOVE** (as currently scoped) | This entire policy exists to let one tenant user administer *other* tenant users. Under a one-account-per-tenant model there are no other tenant users to view/create/update/deactivate/assign a role to. See §1.4 below — this is tied directly to `AdminUserController`. |
| `ProfessionalCollectionRequestPolicy` | `submit`/`view`/`postMessage` → `isTenantActor()` = `hasAnyRole(['admin','sales_finance'])`; `transitionStatus`/`close` → `isPlatformAdmin()` only | **SIMPLIFY** (tenant side only) | `isTenantActor()` drops `sales_finance`, becomes `hasRole('admin')`. The Platform Administrator side (`transitionStatus`/`close`) is unaffected — this is the Business-Owner-submits / Deendoon-actions workflow described by the Product Owner, and it stays intact. |

### 1.4 Controllers / Services / Requests tied to the retired roles

| Item | Current behavior | Classification | Reasoning |
|---|---|---|---|
| `AdminUserController` (index, store, show, update, deactivate, updateRole) + `AdminUserService` | Full CRUD + role assignment for *other* users within a tenant | **REMOVE** | No second tenant user exists to manage under a one-account-per-tenant model. This is the direct backend consequence of the Product Owner's decision, already flagged as an observation in the RBAC proposal — this audit formalizes that observation into a classification. |
| `CreateUserRequest`, `UpdateUserRequest`, `AssignUserRoleRequest` | Validate name/email/password/role for creating/updating/re-roling a tenant user | **REMOVE** | Exist solely to serve `AdminUserController`. Removed alongside it. |
| `PATCH /admin/users/{user}/role` route + `updateRole()`/`assignRole()` | Assigns one of a hardcoded 4-role whitelist to a tenant user | **REMOVE** | Same reasoning — no second role, no second user, nothing to assign. |
| `CollectionCaseController::assign()` + `PATCH /collection-cases/{case}/assign` + `AssignCollectionCaseRequest` | Assigns a Collection Case to a tenant user by `officer_user_id` | **REMOVE** | Already flagged as an observation in the RBAC proposal: under a one-account-per-tenant model, the only possible assignee is the Business Owner themselves — a self-assignment action with no real purpose. `collection_cases.assigned_officer_user_id` itself (the column) is a database-schema question, not touched by this audit — see the Cleanup Plan for how to phase this safely. |
| `GET /auth/me` (FR-006, not yet implemented — the original Sprint 17 trigger) | N/A — doesn't exist yet | **KEEP, simplified** | Still needed (this is what unblocks Sprint 17), but now trivial: since there's only one possible tenant role, "resolve the user's role" returns either `business_owner` or `platform_administrator` with no further nuance. Substantially simpler to build than originally scoped. |
| `ProfessionalCollectionRequestController` (submit, index, show, messages) — tenant-facing side | Business Owner submits/views/messages on a Request | **KEEP** | This is exactly the Business-Owner-facing half of the workflow the Product Owner confirmed still exists ("after a Professional Collection Request has been accepted" implies submission/acceptance is still a real, in-scope flow). Unaffected by the role simplification. |
| `ProfessionalCollectionRequestController` (updateStatus, close) — platform-admin side | Platform Administrator transitions/closes a Request | **KEEP** | Unaffected — this is exactly where "Collection Officer" work happens, performed by whichever Platform Administrator account is handling it. No separate role needed to represent this, per the Product Owner's own framing. |

### 1.5 SRS Documents (role-model content only)

Per the Engineering Constitution's Rule Precedence, the SRS remains authoritative and is not modified here — these are classifications for a future Product-Owner-approved reopening, listed for completeness since the audit was asked to cover SRS as well as Backend.

| Document / Section | Current content | Classification | Reasoning |
|---|---|---|---|
| `SRS/08_Security_and_RBAC.md` §5 | 7-role table | **SIMPLIFY** | Replace with the 2-account-type table from the approved RBAC proposal. |
| `SRS/02_Business_Requirements.md` §2.2 Actor table | BA-002 (Operations Manager), BA-003 (Collection Officer, as a tenant actor), BA-004 (Finance), BA-005 (Support), BA-006 (Viewer) | **SIMPLIFY / REMOVE** | BA-002/004/005/006 have no account type to trace to anymore — remove or explicitly mark not-applicable-to-V1. BA-003 needs re-description as a Deendoon-internal function (Platform Administrator side), not a tenant actor. |
| `SRS/06_Database_Design.md` §6.1 `roles`/`user_roles` design | Fixed 7-row lookup + many-to-many join, `is_tenant_scoped` column | **SIMPLIFY** | Redesign to reflect exactly two account types (however that's ultimately modeled — see Cleanup Plan for the schema question this doesn't resolve). |
| `SRS/03_Functional_Requirements.md` FR-041 (Collection Case assignment) | Assign a case to a Collection Officer | **REMOVE or re-scope** | No meaningful tenant-side assignment target exists. If Collection Case assignment is retained at all, it would need complete re-description against the new model — not a simple wording fix. |
| `SRS/03_Functional_Requirements.md` FR-067 ("six approved roles") | Role & Permission Management, six-role assignment | **REMOVE** | No role management capability exists under a one-account-per-tenant model — this FR's entire premise (an admin assigning roles to staff) no longer applies. |
| `SRS/04_Business_Rules.md` BRL-047, BRL-071 | Collection Case assignment rules; six-role cardinality (correction: the assignment rule is BRL-047 "Assignment Rules," not BRL-035 "Escalation Eligibility" as originally mislabeled here — verified against source during Phase 8) | **REMOVE / SIMPLIFY** | BRL-047 retired alongside FR-041; BRL-071 (DD-039, multi-role) resolved as moot with only one possible role. Both applied — see SRS revision histories. |

---

## Part 2 — Re-Classification of Existing `Known_Backend_Issues.md` Findings

Findings from the prior full backend audit, re-examined against actual Version 1 scope (not just RBAC). Only items with a bearing on V1 scope/architecture are listed; purely technical items (performance, N+1, migration-ordering anomalies) are unaffected by this decision and retain their original classification in that document — not repeated here.

| Original finding | Classification | Reasoning |
|---|---|---|
| §1.3 `POST /register` creates a permission-less, tenant-less account | **REMOVE or REMAP** | Under the approved model, tenant account creation is presumably a controlled, Deendoon-side or first-run process (one Business Owner per tenant), not open self-registration. This endpoint's purpose needs a Product Owner decision regardless of RBAC — flagged again here because the "no second tenant user" model makes an open self-registration endpoint even less clearly justified than before. |
| §1.1 `MessageController::templates()`/`render()` missing authorization | **KEEP finding, SIMPLIFY fix** | Still a real gap, but the fix is now simpler — add `hasRole('admin')` (i.e., "is the Business Owner") rather than a multi-role check. |
| §3.6 No web admin dashboard exists in this repository | **KEEP as open item** | Directly relevant now: the Super Admin Web Dashboard is one of the two approved V1 applications and doesn't exist as a project in this repo. This was already flagged; it's now confirmed architecturally essential, not optional, since it's the only interface the Platform Administrator account type has. |
| §3.3 Message delivery (WhatsApp/SMS) is simulated | **KEEP** (unaffected) | No bearing on the role model. |
| §3.4 Scheduled reminder delivery has no scheduler wired up | **KEEP** (unaffected) | No bearing on the role model. |
| Roles & Permissions (§10 of `Backend_Architecture_Reference.md`) — spatie `Permission` model installed but unused | **REMOVE (the unused half)** | With the role model simplifying to two account types, the case for ever adopting granular permissions in V1 weakens further. Recommend formally dropping the unused `permissions`/`model_has_permissions`/`role_has_permissions` tables rather than carrying installed-but-dead package machinery indefinitely — a Product Owner call, listed in the Cleanup Plan. |

---

## Summary Counts

| Classification | Count (Part 1 + relevant Part 2 items) |
|---|---|
| KEEP | 9 |
| SIMPLIFY | 9 |
| REMOVE | 11 |

Full sequencing and concrete steps for whatever the Product Owner approves are in the companion document, `Backend_Cleanup_Plan.md`. No action has been taken on any item above.
