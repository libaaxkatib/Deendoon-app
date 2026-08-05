# Backend v2.1 — Database Alignment

**Source of truth:**
- `docs/Mobile_UI_V1_Frozen.md` (UI Version 1.0 — APPROVED, FROZEN, 2026-07-27)
- `docs/Backend_v2.1_UI_Mapping.md`
- `docs/Backend_v2.1_REST_API_Specification.md`

This is a **database architecture document only**. Every table,
relationship, constraint, and index below is justified by a specific,
traceable requirement in one of the three documents above. No table is
added because it is conventional, only because the approved UI or API
already requires it.

> **Amendment note (2026-07-31, Product Vision Amendment, Product Owner Decision).** The Users role description previously enumerated three tenant-level roles (Business Owner/Administrator, Sales & Finance Staff, Collections Staff) — Version 1 has exactly one tenant-level role, the Business Owner, matching `SRS/08_Security_and_RBAC.md` v1.4. No table, column, relationship, or schema structure changed — the role field itself remains a single field on Users, now enumerating one value instead of three.

---

# 1. Introduction

## Purpose

This document defines the database architecture required to store and
serve the data behind every API endpoint in
`Backend_v2.1_REST_API_Specification.md`, which in turn exists to support
`Mobile_UI_V1_Frozen.md`. It is the reference against which Backend
Developers implement the schema, Flutter Developers understand the data
their API calls return, and QA Engineers validate data integrity.

## Scope

This document covers every table implied by the API Inventory in
`Backend_v2.1_REST_API_Specification.md` §13 and the Database Impact
table in `Backend_v2.1_UI_Mapping.md` §12. It does not cover any table,
field, or relationship beyond what those two documents already require —
no administrative, settings, or reference-data module exists anywhere in
the frozen UI, so none is included here.

## Database Principles

- **Every table traces to an approved requirement.** If a table cannot be
  justified by a specific screen, API field, or business rule already
  documented in the three source documents, it does not belong here.
- **Tenant isolation is universal.** Per `Mobile_UI_V1_Frozen.md` §11's
  Tenant Isolation rule, every tenant-owned table carries a tenant
  reference, and no query may return or accept data across tenants.
- **No table exists for a feature the frozen UI does not have.** There is
  no Admin, Settings, or Reference Data module in
  `Mobile_UI_V1_Frozen.md`'s thirteen sections, so none is modeled here.
- **Immutability where the UI requires it.** Where a business rule states
  a record is fixed once created (e.g., generated documents), the schema
  reflects that as a design constraint, not merely an application-layer
  convention.
- **No implementation technology is named anywhere in this document,**
  consistent with its role as architecture, not implementation.

---

# 2. Core Entities

## Tenants

- **Purpose:** The top-level business/account boundary every other entity
  is scoped to, per `Mobile_UI_V1_Frozen.md` §11 Tenant Isolation.
- **Owned By:** Platform-level (implicit prerequisite of every module).
- **Used By:** Every module — Home, Analytics, Cases, Reminder Center,
  Documents.

## Users

- **Purpose:** Represents an individual who authenticates and acts within
  a tenant — the actor behind every "Created By," "Assigned Officer," and
  audit entry across the system. Each user holds the single tenant-level
  role (Business Owner), carried as a single role field on
  the user record — sufficient to satisfy every "any of" permission
  check in `Backend_v2.1_UI_Mapping.md` §10 without a separate roles
  table or join.
- **Owned By:** Authentication (`Backend_v2.1_REST_API_Specification.md`
  §2).
- **Used By:** Cases (assigned officer), Reminder Center (created by),
  Documents (download/share actor), Shared (notification recipient).

## Customers

- **Purpose:** Represents a business's customer — the subject of a debt,
  a case, a reminder, or a document.
- **Owned By:** Cases module (Customer is created via the "Add Case"
  Quick Action's underlying flow, per `Mobile_UI_V1_Frozen.md` §4.4).
- **Used By:** Home, Analytics, Cases, Reminder Center, Documents.

## Debts

- **Purpose:** Represents an amount owed by a customer — the financial
  record every KPI, report, case, and payment is ultimately computed
  from.
- **Owned By:** Cases module.
- **Used By:** Home, Analytics, Cases, Reminder Center (Payment Due
  reminders, Calendar), Documents (Invoices, Demand Letters).

## Payments

- **Purpose:** Records a payment recorded against a debt.
- **Owned By:** Cases module (Record Payment action, §6.5).
- **Used By:** Home (KPIs), Analytics (Collection Analytics, Trends),
  Documents (Receipts).

## Cases

- **Purpose:** Tracks a debt's collection workflow — status, assigned
  officer, and closure outcome.
- **Owned By:** Cases module.
- **Used By:** Home (Recent Cases), Analytics (Reports), Cases (all
  components), Reminder Center (Schedule Reminder from Case Actions),
  Documents (escalation-triggered Demand Letters).

## Promise to Pay

- **Purpose:** Records a customer's committed future payment date.
  Anchored to its Debt as the sole required parent, with an optional
  Case reference retained only for display convenience when a
  collection case already exists for that debt.
- **Owned By:** Cases module.
- **Used By:** Cases (Promise Due filter), Reminder Center (Smart
  Calendar, Promise to Pay reminder type).

## Reminders

- **Purpose:** Represents a scheduled or logged follow-up task, of one of
  the five defined types.
- **Owned By:** Reminder Center module.
- **Used By:** Home (Today's Overview), Reminder Center (all
  components), Documents (Share, via Sent Messages).

## Messages (Message Templates, Sent Messages)

- **Purpose:** Message Templates store reusable, placeholder-based
  message bodies; Sent Messages record every WhatsApp/SMS dispatch.
- **Owned By:** Reminder Center module (shared with Documents §8.8).
- **Used By:** Reminder Center (WhatsApp/SMS Preview), Documents (Share).

## Documents (Invoices, Receipts, Demand Letters, Statements)

- **Purpose:** The four generated, immutable document types the
  Documents module presents, previews, downloads, and shares.
- **Owned By:** Documents module (Invoices and Demand Letters are also
  generated as a side effect of Cases actions).
- **Used By:** Documents (all components), Cases (escalation). *(The
  earlier "Home — Scan Invoice" Quick Action was retired in the
  2026-08-05 V1 Implementation Alignment; see `Mobile_UI_V1_Frozen.md`
  §4.4.)*

## Notifications

- **Purpose:** The per-user, chronological record of dispatched
  notification events referenced by `Mobile_UI_V1_Frozen.md` §2.10 and
  §9.
- **Owned By:** Shared (Reminder Center and Documents both trigger
  entries).
- **Used By:** Any module whose action triggers a notification event
  (`Backend_v2.1_UI_Mapping.md` §9).

## Audit Records (Case Activity/Follow-Up, Audit Log, Document Events)

- **Purpose:** The append-only historical record behind Case Timeline,
  and every Document Download/Share event.
- **Owned By:** Cases module (Case Activity) and Documents module
  (Document Events), with a shared Audit Log used by both.
- **Used By:** Cases (Timeline), Documents (history implied by download/
  share recording).

---

# 3. Table Inventory

No SQL. Primary keys and foreign keys are described conceptually.

| Table Name | Purpose | Primary Key | Foreign Keys | Referenced By |
|---|---|---|---|---|
| Tenants | The business/account boundary | tenant_id | — | Every tenant-owned table below |
| Users | An individual who authenticates and acts, holding the single tenant-level role (role field: Business Owner) | user_id | tenant_id → Tenants | Auth Tokens, Cases, Reminders, Audit Log, Case Activity, Document Events, Notifications |
| Auth Tokens | Issued access/refresh tokens for a session | token_id | user_id → Users | — |
| Customers | A tenant's customer | customer_id | tenant_id → Tenants | Debts, Statements |
| Debts | An amount owed by a customer | debt_id | tenant_id → Tenants; customer_id → Customers | Cases, Payments, Invoices, Demand Letters, Promise to Pay, Reminders (via related_entity) |
| Payments | A recorded payment against a debt | payment_id | tenant_id → Tenants; debt_id → Debts | Receipts |
| Cases | A debt's collection workflow | case_id | tenant_id → Tenants; debt_id → Debts; assigned_officer_user_id → Users (nullable) | Case Activity, Promise to Pay (optional), Reminders (related_case_id) |
| Promise to Pay | A customer's committed payment date | promise_id | tenant_id → Tenants; debt_id → Debts (required, primary parent); case_id → Cases (nullable, secondary reference) | Reminders (related_entity), Calendar aggregation (read-only) |
| Case Activity | Chronological record of case actions | activity_id | tenant_id → Tenants; case_id → Cases; actor_user_id → Users | Case Timeline (read-only) |
| Audit Log | Administrative and cross-module audit trail | audit_id | tenant_id → Tenants; user_id → Users; entity_type + entity_id (polymorphic, not a strict foreign key) | Case Timeline (read-only) |
| Reminders | A scheduled or logged follow-up task | reminder_id | tenant_id → Tenants; created_by_user_id → Users; related_entity_type + related_entity_id (polymorphic); related_case_id → Cases (nullable) | Sent Messages, Calendar aggregation (read-only) |
| Message Templates | Reusable, placeholder-based message bodies | template_id | tenant_id → Tenants | Sent Messages |
| Sent Messages | Every dispatched WhatsApp/SMS message | sent_message_id | tenant_id → Tenants; template_id → Message Templates; reminder_id → Reminders (nullable); case_id → Cases (nullable); document_type + document_id (polymorphic, nullable) | Notifications (as a triggering source) |
| Invoices | The amount billed to a customer | invoice_id | tenant_id → Tenants; debt_id → Debts | Document Events, Sent Messages (via Share) |
| Receipts | Proof of a recorded payment | receipt_id | tenant_id → Tenants; payment_id → Payments | Document Events, Sent Messages (via Share) |
| Demand Letters | Formal collection correspondence | demand_letter_id | tenant_id → Tenants; debt_id → Debts | Document Events, Sent Messages (via Share) |
| Statements | Full-account customer history document | statement_id | tenant_id → Tenants; customer_id → Customers | Document Events, Sent Messages (via Share) |
| Document Events | Records a document download or share | event_id | tenant_id → Tenants; document_type + document_id (polymorphic); user_id → Users | — |
| Notifications | Per-user notification feed entry | notification_id | tenant_id → Tenants; recipient_user_id → Users; related_entity_type + related_entity_id (polymorphic) | — |

---

# 4. Relationships

## One-to-Many

- **Tenant → Users** — a tenant has many users; a user belongs to exactly
  one tenant.
- **Tenant → Customers** — a tenant has many customers.
- **Customer → Debts** — a customer has many debts; a debt belongs to
  exactly one customer. Corresponds to every screen that lists a
  customer's debts (`Mobile_UI_V1_Frozen.md` §6.3 debt summary, §8.2
  Invoices).
- **Debt → Payments** — a debt has many payments; a payment belongs to
  exactly one debt (§6.5 Record Payment).
- **Debt → Invoices** — a debt has many invoices over its lifetime (§8.2).
- **Debt → Demand Letters** — a debt has many demand letters, one per
  escalation (§8.4, §6.5 Escalate).
- **Customer → Statements** — a customer has many statements, each
  generated independently (§8.5).
- **Case → Case Activity** — a case has many recorded activity entries; an
  activity entry belongs to exactly one case (§6.4 Timeline).
- **User → Reminders (Created By)** — a user creates many reminders; a
  reminder has exactly one creator (§7.4, §7.9 — immutable after
  creation).
- **User → Case Activity / Audit Log (Actor)** — a user performs many
  audited actions; each entry has exactly one actor.
- **Reminder → Sent Messages** — a reminder may result in many sent
  messages over its lifetime (each send recorded independently, §7.7,
  §7.8); a sent message optionally references the one reminder that
  triggered it.
- **Message Template → Sent Messages** — a template is reused across many
  sent messages; a sent message references exactly one template (§7.7,
  §7.8).
- **Payment → Receipt** — see One-to-One below; included here for
  completeness of the payment lifecycle.

## One-to-One

- **Payment → Receipt** — every payment produces exactly one receipt,
  automatically, per `Mobile_UI_V1_Frozen.md` §8.3's business rule
  ("generated automatically whenever a payment is recorded"); a receipt
  belongs to exactly one payment.
- **Debt → Case** — a debt has at most one active collection case at a
  time (a case is the debt's collection workflow, not an independent,
  repeatable entity); a case belongs to exactly one debt.

## Many-to-One (from the "many" side's perspective, restated for clarity)

- **Case → Debt** — every case belongs to exactly one debt (inverse of
  Debt → Case above).
- **Reminders → related entity** — a reminder's `related_entity`
  reference points to exactly one Customer, Debt, or Case, depending on
  its type (§7.2); this is a polymorphic many-to-one, not a many-to-many,
  since each reminder relates to exactly one entity at a time.
- **Case → Officer (User)** — **Retired (Product Vision Amendment, 2026-07-31).** The Assign Officer action itself is retired (see `Backend_v2.1_REST_API_Specification.md`) — Version 1 has no second tenant user to assign a Case to. The `assigned_officer_user_id` column remains in the schema (approved decision) but is no longer written to by any active endpoint; this relationship is not actively maintained going forward.

## Many-to-Many

No many-to-many relationship is required anywhere in the frozen UI or
API. Every relationship documented across `Mobile_UI_V1_Frozen.md`,
`Backend_v2.1_UI_Mapping.md`, and `Backend_v2.1_REST_API_Specification.md`
is expressible as one-to-one or one-to-many. In particular:

- Reminders relate to exactly one entity at a time (polymorphic
  one-to-many, not many-to-many).
- A Case has at most one assigned officer at a time, not a team.
- A Sent Message references at most one of Reminder, Case, or Document as
  its source — never more than one simultaneously — so no join table is
  required.

---

# 5. Data Ownership

| Table | Owning Module | Readable By | Updatable By |
|---|---|---|---|
| Tenants | Platform-level | All modules | Platform-level only |
| Users | Authentication | All modules (for actor/assignee display) | Authentication |
| Auth Tokens | Authentication | Authentication only | Authentication |
| Customers | Cases | Home, Analytics, Cases, Reminder Center, Documents | Cases |
| Debts | Cases | Home, Analytics, Cases, Reminder Center, Documents | Cases (status, recovery via Payments) |
| Payments | Cases | Home, Analytics, Documents (Receipts) | Cases |
| Cases | Cases | Home, Analytics, Reminder Center (Schedule Reminder) | Cases |
| Promise to Pay | Cases | Cases, Reminder Center | Cases |
| Case Activity | Cases | Cases | Cases (append-only) |
| Audit Log | Shared (Audit Trail Service) | Cases (Timeline) | Every module (append-only writes) |
| Reminders | Reminder Center | Home, Cases (Schedule Reminder), Documents (Share source) | Reminder Center |
| Message Templates | Reminder Center | Reminder Center, Documents | Reminder Center |
| Sent Messages | Reminder Center | Reminder Center, Documents | Reminder Center, Documents (append-only writes) |
| Invoices | Documents | Home (Documents preview), Documents | Documents (generated by Cases' Debt creation) |
| Receipts | Documents | Documents | Documents (generated by Cases' Record Payment) |
| Demand Letters | Documents | Documents | Documents (generated by Cases' Escalate) |
| Statements | Documents | Documents | Documents |
| Document Events | Documents | Documents | Documents (append-only writes) |
| Notifications | Shared | The recipient user only | Every module that triggers an event (append-only writes) |

No table is writable by a module other than its owner except through the
specific, already-documented cross-module actions above (e.g., Cases
writing a Receipt indirectly by recording a Payment) — no module
directly edits another module's table outside those flows.

---

# 6. Index Strategy

Only indexes required to serve an already-specified UI or API requirement
are documented. No SQL or engine-specific index type is named.

## Dashboard KPIs

- **Debts, scoped by tenant and status:** required so Total Outstanding
  and Overdue Amount (`Mobile_UI_V1_Frozen.md` §4.2) can sum remaining
  balances across open debts without scanning every debt a tenant has
  ever had.
- **Payments, scoped by tenant and payment date:** required so Collected
  This Month (§4.2) and the period-scoped Collection Analytics (§5.4) can
  sum payments within a date range efficiently.
- **Customers, scoped by tenant and risk level:** required so the High
  Risk Customers KPI (§4.2) and Risk Distribution (§5.6) can count by
  classification without scanning the full customer base.

## Reminder Engine and Calendar

- **Reminders, scoped by tenant, due date, and status:** required for
  every status-tab filter (§7.3: Today/Upcoming/Overdue/Completed), the
  Reminder Summary counts (§7.1), and the Smart Calendar's date-range
  aggregation (§7.6) — all of which filter or group by exactly these
  three fields.
- **Reminders, scoped by tenant and type:** required for the per-type
  sub-counts in Today's Overview (§4.3) and the Reminder Summary (§7.1).

## Case Filters

- **Cases, scoped by tenant and case status:** required for the Case
  List's status filtering (§6.1) and the total-count computation per
  active tab.
- **Promise to Pay, scoped by debt/case and status:** required for the
  Promise Due filter (§6.2), which must identify open, unfulfilled
  promises without scanning every promise ever recorded.

## Search

- **Reminders, on title and related-entity name:** required to serve the
  `search` parameter on List Reminders (`Backend_v2.1_REST_API_Specification.md`
  §6, per §7.1's search icon).
- **Documents (each of the four types), on filename:** required to serve
  the `search` parameter on List Documents (§8.1's search icon).

## Documents

- **Each document table, scoped by tenant and generated date:** required
  for the "Recent Documents" ordering and type-tab listing in §8.1, and
  for the per-type lists in §8.2–8.5.
- **Document Events, scoped by document reference:** required so a
  document's download/share history (§8.7, §8.8's audit requirement) can
  be retrieved without scanning the entire audit surface.

---

# 7. Constraints

No SQL. Constraints are described at the business-rule level.

## Required Fields

- Every tenant-owned table requires a tenant reference — no row may exist
  without one, per the universal Tenant Isolation rule.
- Debts require a customer reference; Payments require a debt reference;
  Cases require a debt reference — none of these relationships is
  optional, since none of the corresponding screens can render a debt,
  payment, or case without its parent.
- Reminders require a type (one of the five defined types, §7.2), a due
  date, a timing rule, and at least one delivery method — all four are
  mandatory per §7.5's validation rules.
- Case Closure requires a closure outcome — enforced as a required field
  at the point of closing, not merely a UI-level prompt (§6.5).
- Reminder Amount Due is required only for Payment Due and Promise to Pay
  types, and must be absent for the other three — a conditional
  requirement, not a universally required field (§7.4).
- Each of the four document tables (Invoices, Receipts, Demand Letters,
  Statements) requires a `file_size` value, captured once at generation
  time and never recalculated — the only capture point consistent with
  every document being "immutable once generated" (§8.2–8.5).

## Unique Fields

- No two documents of any single type (Invoice, Receipt, Demand Letter,
  Statement) may share the same reference/document number within a
  tenant — each generated document's reference number is unique per
  tenant, consistent with every document being individually identifiable
  in the Documents list and Preview screen (§8.1, §8.6).
- A user's email/login identifier is unique across the system (a
  prerequisite for Login, §2 of the API specification, to unambiguously
  resolve one account).

## Referential Integrity

- A Payment cannot exist without its parent Debt; a Receipt cannot exist
  without its parent Payment — both are structurally dependent, matching
  the frozen UI's own dependency chain (a receipt is generated *because*
  a payment was recorded, §8.3).
- A Case cannot exist without its parent Debt.
- A Reminder's `related_case_id`, when present, must reference an
  existing Case; its polymorphic `related_entity` must reference an
  existing Customer, Debt, or Case consistent with its type.
- A Sent Message's template reference must point to an existing Message
  Template — a message cannot be recorded as sent from a template that
  was never defined.

## Cascade Rules

- Deleting a Reminder (§7.4's explicit Delete action) removes it from
  every view but does not cascade-delete its historical Sent Messages —
  a message that was already sent remains a real, recorded event
  regardless of whether the reminder that triggered it is later deleted.
- No other cascade-delete rule is required, because no other table in
  this inventory supports deletion at all (Section 9 below) — Cases,
  Debts, Customers, and every generated Document are permanently
  retained, so no cascade behavior needs to be defined for them.

---

# 8. Audit Requirements

## Case Activity / Audit Log

- **Why:** `Mobile_UI_V1_Frozen.md` §6.4 requires the Timeline to show
  "the full chronological activity history of a case," explicitly stating
  entries are "never retroactively altered."
- **What is audited:** every case-affecting action — payment recorded,
  officer assigned, escalation, closure — with the acting user and
  timestamp, assembled in reverse-chronological order for §6.4's display.

## Document Events

- **Why:** `Mobile_UI_V1_Frozen.md` §8.7 and §8.8 both state, as a
  business rule, that "every download of a document is recorded" and
  "every share of a document is recorded... for audit purposes."
- **What is audited:** the document, the action (download or share), the
  acting user, the recipient (for shares), and the timestamp.

## Sent Messages

- **Why:** `Mobile_UI_V1_Frozen.md` §7.7/§7.8 state "every send is
  recorded against the originating reminder or case for audit purposes,"
  and `Backend_v2.1_REST_API_Specification.md` §11 lists every WhatsApp/
  SMS dispatch as an audit-logged action.
- **What is audited:** the channel, the template used, the rendered
  recipient, the delivery status, and the timestamp.

## Reminders (Created By / Created On)

- **Why:** §7.4 explicitly states "Created By and Created On are fixed
  at creation and never change" — this is an audit-style immutability
  requirement on the reminder record itself, distinct from a separate
  audit log entry.
- **What is audited:** the original creator and creation timestamp,
  preserved even through a Reschedule (§7.9).

No other table carries an explicit audit requirement in the frozen UI or
API specification — Customers, Debts, and Payments are covered by Case
Activity when their changes occur through a Case action, and generated
Documents are covered by immutability itself (Section 9) rather than a
separate audit trail.

---

# 9. Soft Delete Policy

| Table | Delete Behavior | Business Reason |
|---|---|---|
| Reminders | Soft delete | §7.4 requires a deleted reminder to be "excluded from any subsequent view," which soft deletion satisfies, while preserving the record for the Sent Messages history it may have already produced (Section 7's cascade rule). |
| Cases | No delete — status transition only | The frozen UI never presents a "delete case" action; a case moves to Closed (§6.5) and is permanently retained, since its Timeline (§6.4) must remain available indefinitely. |
| Customers, Debts | No delete or archive specified | Neither `Mobile_UI_V1_Frozen.md` nor either backend document defines an archive or delete action for a customer or a debt; both are permanently retained. |
| Payments | No delete | A recorded payment is the basis for a Receipt and every downstream KPI; the frozen UI defines no correction/reversal action, so no delete behavior is specified. |
| Invoices, Receipts, Demand Letters, Statements | No delete — immutable | §8.2–8.5 each state the document "is immutable once generated"; permanent retention is the direct consequence of that rule. |
| Message Templates | No delete specified | Neither document defines a template-management action beyond retrieval (§7.7, §7.8); templates are permanently retained. |
| Sent Messages, Case Activity, Audit Log, Document Events | No delete — append-only | Each is an audit trail; §6.4 explicitly states entries are "never retroactively altered," which precludes deletion as well as modification. |
| Notifications | No delete specified | `Backend_v2.1_UI_Mapping.md` §9 defines only a list capability, with no delete or archive action specified. |

No table in this inventory requires permanent (hard) delete as a
user-facing capability. The only delete behavior anywhere in the frozen
UI is Reminder deletion, and it is satisfied by soft deletion.

---

# 10. Data Lifecycle

The data flow below reflects the actual dependency order established
across the three source documents — a customer must exist before a debt,
a debt before a case or payment, and so on:

```
Customer
  ↓
Debt (belongs to Customer)
  ↓
  ├── Invoice (generated when the Debt is established, §8.2)
  ├── Case (created when the Debt is tracked as a collection case, §6)
  │     ↓
  │     ├── Case Activity entry (recorded per action, §6.4)
  │     ├── Promise to Pay (recorded via Cases, §6.2)
  │     ├── Demand Letter (generated on Escalate, §6.5 / §8.4)
  │     └── Reminder (Schedule Reminder from Case Actions, §6.5 / §7.5)
  ├── Payment (recorded against the Debt, §6.5)
  │     ↓
  │     └── Receipt (generated automatically, §8.3)
  └── Reminder (Payment Due type, related to the Debt directly, §7.2)

Customer
  ↓
  └── Statement (generated on demand, independent of any single Debt, §8.5)

Reminder (of any origin above)
  ↓
  └── Sent Message (recorded on Send, §7.7 / §7.8)

Document (Invoice, Receipt, Demand Letter, or Statement)
  ↓
  ├── Document Event (recorded on Download or Share, §8.7 / §8.8)
  └── Sent Message (recorded when Shared, §8.8)
```

Every arrow above corresponds to a business rule or action already
documented in `Mobile_UI_V1_Frozen.md`; no arrow represents an invented
flow.

---

# 11. Performance Considerations

No implementation technology is named below — only the data-design
decisions the approved UI and API depend on.

## Dashboard

Home Dashboard KPIs (§4.2) require summing remaining balances and
payment amounts across a tenant's full open-debt and current-month-
payment sets on every load. Storing `remaining_balance` directly on the
Debt record (updated as payments are recorded), rather than recomputing
it from the full payment history on every request, keeps this a
single-pass aggregation instead of a join-and-recompute operation.

## Analytics

Collections Trend (§5.3) and Collection Analytics (§5.4) both aggregate
Payments over arbitrary date ranges. Storing `payment_date` as a first-
class, directly filterable field (rather than deriving it from a related
record) allows range-scoped aggregation without traversing unrelated
tables.

## Reminder Engine

The Smart Reminder Engine (`Backend_v2.1_UI_Mapping.md` Section 5) must
repeatedly answer "which reminders are due, by status and type, for this
tenant" — for the Dashboard summary (§7.1), the List (§7.3), and Today's
Overview (§4.3). Storing `status`, `type`, and `due_date` as direct,
queryable fields on the Reminder record — rather than deriving status
from a computation across other tables — keeps every one of these
read-heavy screens a direct filter rather than a computed join.

## Calendar

The Smart Calendar (§7.6) aggregates three different source tables
(Reminders, Debts, Promise to Pay) into one date-ordered view. Each
source table exposes its relevant date directly (`due_date` on Reminders
and Debts, `promised_date` on Promise to Pay) so the aggregation is a
union of three already-indexed date-range queries, not a set of derived
calculations.

## Documents

The Documents module (§8) lists four structurally similar but distinct
document types under one combined view (§8.1). Keeping each document
type in its own table (rather than one shared table with a type
discriminator) matches the frozen UI's own treatment of each type as
having independent business rules (§8.2–8.5), while the combined "All
Documents" list is served by aggregating across the four at query time —
a design that keeps each type's immutability and generation rules
independent while still supporting the unified list view.

---

# 12. Traceability Matrix

| UI Screen | API | Database Tables |
|---|---|---|
| Home Dashboard — Business Health (§4.1) | GET /dashboard/business-health | Customers, Debts, Payments |
| Home Dashboard — KPI Cards (§4.2) | GET /dashboard/kpis | Debts, Payments, Customers |
| Home Dashboard — Today's Overview (§4.3) | GET /dashboard/todays-overview | Reminders |
| Home Dashboard — Recent Cases (§4.5) | GET /dashboard/recent-cases | Cases, Customers, Debts |
| Analytics — Overview (§5.1) | GET /analytics/overview | Debts, Payments, Customers |
| Analytics — Reports (§5.2) | GET /analytics/reports/* | Debts, Customers, Cases, Payments |
| Analytics — Trends (§5.3) | GET /analytics/trends | Payments, Debts |
| Analytics — Collection Analytics (§5.4) | GET /analytics/collection-kpis | Payments, Debts |
| Analytics — Aging Analysis (§5.5) | GET /analytics/aging-analysis | Debts |
| Analytics — Risk Distribution (§5.6) | GET /analytics/risk-distribution | Customers |
| Cases — Case List / Filters (§6.1, §6.2) | GET /cases | Cases, Customers, Debts, Promise to Pay |
| Cases — Case Details (§6.3) | GET /cases/{id} | Cases, Customers, Debts |
| Cases — Timeline (§6.4) | GET /cases/{id}/timeline | Case Activity, Audit Log |
| Cases — Actions (§6.5) | POST /cases/{id}/payments, POST .../escalate, POST .../close (~~PATCH .../assign-officer~~ Retired) | Cases, Debts, Payments, Demand Letters (via escalation) |
| Reminder Center — Dashboard (§7.1) | GET /reminders/summary | Reminders |
| Reminder Center — Reminder List (§7.3) | GET /reminders | Reminders |
| Reminder Center — Reminder Details (§7.4) | GET/PUT/DELETE /reminders/{id}, PATCH .../complete | Reminders |
| Reminder Center — Reminder Scheduling (§7.5) | POST /reminders, PUT /reminders/{id} | Reminders |
| Reminder Center — Smart Calendar (§7.6) | GET /calendar | Reminders, Debts, Promise to Pay |
| Reminder Center — WhatsApp/SMS Preview (§7.7, §7.8) | GET /message-templates, POST /messages/render, POST /messages/send/whatsapp, POST /messages/send/sms | Message Templates, Sent Messages, Reminders, Cases |
| Documents — Document List / Storage Usage (§8.1) | GET /documents, GET /documents/storage-usage | Invoices, Receipts, Demand Letters, Statements |
| Documents — Invoices/Receipts/Letters/Statements (§8.2–8.5) | GET /documents/invoices, /receipts, /demand-letters, /statements | Invoices, Receipts, Demand Letters, Statements |
| Documents — Preview / Download (§8.6, §8.7) | GET /documents/{id}, GET /documents/{id}/download | Invoices, Receipts, Demand Letters, Statements, Document Events |
| Documents — Share (§8.8) | POST /documents/{id}/share | Document Events, Sent Messages, Message Templates |
| Shared — Notifications | GET /notifications | Notifications |
| Shared — Invoice Scan Capture | POST /documents/invoices/scan | Invoices |

---

# 13. Database Readiness Assessment

**The database architecture is ready for implementation.** The three
points previously identified as requiring a decision have each been
resolved using the architecture already established in this document —
none required a new table, a new relationship, or any change to the
approved UI or API:

1. **Promise to Pay's parent reference — resolved.** Promise to Pay is
   anchored to Debt as its sole required parent (`debt_id`, required),
   with the existing, already-nullable Case reference (`case_id`)
   retained only as a secondary, display-convenience field. This uses
   exactly the foreign-key shape already recorded for Promise to Pay in
   Section 3's Table Inventory — no new relationship was introduced.
2. **File size capture timing — resolved.** Each of the four document
   tables captures `file_size` once, at generation time, and never
   recalculates it — the only capture point consistent with every
   document being "immutable once generated" (§8.2–8.5). This is now
   recorded as a Required Field in Section 7.
3. **Role representation on Users — resolved.** Each user holds the
   single tenant-level role (Business Owner), carried as a single role
   field on the existing Users table. This fully satisfies every "any
   of" permission check in `Backend_v2.1_UI_Mapping.md` §10 without
   introducing a separate roles table or a user-role join.

No table, relationship, or constraint is missing that the approved UI or
API actually requires. All nineteen tables in Section 3 are directly
traceable to a specific screen or endpoint, every relationship in Section
4 is already implied by an existing business rule, and no gap identified
above requires inventing a feature — each is a resolution of an existing,
already-specified requirement.
