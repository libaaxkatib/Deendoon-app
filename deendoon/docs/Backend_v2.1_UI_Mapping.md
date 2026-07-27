# Backend v2.1 — UI Mapping

**Source of truth:** `docs/Mobile_UI_V1_Frozen.md` (UI Version 1.0 — APPROVED, FROZEN, 2026-07-27)

This document maps every screen, component, and business rule in the
frozen UI specification to the backend architecture required to support
it. Every requirement below traces to a specific, cited section of
`Mobile_UI_V1_Frozen.md`. No screen, feature, workflow, or business rule
is added, removed, redesigned, or reinterpreted here — this document
answers only "what must the backend provide," never "what should the UI
do."

---

# 1. Introduction

## Purpose

This document translates the approved, frozen UI specification into a
complete backend implementation plan — the APIs, database tables,
business logic, services, background jobs, notifications, and
permissions required for the backend to fully support UI Version 1.0. It
is intended for Backend Development, QA, and future API implementation
work.

## Scope

This document covers every section of `Mobile_UI_V1_Frozen.md`: Bottom
Navigation (§3), Home Dashboard (§4), Analytics (§5), Cases (§6),
Reminder Center (§7), and Documents (§8), together with the cross-cutting
Reusable Components (§9), UX Rules (§10), and Business Rules (§11) those
sections depend on. Every backend requirement in this document is
derived directly from one of those sections; where the frozen UI is
silent on a detail, this document says so explicitly rather than
inventing one.

## Mapping Principles

- **The frozen UI is authoritative.** The backend adapts to it; it is
  never adapted to the backend.
- **No new requirements.** Every API, table, service, job, notification,
  and permission listed here exists to fulfill a specific, cited
  requirement already present in `Mobile_UI_V1_Frozen.md` — never a
  hypothetical future need.
- **Traceability.** Every mapping entry references the section number of
  the frozen UI it fulfills, so any requirement here can be checked
  against its source.
- **Shared capabilities documented once.** A backend service, job, or
  API used by more than one screen is fully specified once, in Section 7
  (Shared Services), 8 (Background Jobs), 9 (Notifications), or 11 (API
  Inventory), and referenced by name from each screen's own mapping
  rather than repeated in full.
- **No implementation is prescribed.** This document defines what the
  backend must provide, not how it is coded — no framework, language, or
  schema syntax is used anywhere below.

---

# 2. Home Dashboard Mapping

*Maps to `Mobile_UI_V1_Frozen.md` §4 and its components §4.1–4.5.*

## 4.1 Business Health

- **Required APIs:** Business Health Score retrieval (returns the
  current score and its status band).
- **Required Database Tables:** Customer records, Debt records, Payment
  records.
- **Required Business Logic:** Composite score calculation combining
  collection performance, outstanding exposure, and risk concentration
  into a 0–100 percentage; mapping of that percentage to one of three
  status bands (Healthy, Needs Attention, At Risk); continuous
  recalculation on every request — no cached/stale value is permitted,
  per §4.1's explicit "recalculated continuously" rule.
- **Required Services:** Business Health Scoring Service.
- **Required Background Jobs:** None. §4.1 mandates continuous, on-demand
  recalculation, not a periodic snapshot.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 4.2 KPI Cards

- **Required APIs:** Dashboard KPI Summary retrieval (Total Outstanding,
  Collected This Month, Overdue Amount, High Risk Customers, each with
  its prior-month comparison value).
- **Required Database Tables:** Debt records, Payment records, Customer
  records.
- **Required Business Logic:** Open-debt remaining-balance aggregation
  (excluding Paid/Cancelled/Written-Off); current-calendar-month payment
  aggregation; overdue-debt aggregation; High Risk customer count;
  equivalent prior-month values for each figure's delta.
- **Required Services:** Dashboard KPI Aggregation Service (shared
  aggregation logic with Aging Analysis Service and Risk Classification
  Service — Section 7).
- **Required Background Jobs:** None. Prior-period comparisons can be
  computed on demand from existing records.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 4.3 Today's Overview

- **Required APIs:** Today's Reminder Summary retrieval (Reminders Due
  Today, Payments Due, Client Visits, Follow-up Calls counts).
- **Required Database Tables:** Reminder records.
- **Required Business Logic:** Count reminders due on the current
  calendar day whose status is not Completed, broken down by Reminder
  Type.
- **Required Services:** Reminder Summary Service (shared with §7.1
  Dashboard — Section 7).
- **Required Background Jobs:** None directly; relies on the Smart
  Reminder Engine (Section 5) for accurate status.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 4.4 Quick Actions

- **Required APIs:** Case Creation; Payment Recording; Invoice Capture;
  Message Composition — each opening its own workflow, detailed under
  the module that owns it (Cases §6, Documents §8, Reminder Center §7).
- **Required Database Tables:** Case records, Payment records, Invoice
  records, Reminder/Message records.
- **Required Business Logic:** Each action is unconditionally available
  to a permitted user regardless of current data state, per §4.4's
  business rule.
- **Required Services:** Case Service, Payment Service, Invoice Capture
  Service, Message Composition Service (each owned by its destination
  module, shared via Section 7).
- **Required Background Jobs:** None directly.
- **Required Notifications:** None directly (downstream workflows may
  trigger their own — Section 9).
- **Required Permissions:** Independently gated per tile, matching the
  permission required by the destination workflow.

## 4.5 Recent Cases

- **Required APIs:** Recent Cases retrieval (most-recently-active cases,
  preview count).
- **Required Database Tables:** Case records, Customer records, Debt
  records.
- **Required Business Logic:** Ordering by most recent recorded activity,
  descending; limited to a small preview count, with the full list
  available via Cases §6.1.
- **Required Services:** Case List Service (shared with §6.1 — Section
  7).
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

---

# 3. Analytics Mapping

*Maps to `Mobile_UI_V1_Frozen.md` §5 and its components §5.1–5.6.*

## 5.1 Overview

- **Required APIs:** Analytics Overview retrieval (accepts a date range;
  returns the composed Collection Analytics and Aging Analysis figures).
- **Required Database Tables:** Debt records, Payment records, Customer
  records.
- **Required Business Logic:** Immediate recomputation of all Overview
  figures on date-range change; date-range validation (non-inverted
  start/end).
- **Required Services:** Analytics Aggregation Service.
- **Required Background Jobs:** None. §5.1 requires figures to recompute
  "immediately whenever the date range changes" — a live, on-demand
  requirement, not a cached one.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 5.2 Reports

- **Required APIs:** Customers Report; Debts Report; Collection Cases
  Report; Payments Report; Credit Risk Report; Aging Analysis Report
  (each filterable); Report Export.
- **Required Database Tables:** Debt records, Customer records,
  Collection Case records, Payment records.
- **Required Business Logic:** Filter-criteria internal-consistency
  validation (e.g., a minimum must not exceed its maximum); every report
  reflects live data at the moment it is viewed.
- **Required Services:** Reporting Service; Report Export Service.
- **Required Background Jobs:** None. §5.2 specifies live data on
  viewing, not a precomputed report.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 5.3 Trends

- **Required APIs:** Collections Trend time-series retrieval (accepts an
  extended date range; returns one data point per interval).
- **Required Database Tables:** Payment records, Debt records.
- **Required Business Logic:** Per-interval (e.g., daily) aggregation of
  the displayed metric across the selected range.
- **Required Services:** Trend Aggregation Service.
- **Required Background Jobs:** None required for correctness.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 5.4 Collection Analytics

- **Required APIs:** Collection Analytics KPI retrieval.
- **Required Database Tables:** Payment records, Debt records.
- **Required Business Logic:** Collection Rate = total collected in
  period ÷ total amount due in period; Total Collected = sum of period
  payments; Average Days = mean days between a debt's due date and its
  full-payment date, across debts paid within the period.
- **Required Services:** Collection Analytics Service.
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 5.5 Aging Analysis

- **Required APIs:** Aging Analysis retrieval.
- **Required Database Tables:** Debt records.
- **Required Business Logic:** Bracket assignment (Current, 1–30, 31–60,
  61–90, 90+ days) by days-past-due, computed against remaining balance,
  over open debts only.
- **Required Services:** Aging Analysis Service (shared with Reports
  §5.2 and Home §4.2 — Section 7).
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 5.6 Risk Distribution

- **Required APIs:** Risk Distribution retrieval.
- **Required Database Tables:** Customer records.
- **Required Business Logic:** Count and percentage share of active
  customers per risk classification (High, Medium, Low).
- **Required Services:** Risk Classification Service (shared with Cases
  §6.2 and Home §4.2 — Section 7).
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

---

# 4. Cases Mapping

*Maps to `Mobile_UI_V1_Frozen.md` §6 and its components §6.1–6.5.*

## 6.1 Case List

- **Required APIs:** Case List retrieval (paginated, filterable by status
  tab).
- **Required Database Tables:** Case records, Customer records, Debt
  records.
- **Required Business Logic:** Total-count computation for the active
  tab; "Last activity" derived from the most recent recorded activity
  against the case.
- **Required Services:** Case List Service.
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff, Collections Staff.

## 6.2 Filters

- **Required APIs:** Case List retrieval, extended to accept filter
  criteria (status tab plus additional filter-panel criteria).
- **Required Database Tables:** Case records, Customer records, Promise
  to Pay records.
- **Required Business Logic:** High Risk = customer risk level High;
  Follow Up = case has a recorded follow-up activity not yet resulting
  in payment, closure, or an open Promise to Pay; Promise Due = case has
  an open, unfulfilled Promise to Pay; additional filter-criteria
  internal-consistency validation.
- **Required Services:** Case Filtering Service; Risk Classification
  Service (Section 7).
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Same as §6.1.

## 6.3 Case Details

- **Required APIs:** Case Details retrieval.
- **Required Database Tables:** Case records, Customer records, Debt
  records.
- **Required Business Logic:** Live assembly of the case summary panel
  (outstanding amount, risk level, status, assigned officer) at the
  moment of viewing.
- **Required Services:** Case Detail Service.
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Same as §6.1.

## 6.4 Timeline

- **Required APIs:** Case Timeline retrieval.
- **Required Database Tables:** Case Activity/Follow-Up records, Audit
  records.
- **Required Business Logic:** Reverse-chronological assembly of every
  recorded action against the case; timeline entries are never
  retroactively altered.
- **Required Services:** Case Timeline Service; Audit Trail Service
  (Section 7).
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Same as §6.1.

## 6.5 Actions

- **Required APIs:** Payment Recording; Officer Assignment; Escalation;
  Case Closure; "Schedule Reminder" delegates to Reminder Creation
  (Section 5).
- **Required Database Tables:** Case records, Debt records, Payment
  records.
- **Required Business Logic:** Only actions valid for the case's current
  status are permitted (e.g., a closed case cannot be closed again);
  closure requires a recorded closure outcome.
- **Required Services:** Case Action Service (payment recording, officer
  assignment, escalation, closure); delegates to the Reminder Service for
  scheduling.
- **Required Background Jobs:** None.
- **Required Notifications:** None — the frozen UI does not specify a
  notification for Officer Assignment or Escalation; only the recorded
  action itself is required (§6.5).
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff, assigned Collections Staff; each action independently gated.

---

# 5. Reminder Center Mapping

*Maps to `Mobile_UI_V1_Frozen.md` §7 and its components §7.1–7.9. Includes
the Smart Reminder Engine as the cross-cutting backend subsystem required
to fulfill §7.1, §7.3, §7.5, and §7.9 — it is not a UI screen, only the
backend mechanism behind requirements the frozen UI already specifies.*

## 7.1 Dashboard

- **Required APIs:** Reminder Summary retrieval (total due-today count,
  per-type sub-counts, Overdue count); Reminder Search (behind the
  header's search icon).
- **Required Database Tables:** Reminder records.
- **Required Business Logic:** Counts reminders due today (status not
  Completed) by type; separately counts Overdue reminders.
- **Required Services:** Reminder Summary Service (shared with Home
  §4.3); Search Service (Section 7).
- **Required Background Jobs:** Depends on the Smart Reminder Engine
  (below) for correct Overdue status.
- **Required Notifications:** None directly.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff, Collections Staff.

## 7.2 Reminder Types

- **Required APIs:** None — a fixed classification, not a retrieved
  resource, per §7.2.
- **Required Database Tables:** Reminder Type is a field on Reminder
  records (fixed enumeration: Client Visit, Follow-up Call, Payment Due,
  Contract Renewal, Promise to Pay).
- **Required Business Logic:** Every reminder carries exactly one of the
  five defined types; type determines whether Amount Due applies
  (§7.4).
- **Required Services:** Enforced by the Reminder Service's validation
  layer; no dedicated service.
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Not applicable, per §7.2.

## Smart Reminder Engine

- **Purpose:** The backend subsystem responsible for evaluating a
  reminder's due date against the current time, deriving its Today /
  Upcoming / Overdue status, and evaluating the timing rule configured
  in Reminder Scheduling (§7.5) to determine when a scheduled delivery
  must fire.
- **Required APIs:** None exposed directly — consumed internally by the
  APIs listed under §7.1, §7.3, §7.4, and §7.5.
- **Required Database Tables:** Reminder records.
- **Required Business Logic:** Status derivation from due date and
  current date (Today/Upcoming/Overdue); enforcement that Completed is
  reached only via explicit user action (§7.3); timing-rule evaluation
  (1 day before / same day / 1 hour before / custom date-time) to
  determine delivery firing time (§7.5).
- **Required Services:** Reminder Service (core); Smart Reminder Engine
  (status/timing evaluation).
- **Required Background Jobs:** Reminder Scheduler (Section 8) — the one
  background process this engine requires, since "N before due date"
  firing cannot occur purely on request.
- **Required Notifications:** Triggers delivery via whichever channel(s)
  were selected in §7.5, once a timing rule fires (Section 9).
- **Required Permissions:** Internal subsystem; governed by the
  permissions of the APIs that invoke it.

## 7.3 Reminder List

- **Required APIs:** Reminder List retrieval (filterable by status tab);
  Reminder Completion; Reminder Send (for the inline action).
- **Required Database Tables:** Reminder records.
- **Required Business Logic:** Status-based filtering (All, Today,
  Upcoming, Overdue, Completed); inline-action availability rules (e.g.,
  Complete unavailable on an already-completed reminder).
- **Required Services:** Reminder Service; Smart Reminder Engine.
- **Required Background Jobs:** Reminder Scheduler (indirectly, via the
  Smart Reminder Engine).
- **Required Notifications:** None directly (Send triggers Section 9's
  delivery flow).
- **Required Permissions:** Same as §7.1.

## 7.4 Reminder Details

- **Required APIs:** Reminder Detail retrieval; Reminder Update; Reminder
  Deletion; Reminder Completion; Reminder Send.
- **Required Database Tables:** Reminder records.
- **Required Business Logic:** Amount Due shown only for Payment Due and
  Promise to Pay types; Created By and Created On are immutable after
  creation; deletion is distinct from completion — a deleted reminder is
  excluded from every view, a completed one remains visible under
  Completed.
- **Required Services:** Reminder Service.
- **Required Background Jobs:** None directly.
- **Required Notifications:** None directly.
- **Required Permissions:** Viewing — same as §7.1; editing and deletion
  — the reminder's creator or a manager-level role.

## 7.5 Reminder Scheduling

- **Required APIs:** Reminder Creation; Reminder Update (for
  rescheduling).
- **Required Database Tables:** Reminder records (due date, timing rule,
  custom fire date/time, selected delivery methods).
- **Required Business Logic:** Exactly one timing option required;
  Custom time requires both Date and Time, resolving on or before the
  reminder's due date; at least one delivery method required; timing
  options computed relative to the reminder's own due date; each
  selected delivery method dispatched independently of the others.
- **Required Services:** Reminder Service; Smart Reminder Engine.
- **Required Background Jobs:** Reminder Scheduler (Section 8).
- **Required Notifications:** Triggers In-App Notification, Push
  Notification, WhatsApp Message, and/or SMS Message delivery, per the
  selected methods (Section 9).
- **Required Permissions:** Same as §7.1.

## 7.6 Smart Calendar

- **Required APIs:** Calendar Aggregation retrieval (accepts a date range
  or view granularity).
- **Required Database Tables:** Reminder records, Debt records, Promise
  to Pay records.
- **Required Business Logic:** Aggregates every dated item — all five
  reminder types, Payment Due dates, Promise to Pay dates — into one
  dated collection; a date is marked only if it carries at least one
  item.
- **Required Services:** Calendar Aggregation Service.
- **Required Background Jobs:** None. Aggregation is computed on
  request.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 7.7 WhatsApp (WhatsApp Preview)

- **Required APIs:** Message Template retrieval; Message Rendering
  (substitutes live data into a template); Send via WhatsApp.
- **Required Database Tables:** Message Template records, Reminder or
  Case records, Sent Message records.
- **Required Business Logic:** A template must be selected before
  sending is enabled; the recipient's phone number must be present and
  valid; the message body is generated by substituting customer name,
  amount due, due date, and sender/company name into the selected
  template; every send is recorded against the originating reminder or
  case.
- **Required Services:** Message Template Service; Message Rendering
  Service; WhatsApp Delivery Service.
- **Required Background Jobs:** None directly — a manual send is
  synchronous; a timed send is triggered by the Reminder Scheduler
  (Section 8).
- **Required Notifications:** Records the successful delivery (Section
  9).
- **Required Permissions:** Same as §7.1.

## 7.8 SMS (SMS Preview)

- **Required APIs:** Message Template retrieval (shared with §7.7);
  Message Rendering (shared); Send via SMS.
- **Required Database Tables:** Message Template records, Reminder or
  Case records, Sent Message records.
- **Required Business Logic:** Identical to §7.7, applied to the SMS
  channel; the recipient's phone number must be valid for SMS delivery
  specifically.
- **Required Services:** Message Template Service; Message Rendering
  Service; SMS Delivery Service.
- **Required Background Jobs:** Same pattern as §7.7.
- **Required Notifications:** Records the successful delivery (Section
  9).
- **Required Permissions:** Same as §7.1.

## 7.9 Reminder Workflow

- **Required APIs:** None additional — covered collectively by §7.1,
  §7.3, §7.4, §7.5, §7.7, and §7.8's APIs.
- **Required Database Tables:** Reminder records.
- **Required Business Logic:** The full lifecycle — Schedule, Send,
  Complete, Reschedule — expressed through the four statuses (Today,
  Upcoming, Overdue, Completed); a reminder is Overdue whenever its due
  date has passed while its status is not yet Completed; a rescheduled
  reminder retains its original Created By/Created On while adopting a
  new due date and timing rule.
- **Required Services:** Reminder Service; Smart Reminder Engine.
- **Required Background Jobs:** Reminder Scheduler (Section 8).
- **Required Notifications:** Per action, as documented under §7.5,
  §7.7, §7.8, and Section 9.
- **Required Permissions:** Same as §7.1.

---

# 6. Documents Mapping

*Maps to `Mobile_UI_V1_Frozen.md` §8 and its components §8.1–8.8.*

## 8.1 All Documents

- **Required APIs:** Document List retrieval (filterable by type tab,
  searchable); Storage Usage retrieval.
- **Required Database Tables:** Invoice records, Receipt records, Demand
  Letter records, Statement records.
- **Required Business Logic:** "All" returns every document type;
  Invoices/Receipts/Letters each filter to their respective type;
  "Other" covers any type not covered by the first three tabs.
- **Required Services:** Document Aggregation Service; Storage Usage
  Service; Search Service (Section 7).
- **Required Background Jobs:** None required. Storage Usage may be
  computed live or maintained incrementally — an implementation choice,
  not a UI requirement.
- **Required Notifications:** None.
- **Required Permissions:** Business Owner/Administrator, Sales & Finance
  Staff.

## 8.2 Invoices

- **Required APIs:** Invoice List retrieval.
- **Required Database Tables:** Invoice records.
- **Required Business Logic:** An invoice represents the amount billed
  to a customer, generated at the point a debt is established; immutable
  once generated.
- **Required Services:** Invoice Service.
- **Required Background Jobs:** None.
- **Required Notifications:** None specified by the frozen UI beyond the
  document appearing in §8.1's list once generated.
- **Required Permissions:** Same as §8.1.

## 8.3 Receipts

- **Required APIs:** Receipt List retrieval.
- **Required Database Tables:** Receipt records, Payment records.
- **Required Business Logic:** Generated automatically whenever a
  payment is recorded; immutable once generated.
- **Required Services:** Receipt Service (invoked by the Payment
  Service on payment recording, Section 4).
- **Required Background Jobs:** None.
- **Required Notifications:** None specified beyond §8.1's listing.
- **Required Permissions:** Same as §8.1.

## 8.4 Demand Letters

- **Required APIs:** Demand Letter List retrieval.
- **Required Database Tables:** Demand Letter records.
- **Required Business Logic:** Generated from an approved template at
  the point a debt is escalated; immutable once generated.
- **Required Services:** Demand Letter Service (invoked by Case
  Escalation, Section 4).
- **Required Background Jobs:** None.
- **Required Notifications:** None specified beyond §8.1's listing.
- **Required Permissions:** Same as §8.1.

## 8.5 Statements

- **Required APIs:** Statement List retrieval.
- **Required Database Tables:** Statement records.
- **Required Business Logic:** Reflects a customer's full account
  history at generation time; immutable once generated.
- **Required Services:** Statement Service.
- **Required Background Jobs:** None.
- **Required Notifications:** None specified beyond §8.1's listing.
- **Required Permissions:** Same as §8.1.

## 8.6 Preview

- **Required APIs:** Document Detail retrieval.
- **Required Database Tables:** Invoice, Receipt, Demand Letter, and
  Statement records.
- **Required Business Logic:** Always returns the exact, final,
  immutable content generated for the document — never a
  live-recomputed version.
- **Required Services:** Document Service (polymorphic resolution across
  the four document types).
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Same as §8.1.

## 8.7 Download

- **Required APIs:** Document Download.
- **Required Database Tables:** Invoice, Receipt, Demand Letter, and
  Statement records; Document Event records.
- **Required Business Logic:** Every download is recorded against the
  document's history for audit purposes.
- **Required Services:** Document Service; Audit Trail Service (Section
  7).
- **Required Background Jobs:** None.
- **Required Notifications:** None.
- **Required Permissions:** Same as §8.1.

## 8.8 Share

- **Required APIs:** Document Share; Send via WhatsApp; Send via SMS
  (shared with Section 5).
- **Required Database Tables:** Invoice, Receipt, Demand Letter, and
  Statement records; Document Event records; Sent Message records.
- **Required Business Logic:** The recipient's contact information must
  be present and valid for the selected channel; every share is recorded
  against the document's history and the recipient's record.
- **Required Services:** Document Service; Message Template Service;
  Message Rendering Service; WhatsApp/SMS Delivery Services; Audit Trail
  Service.
- **Required Background Jobs:** None.
- **Required Notifications:** Records the successful delivery (Section
  9), same as §7.7/§7.8.
- **Required Permissions:** Same as §8.1.

---

# 7. Shared Services

Only services actually required by more than one mapped component above
are listed here, each with the modules that depend on it.

| Service | Purpose | Used By |
|---|---|---|
| Reminder Service | Core reminder create/read/update/delete and status logic | Home §4.3, Cases §6.5, Reminder Center §7.1–7.9 |
| Smart Reminder Engine | Status derivation and timing-rule evaluation for reminders | Reminder Center §7.1, §7.3, §7.5, §7.9 |
| Message Template Service | Retrieves stored message templates | Reminder Center §7.7, §7.8; Documents §8.8 |
| Message Rendering Service | Substitutes live data into a selected template | Reminder Center §7.7, §7.8; Documents §8.8 |
| WhatsApp Delivery Service | Dispatches a rendered message via WhatsApp | Reminder Center §7.7; Documents §8.8; Home §4.4 |
| SMS Delivery Service | Dispatches a rendered message via SMS | Reminder Center §7.8; Documents §8.8; Home §4.4 |
| Case Service | Core case create/read/update logic and status rules | Cases §6.1–6.5; Home §4.4, §4.5 |
| Case List Service | Filterable, paginated case retrieval | Cases §6.1; Home §4.5 |
| Risk Classification Service | Determines and reports a customer's risk level | Analytics §5.6; Cases §6.2; Home §4.2 |
| Aging Analysis Service | Assigns open debts to age brackets | Analytics §5.5; Analytics §5.2; Home §4.2 |
| Audit Trail Service | Records case activity and document download/share events | Cases §6.4; Documents §8.7, §8.8 |
| Document Service | Polymorphic retrieval, preview, and download across all document types | Documents §8.1–8.8 |
| Storage Usage Service | Reports per-tenant document storage consumption | Documents §8.1 |
| Search Service | Query-based lookup within a list | Reminder Center §7.1; Documents §8.1 |
| Reporting Service | Filterable, exportable entity-level reports | Analytics §5.2 |
| Analytics Aggregation Service | Period-scoped KPI and chart aggregation | Analytics §5.1, §5.3, §5.4 |

No service is listed that is used by only one component; single-use
logic is documented directly under its owning screen in Sections 2–6.

---

# 8. Background Jobs

Only one background process is required by the frozen UI's specified
behavior:

## Reminder Scheduler

- **Why it is required:** Reminder Scheduling (§7.5) requires a reminder
  to be delivered "1 day before," "same day," "1 hour before," or at a
  custom date/time relative to its due date. None of these timing rules
  can be satisfied by computing a value only when a screen happens to be
  open — something must actively check pending reminders and fire their
  configured delivery at the correct moment, independent of whether any
  user is using the application at that time.
- **What it does:** Periodically evaluates every reminder with a pending
  timing rule; for any reminder whose configured fire time has arrived,
  dispatches delivery via each of its selected methods (In-App
  Notification, Push Notification, WhatsApp Message, SMS Message), per
  §7.5's independent-dispatch rule.
- **Depends on:** Smart Reminder Engine (Section 5); Message Template
  and Rendering Services, WhatsApp/SMS Delivery Services (Section 7).

## Jobs explicitly not required

For traceability, the following are deliberately excluded, with the
frozen-UI basis for each exclusion:

- **A reminder status-transition job** (proactively flipping a reminder
  to Overdue) is not required. §7.9 defines Overdue as "whenever its due
  date has passed while its status is not yet Completed" — a condition
  that can be correctly evaluated at the moment of any request (§7.1,
  §7.3) without needing a background writer.
- **A dashboard or analytics caching job** is not required. §4.1 requires
  Business Health to be "recalculated continuously," and §5.1 requires
  Analytics figures to recompute "immediately whenever the date range
  changes" — both are explicit live-computation requirements, not
  caching requirements.

---

# 9. Notifications

The frozen UI's own basis for notification behavior is narrow and is
documented here exactly as specified, without extension:

- **§7.5 (Reminder Scheduling)** specifies four delivery methods a
  scheduled reminder may use: In-App Notification, Push Notification,
  WhatsApp Message, SMS Message — each dispatched independently.
- **§7.4 / §7.7 / §7.8 (Reminder Details, WhatsApp Preview, SMS
  Preview)** specify manual "Send Reminder" / "Send via WhatsApp" / "Send
  via SMS" actions that dispatch immediately on user action, using the
  same rendering and recording rules as the scheduled case.
- **§2.10 and §9 (Reusable Components)** acknowledge that notification
  entries exist as a list-based content type, using the same List
  Card/Row component as case, reminder, and document entries, and that
  such a list scrolls like every other list-based screen.

## Required notification events

| Event | Trigger | Delivery Channel(s) |
|---|---|---|
| Scheduled Reminder Delivery | Smart Reminder Engine's timing rule fires (§7.5) | Whichever of In-App/Push/WhatsApp/SMS were selected |
| Manual Reminder Send | User taps "Send Reminder" / "Send via WhatsApp" / "Send via SMS" (§7.4, §7.7, §7.8) | WhatsApp or SMS, per the action taken |
| Document Share Send | User taps "Share" and sends a document (§8.8) | WhatsApp or SMS, per the channel selected |

Each event above must create a notification-entry record so it can
appear in the per-user notification list referenced by §2.10 and §9.

## Explicitly not specified by the frozen UI

The frozen UI references notification entries as a component type
(§2.10, §9) but does not dedicate a numbered section to a Notifications
screen's tabs, filters, read/unread states, or actions. This document
does not invent that detail. The backend requirement implied by the
frozen UI's own text is limited to: a per-user, chronological list of
notification-entry records, populated by the three events above. Any
further Notifications-screen behavior (mark-as-read, filtering, etc.)
requires a future revision of the frozen UI before it can be specified
here.

---

# 10. Permissions

Every screen and action mapped to its required role(s), per the
Permissions field already specified throughout `Mobile_UI_V1_Frozen.md`:

| Screen / Action | Required Role(s) |
|---|---|
| Bottom Navigation (§3) | Any authenticated user (destination access governed per-screen below) |
| Home Dashboard — all components (§4.1–4.5) | Business Owner/Administrator, Sales & Finance Staff |
| Analytics — all components (§5.1–5.6) | Business Owner/Administrator, Sales & Finance Staff |
| Cases — Case List, Filters, Case Details, Timeline (§6.1–6.4) | Business Owner/Administrator, Sales & Finance Staff, Collections Staff |
| Cases — Actions (§6.5) | Business Owner/Administrator, Sales & Finance Staff, assigned Collections Staff (per-action gated) |
| Reminder Center — Dashboard, Reminder List (§7.1, §7.3) | Business Owner/Administrator, Sales & Finance Staff, Collections Staff |
| Reminder Center — Reminder Details, viewing (§7.4) | Business Owner/Administrator, Sales & Finance Staff, Collections Staff |
| Reminder Center — Reminder Details, edit/delete (§7.4) | The reminder's creator, or a manager-level role |
| Reminder Center — Reminder Scheduling (§7.5) | Business Owner/Administrator, Sales & Finance Staff, Collections Staff |
| Reminder Center — Smart Calendar (§7.6) | Business Owner/Administrator, Sales & Finance Staff |
| Reminder Center — WhatsApp/SMS Preview (§7.7, §7.8) | Business Owner/Administrator, Sales & Finance Staff, Collections Staff |
| Documents — all components (§8.1–8.8) | Business Owner/Administrator, Sales & Finance Staff |

All permission checks are additionally scoped to the authenticated user's
own tenant, per §11's Tenant Isolation rule — no permission grants access
to another business's data under any circumstance.

---

# 11. API Inventory

Grouped by module. No endpoint payload or route syntax is specified —
only purpose, HTTP method, and authentication requirement, per the task
scope. Every endpoint requires an authenticated, tenant-scoped session
unless otherwise noted.

## Home Dashboard

| Endpoint Purpose | Method | Auth |
|---|---|---|
| Retrieve Business Health score and status | GET | Authenticated |
| Retrieve Dashboard KPI summary | GET | Authenticated |
| Retrieve Today's Reminder summary | GET | Authenticated |
| Retrieve Recent Cases preview | GET | Authenticated |
| Create a Case (Quick Action) | POST | Authenticated |
| Record a Payment (Quick Action) | POST | Authenticated |
| Capture an Invoice (Quick Action) | POST | Authenticated |
| Compose a Message (Quick Action) | POST | Authenticated |

## Analytics

| Endpoint Purpose | Method | Auth |
|---|---|---|
| Retrieve Analytics Overview for a date range | GET | Authenticated |
| Retrieve Customers report | GET | Authenticated |
| Retrieve Debts report | GET | Authenticated |
| Retrieve Collection Cases report | GET | Authenticated |
| Retrieve Payments report | GET | Authenticated |
| Retrieve Credit Risk report | GET | Authenticated |
| Retrieve Aging Analysis report | GET | Authenticated |
| Export a report | GET | Authenticated |
| Retrieve Collections Trend time series | GET | Authenticated |
| Retrieve Collection Analytics KPIs | GET | Authenticated |
| Retrieve Aging Analysis (dashboard chart) | GET | Authenticated |
| Retrieve Risk Distribution | GET | Authenticated |

## Cases

| Endpoint Purpose | Method | Auth |
|---|---|---|
| Retrieve Case List (filterable) | GET | Authenticated |
| Retrieve Case Details | GET | Authenticated |
| Retrieve Case Timeline | GET | Authenticated |
| Record a Payment against a case's debt | POST | Authenticated |
| Assign an officer to a case | PATCH | Authenticated |
| Escalate a case | POST | Authenticated |
| Close a case | POST | Authenticated |

## Reminder Center

| Endpoint Purpose | Method | Auth |
|---|---|---|
| Retrieve Reminder summary (today/overdue/per-type counts) | GET | Authenticated |
| Search reminders | GET | Authenticated |
| Retrieve Reminder List (filterable by status) | GET | Authenticated |
| Retrieve Reminder Detail | GET | Authenticated |
| Create a Reminder | POST | Authenticated |
| Update a Reminder (edit or reschedule) | PUT/PATCH | Authenticated |
| Delete a Reminder | DELETE | Authenticated |
| Complete a Reminder | PATCH | Authenticated |
| Send a Reminder (manual, immediate) | POST | Authenticated |
| Retrieve Calendar aggregation for a range | GET | Authenticated |
| Retrieve Message Templates | GET | Authenticated |
| Render a message from a template | POST | Authenticated |
| Send a rendered message via WhatsApp | POST | Authenticated |
| Send a rendered message via SMS | POST | Authenticated |

## Documents

| Endpoint Purpose | Method | Auth |
|---|---|---|
| Retrieve Document List (filterable by type, searchable) | GET | Authenticated |
| Retrieve Storage Usage | GET | Authenticated |
| Retrieve Invoice List | GET | Authenticated |
| Retrieve Receipt List | GET | Authenticated |
| Retrieve Demand Letter List | GET | Authenticated |
| Retrieve Statement List | GET | Authenticated |
| Retrieve Document Detail (Preview) | GET | Authenticated |
| Download a Document | GET | Authenticated |
| Share a Document (delegates to WhatsApp/SMS send, above) | POST | Authenticated |

---

# 12. Database Impact

Every table required by the frozen UI, its purpose, its relationships,
and the screens that depend on it. No column-level schema is specified.

| Table | Purpose | Relationships | Used By |
|---|---|---|---|
| Customers | Represents each business's customer | Has many Debts, Cases (via Debts), Documents | Home §4.1–4.5; Analytics §5.1–5.6; Cases §6.1–6.3; Documents §8.1–8.5 |
| Debts | Represents an amount owed by a customer | Belongs to Customer; has many Payments, one Case (when escalated) | Home §4.2, §4.3; Analytics §5.1–5.5; Cases §6.1–6.5; Reminder Center §7.6; Documents §8.2 |
| Payments | Records a payment against a debt | Belongs to Debt; has one Receipt | Home §4.2; Analytics §5.1, §5.3, §5.4; Cases §6.5; Documents §8.3 |
| Cases (Collection Cases) | Tracks a debt's collection workflow | Belongs to Debt; has many Case Activity/Follow-Up entries | Home §4.5; Analytics §5.2; Cases §6.1–6.5 |
| Promise to Pay | Records a customer's committed payment date | Belongs to Debt or Case | Cases §6.2; Reminder Center §7.2, §7.6 |
| Case Activity/Follow-Up | Chronological record of actions taken on a case | Belongs to Case | Cases §6.4 |
| Audit Records | Records administrative and document-related events | References the acting user and the affected record | Cases §6.4; Documents §8.7, §8.8 |
| Reminders | Represents a scheduled or logged follow-up task | Belongs to a related entity (Customer, Debt, or Case) depending on type | Home §4.3; Reminder Center §7.1–7.9; Documents §8.8 (via Share) |
| Message Templates | Stores reusable message bodies with substitution placeholders | Referenced by Sent Messages | Reminder Center §7.7, §7.8; Documents §8.8 |
| Sent Messages | Records every WhatsApp/SMS message actually dispatched | References the originating Reminder or Case, and the Message Template used | Reminder Center §7.7, §7.8; Documents §8.8 |
| Invoices | Represents the amount billed to a customer | Belongs to Debt | Documents §8.1, §8.2 |
| Receipts | Proof of a recorded payment | Belongs to Payment | Documents §8.1, §8.3 |
| Demand Letters | Formal collection correspondence | Belongs to Debt | Documents §8.1, §8.4 |
| Statements | Full-account customer history document | Belongs to Customer | Documents §8.1, §8.5 |
| Document Events | Records downloads and shares of any document | References the affected document and acting user | Documents §8.7, §8.8 |
| Notification Entries | Per-user record of a dispatched notification | References the triggering event and recipient user | Section 9 (all notification events) |

---

# 13. Implementation Roadmap

Ordered from highest to lowest priority. Priority reflects dependency
order — later sprints build on data and services established earlier —
not screen importance.

## Sprint 1 — Core Data Model & Cases (Highest Priority)

Establish Customers, Debts, Payments, and Cases, together with the Case
List, Filters, Case Details, Timeline, and Actions (§6.1–6.5). Every
other module depends on this data model; Cases is the first fully
functional screen once it is complete.

## Sprint 2 — Home Dashboard

Business Health, KPI Cards, Today's Overview (partial — full counts
depend on Sprint 4), Quick Actions, and Recent Cases (§4.1–4.5), built
directly on Sprint 1's data model.

## Sprint 3 — Documents

Invoice, Receipt, Demand Letter, and Statement generation, All Documents,
Preview, and Download (§8.1–8.7). Receipts depend on Sprint 1's Payment
recording; Demand Letters depend on Sprint 1's Escalation action.

## Sprint 4 — Reminder Center Core

Reminder Types, Reminder List, Reminder Details, Dashboard, and Reminder
Workflow status handling (§7.1–7.4, §7.9), excluding scheduled-delivery
timing. Completes Home Dashboard's Today's Overview counts from Sprint 2.

## Sprint 5 — Smart Reminder Engine, Scheduling, and Delivery

Reminder Scheduling (§7.5), the Smart Reminder Engine, the Reminder
Scheduler background job (Section 8), Message Templates and Rendering,
and WhatsApp/SMS delivery (§7.7, §7.8). This is the most complex sprint
in the roadmap and depends on Sprint 4's reminder data model being
stable.

## Sprint 6 — Smart Calendar & Document Share

Smart Calendar (§7.6), which aggregates Reminder, Debt, and Promise to
Pay dates from Sprints 1, 4, and 5; Document Share (§8.8), which reuses
Sprint 5's WhatsApp/SMS delivery for documents.

## Sprint 7 — Analytics

Overview, Reports, Trends, Collection Analytics, Aging Analysis, and Risk
Distribution (§5.1–5.6) — a read-only reporting layer over data already
established in Sprints 1–3; sequenced after the modules producing the
data it reports on, not before.

## Sprint 8 — Cross-Cutting Completion (Lowest Priority)

Search across Reminder Center and Documents (§7.1, §8.1); Storage Usage
(§8.1); the per-user notification-entry list implied by §2.10/§9;
permission hardening and audit-trail completeness across all modules.
Lowest priority because each item here refines an already-functional
module rather than delivering new capability.
