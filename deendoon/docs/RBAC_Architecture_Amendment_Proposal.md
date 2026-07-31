# RBAC Architecture Amendment — Proposal for Product Owner Approval

**Date:** 2026-07-30 (Revision 2 — supersedes Revision 1 in full)
**Status: APPROVED AND IMPLEMENTED (2026-07-31).** Revision 2 was approved with the five decisions and five implementation adjustments recorded in `Backend_Cleanup_Plan.md`, and all six phases there were executed. This document is preserved as the historical decision record — see `Backend_Cleanup_Plan.md` for exactly what was built and `Backend_Architecture_Reference.md` §6 for the current authoritative model.
**Revision history:**
- **Revision 1** proposed a tiered model (Tenant Admin / Tenant Staff / optional Tenant Viewer) and treated Collection Officer as a tenant-side workflow assignment. **Rejected by the Product Owner** — still too complex for the approved Version 1 scope.
- **Revision 2 (this document)** reflects the Product Owner's explicit correction: Version 1 has **exactly two authenticated account types, full stop** — no intermediate tiers of any kind.

---

## 1. The Approved Version 1 Authentication Model (as stated by the Product Owner)

| Application | Account type | Count per tenant |
|---|---|---|
| **Customer Mobile App** | **Business Owner** | Exactly one |
| **Super Admin Web Dashboard** | **Platform Administrator** | N/A (platform-level, not tenant-scoped) |

**Explicitly not introduced, at the Product Owner's direction:**
Tenant User, Tenant Staff, Operations Manager, Finance, Support, Viewer, Collection Officer (as a login role). None of these exist as authentication concepts in Version 1.

**Collection Officer is not an authentication role.** It is an internal operational assignment handled by Deendoon's own staff *after* a Professional Collection Request has been accepted — it describes work done on Deendoon's side of the Professional Collection workflow, not a role any tenant user or any distinct login account holds.

---

## 2. Proposed RBAC Architecture

### A. Application Users

**A.1 — Customer Mobile App: Business Owner**
- One authenticated account per tenant. This is the entirety of the tenant-side login model in Version 1 — there is no second tier, no staff accounts, no distinction between "admin" and "staff" capability within a tenant, because there is only one person to hold either.
- Full access to every tenant-scoped module: Customers, Debts, Recovery Workflow, Payments, Documents, Reports/Dashboard, Reminder Center, Notifications, Calendar, Search, Settings, My Profile.
- No financial-data segregation, no read-only tier, no additional user-management capability is part of Version 1's authentication model. (Revision 1's two "open decision points" — a Viewer tier and financial segregation — are now moot under this model and are withdrawn, not merely deferred.)

**A.2 — Super Admin Web Dashboard: Platform Administrator**
- The sole account type on this application. Deendoon's own staff, not tenant-scoped (`tenant_id = NULL`).
- No other role exists on this application in Version 1.

### B. Platform Administration

The **Platform Administrator** account type (A.2) is Deendoon's own internal staff operating the Super Admin Web Dashboard. Its approved Version 1 capability is reviewing, transitioning, and closing Professional Collection Requests submitted by any tenant — the one approved cross-tenant capability in Version 1. It has no visibility into any tenant's Customers, Debts, Payments, Documents, or the tenant's own Settings outside a relationship-scoped submitted Request.

This is unchanged from Revision 1 and remains the one part of the current implementation that already matches the approved model exactly, with no change needed.

### C. Internal Operational Assignments (not login roles, not tenant-side)

**Collection Officer** is Deendoon's own internal job function, exercised by Platform Administrator staff after a Professional Collection Request has been accepted — it is not a distinct account type, not a distinct database role, and not something the tenant's Business Owner ever assigns or sees as a role. It describes *who at Deendoon* is working a given accepted Request, which — to the extent it needs any system representation at all — is already expressible through the existing `professional_collection_requests.actioned_by_user_id` column (whichever Platform Administrator account is handling the Request), without requiring a separate role, permission, or account tier.

This is a correction from Revision 1, which incorrectly framed Collection Officer as a tenant-side assignment (`collection_cases.assigned_officer_user_id`). That framing is withdrawn — Collection Officer belongs entirely to Deendoon's internal side of the Professional Collection workflow, not to the tenant's Customer Mobile App at all.

---

## 3. Full Disposition Table — Every Prior Role/Actor, Under This Model

| Name (SRS `08` and/or current code) | Disposition under this proposal |
|---|---|
| `super_admin` (SRS) / `admin` (code) | Becomes **Business Owner** (§A.1) — the single tenant account type |
| `operations_manager` (SRS only) | **Does not exist.** No second tenant tier of any kind. |
| `finance` (SRS only) | **Does not exist.** |
| `support` (SRS only) | **Does not exist.** |
| `viewer` (SRS only) | **Does not exist.** |
| `sales_finance` (code only, no SRS name) | **Retired.** No second tenant tier exists to map it to. |
| `collection_officer` (SRS + code) | **Retired as a login role entirely.** Becomes an internal Deendoon job description (§C), not represented as a tenant-side or authenticated role of any kind. |
| `deendoon_platform_administrator` (SRS + code, exact match) | Kept exactly as-is — **Platform Administrator** (§A.2/§B) |
| `customer` (code only, no SRS counterpart) | **Retired**, as already recommended in Revision 1 — no approved actor corresponds to it, and it is confirmed inert in code today. |

**Net result: exactly two account types survive — Business Owner and Platform Administrator.** Every other name in the SRS's 7-role table and the code's 5-role seed list is retired.

---

## 4. Observations for Product Owner Awareness (not recommendations, not actions taken)

Two things already exist in the running backend that this simplified model puts in a different light. Flagging both because Rule Precedence and "Explain before refactoring" require surfacing this rather than silently working around it — no code has been touched either way.

1. **`AdminUserController`/`AdminUserService` (User Administration — create/update/deactivate additional tenant users, assign roles) has no purpose under a one-account-per-tenant model.** It is not listed as a Version 1 Flutter module in the frozen 14-module scope already on record, which is consistent with this — but it is live, tested, working backend surface with no Version 1 consumer for as long as "one Business Owner per tenant" holds. No action recommended; noting it so it isn't mistaken for a gap that needs building.
2. **`collection_cases.assigned_officer_user_id` and `PATCH /collection-cases/{case}/assign` (assign a Collection Case to a tenant user) has no meaningful target user to assign to under a one-account-per-tenant model** — the only tenant user is the Business Owner who would be assigning the case to themselves. This is already consistent with existing project memory noting "Assign officer" was excluded from the frozen Version 1 Flutter scope. No action recommended here either; same reason as above.

Neither observation asks for or implies a code change. Both are pre-existing, already-built backend capability that this RBAC simplification confirms is out of scope for Version 1's actual authentication model, not a defect introduced by this proposal.

---

## 5. Consequences for Governing Documents (listed only — none modified)

If this revision is approved, the following would need a Product-Owner-approved reopening to stay internally consistent — **not performed as part of this proposal**:

- `SRS/08_Security_and_RBAC.md` §5 — replace the 7-role table with exactly two account types (§A above).
- `SRS/02_Business_Requirements.md` §2.2 — the Actor table's BA-002–BA-006 (Operations Manager, Collection Officer as tenant-side, Finance, Support, Viewer) would need to be corrected or explicitly marked as not applicable to Version 1's authentication model; BA-003 (Collection Officer) specifically needs to be re-described as a Deendoon-internal function, not a tenant actor.
- `SRS/06_Database_Design.md` §6.1 — the `roles`/`user_roles` design assumed multiple tenant roles; would need to reflect a single tenant account type.
- `SRS/03_Functional_Requirements.md` — FR-041 (Collection Case assignment) and FR-067 ("six approved roles") would need re-reading against this model; FR-041 in particular may no longer describe a meaningful Version 1 capability under a one-account-per-tenant architecture.
- `SRS/04_Business_Rules.md` — BRL-035 (Collection Officer role restriction) and BRL-071 ("approved six roles") would need correction.

---

## 6. What Was Not Done

No code was written or modified, no database or migration was touched, no seeder was modified, and no SRS document was edited. This revision resolves both of Revision 1's open decision points by removing them (no Viewer tier, no financial-segregation tier) rather than deferring them, per the Product Owner's explicit instruction that there are no additional login roles in Version 1. Sprint 17 remains suspended pending your approval of this revised proposal.
