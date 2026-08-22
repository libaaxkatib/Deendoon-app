# 10. Acceptance Criteria

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-10 |
| **Document Title** | Acceptance Criteria |
| **Version** | 1.5 |
| **Status** | Reopened — Section 14 (Module 13 — Subscription & Storage Self-Service) added, closing a pre-existing documentation gap found during the Manual Mobile-Money Subscription Payment Flow Amendment audit |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Product Owner (prior version); reopened section pending re-approval |
| **Last Updated** | 2026-08-19 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened v1.5) · `02_Business_Requirements.md` (Reopened v1.6) · `03_Functional_Requirements.md` (v1.17 — **Module 12 still awaiting its original approval**) · `04_Business_Rules.md` (Reopened v1.11) · `05_UI_UX_Specification.md` (Reopened, v1.9) · `06_Database_Design.md` (Reopened v1.9 — §6.1 amended, PostgreSQL) · `07_API_Design.md` (Reopened v1.8 — §5.4 amended) · `08_Security_and_RBAC.md` (Reopened v1.5 — §5 amended) · `09_Non_Functional_Requirements.md` (Approved, v1.2) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: testable pass/fail acceptance criteria for all 76 approved Functional Requirements (FR-001–FR-076), closing out every "Acceptance Criteria References: To be defined in `10_Acceptance_Criteria.md`" placeholder left across `03_Functional_Requirements.md`. Organized as Cross-Cutting criteria (apply universally) plus per-FR criteria (module-organized, matching `03`'s structure). Criteria referencing a still-unresolved `04_Business_Rules.md` Deferred Decision are written to validate the *invariant* that holds regardless of how the DD resolves, not a specific outcome — flagged individually. | Claude |
| 1.1 | 2026-07-31 | **Scope Baseline metadata correction (Documentation Consistency Audit — Scope Baseline synchronization).** Updated the Scope Baseline field to cite the current approved versions of `02` through `09` (previously stale), and corrected `09`'s cited status from "Approved & Frozen" to "Approved" to match `09`'s own header. No acceptance criterion or approved content changed. | Claude |
| 1.2 | 2026-07-31 | **Product Vision Amendment (Product Owner Decision).** FR-041's Acceptance Criteria (AC-041-1, AC-041-2) marked Retired with a notice, matching FR-041's own retirement in `03_Functional_Requirements.md` v1.8 — this document had not previously been updated to reflect that retirement. Criteria text preserved for history, not deleted. Scope Baseline updated to cite `01` at its current version (v1.4). No other acceptance criterion changed. | Claude |
| 1.3 | 2026-07-31 | **Scope Baseline metadata correction (Product Vision Amendment ripple).** Updated the Scope Baseline field to cite `03`–`09` at their current versions following those documents' own updates. No acceptance criterion changed. | Claude |
| 1.4 | 2026-07-31 | **Final architecture consistency audit correction.** AC-067-1 still assumed "seven approved roles" — missed by every prior sweep. Updated to reflect the single approved role (Business Owner, `admin`), matching FR-067's own amendment and the corresponding fix in `05_UI_UX_Specification.md` v1.5 (SCR-039/040/041). Scope Baseline updated to cite `05` at its current version. No other acceptance criterion changed. | Claude |
| 1.0 | 2026-07-24 | Approved and frozen without changes. | Product Owner |
| 1.5 | 2026-08-19 | **Documentation gap closure (Manual Mobile-Money Subscription Payment Flow Amendment audit finding), Product Owner-approved decision.** Added **Section 14 — Module 13 — Subscription & Storage Self-Service**: acceptance criteria for FR-077 through FR-084 (approved since the Subscription & Storage Self-Service Catch-Up, `03` Revision History 1.13, but never given criteria here — every FR-077–FR-084 "Acceptance Criteria References" line in `03` pointed here to nothing) plus the newly-added FR-086 (Platform Payment Destination Number). Former Section 14 (Traceability Confirmation) renumbered to Section 15 and its coverage table/summary line extended to include Module 13; former Section 15 (Criteria Pending Business Rule Resolution) renumbered to Section 16. FR-085 (Invoice Generation, Module 8) remains a separate, pre-existing gap, explicitly out of scope for this amendment. No existing criterion (AC-001 through AC-076-range) was changed. Scope Baseline updated to cite `03` v1.17, `04` v1.11, `05` v1.9, `06` v1.9, `07` v1.8, `08` v1.5. | Claude |

---

## Document Purpose

This document defines testable, pass/fail acceptance criteria for every approved Functional Requirement in `03_Functional_Requirements.md`. It is the document every one of that document's 76 "Acceptance Criteria References: To be defined in `10_Acceptance_Criteria.md` under FR-XXX" placeholders has been pointing to since Module 1 was first drafted.

Every criterion below derives directly from its FR's already-approved Main Flow, Alternate Flows, and Exceptions — this document does not introduce new behavior, new business logic, or a new interpretation of any FR. Where an FR's behavior depends on a Business Rule still marked as a Deferred Decision in `04_Business_Rules.md`, the corresponding criterion is written to validate what's true *regardless* of how that decision resolves (e.g., "no duplicate active record is created," not "the duplicate attempt is rejected" vs. "redirected," since `04` hasn't decided which) — flagged inline, not resolved here.

**Guardian boundary:** no criterion below tests for a capability, permission, or workflow beyond what `01`–`09` already approve. This document does not redesign any FR; it makes each one measurable.

---

## Methodology

- **ID scheme:** `AC-<FR number>-<sequence>`, e.g., `AC-007-1`, `AC-007-2`. Where a criterion corresponds directly to a named Alternate Flow or Exception in the source FR, that label is noted (e.g., "(E1)") for direct cross-reference back to `03`.
- **Format:** each criterion is a single, independently verifiable pass/fail statement — a tester (human or automated) can execute it and get an unambiguous result.
- **Cross-cutting criteria are not repeated per FR.** Section 1 states universal expectations (authentication, RBAC, tenant isolation, validation, audit logging, archive behavior, soft-warning behavior) that apply to *every* FR meeting the described condition (e.g., "every permission-gated action" or "every archivable resource"). A given FR's own section lists only what's specific to it.
- **Definition of "Pass":** a criterion passes when the described precondition, action, and expected outcome all hold exactly as stated — partial matches (e.g., correct data but wrong HTTP status) fail.
- **Deferred-Decision-dependent criteria** are marked **(Pending DD)** with the specific Deferred Decision ID from `04_Business_Rules.md` — these validate an invariant that holds under any resolution, not a specific one, and will need a follow-up criterion once the DD resolves.

---

## 1. Cross-Cutting Acceptance Criteria

These apply universally, referenced by number from every module below rather than restated.

| ID | Criterion |
|---|---|
| **AC-GLOBAL-AUTH** | Any endpoint requiring authentication (`07` §5, marked 🔒) rejects a request with no token, an invalid token, or an expired token with `401 UNAUTHENTICATED`. |
| **AC-GLOBAL-RBAC** | Any permission-gated action succeeds for a role permitted to perform it (`08` §5) and is rejected with `403 FORBIDDEN` for a role that is not — the action is never silently allowed nor silently no-op'd. |
| **AC-GLOBAL-TENANT** | A tenant-scoped resource belonging to Tenant A is never retrievable, editable, or listable by an authenticated session belonging to Tenant B; the response is `404 NOT_FOUND`, not `403`, so existence is never confirmed to the wrong tenant (`07` §4). |
| **AC-GLOBAL-VALIDATION** | Submitting a request with a missing required field, or a field violating its documented constraint (`06` §6 / `07` §7), returns `422 VALIDATION_FAILED` with a `fields` array identifying every offending field; no partial record is created or persisted. |
| **AC-GLOBAL-AUDIT** | Every action whose FR states an Audit Trail event is recorded results in exactly one corresponding `audit_log` row with the correct `action`, `entity_type`, `entity_id`, `user_id` (or `NULL` for a system-automated action), and `occurred_at` — never zero rows, never duplicated rows. |
| **AC-GLOBAL-ARCHIVE** | Archiving a resource excludes it from default list/search results without deleting the underlying row; it remains retrievable via search only when archived records are explicitly included, and is not editable via the resource's normal update action until restored. |
| **AC-GLOBAL-RESTORE** | Restoring an archived resource returns it to default list/search results and re-enables its normal update action. |
| **AC-GLOBAL-WARNING** | An advisory warning (Credit Limit Exceeded, FR-018; Possible Duplicate Customer, FR-014) is returned as part of a successful (`200`/`201`) response, never as a `4xx` error that blocks the underlying action. |
| **AC-GLOBAL-IMMUTABLE** | A resource with no approved edit/delete path (Payments, Documents, `request_messages`, `audit_log`) cannot be modified or removed through any endpoint — no `PUT`/`PATCH`/`DELETE` succeeds against it. |

---

## 2. Module 1 — Authentication & User Session

### FR-001 — User Login
- **AC-001-1:** Valid identifier + credential for an active account with ≥ 1 assigned role → login succeeds, a session token is issued, and a Login event is recorded (AC-GLOBAL-AUDIT).
- **AC-001-2 (A1):** Invalid credential → rejected with a generic error that does not reveal which field was wrong; no session created; no Login event recorded.
- **AC-001-3 (A2):** Archived account → rejected with an "account not active" message; no session created.
- **AC-001-4:** A login attempt using an identifier type other than the tenant's configured type (email vs. username) is rejected the same as an unrecognized identifier.

### FR-002 — User Logout
- **AC-002-1:** Logout invalidates only the current session's token (subsequent use returns `401`); a Logout event is recorded.
- **AC-002-2:** Logout on an already-invalidated session is a no-op, not an error.
- **AC-002-3:** Other active sessions for the same user (other devices) remain valid.

### FR-003 — Session Expiry (Timeout)
- **AC-003-1:** A session idle beyond the configured timeout is rejected (`401`) on its next use.
- **AC-003-2 (A1):** A session used within the idle window has its expiry extended rather than expiring.
- **AC-003-3 (A2):** A session that expires mid-action commits no partial record — the in-progress action must be resubmitted after re-authentication.

### FR-004 — Forgot Password / Password Reset
- **AC-004-1:** Requesting a reset for a valid identifier issues a time-limited, single-use token to the configured recovery channel.
- **AC-004-2:** A valid, unused, unexpired token with a new credential updates the credential and invalidates the token; the same token cannot be reused.
- **AC-004-3 (A1):** An expired or already-used token is rejected.
- **AC-004-4:** A successful reset records an Edited event against the User entity (AC-GLOBAL-AUDIT).

### FR-005 — Change Password (Authenticated)
- **AC-005-1:** Correct current credential + valid new credential → change succeeds, Edited event recorded.
- **AC-005-2 (E1):** Incorrect current credential → rejected; stored credential unchanged.
- **AC-005-3:** A successful change revokes **all** of the user's active tokens, not only the current session's (`08` §3).

### FR-006 — Role & Permission Resolution on Login
- **AC-006-1:** On login, the session's role and permission set are correctly resolved and applied to every subsequent request.
- **AC-006-2 (A1):** A mid-session role change is reflected in the user's effective permissions without indefinitely continuing under the stale role.
- **AC-006-3 (E1):** A user with no assigned role is denied every role-gated module (`403`) despite being authenticated.

---

## 3. Module 2 — Customer Management

### FR-007 — Customer Creation
- **AC-007-1:** Valid required fields, no duplicate match → Customer created with Status = Active, Credit Limit = tenant default unless explicitly provided; Created event recorded.
- **AC-007-2:** An explicit Credit Limit on creation overrides the tenant default.
- **AC-007-3:** A likely duplicate match surfaces the warning (AC-GLOBAL-WARNING) rather than blocking; "Continue Anyway" creates the record as distinct.
- **AC-007-4 (E1):** Missing/invalid required fields → `422` (AC-GLOBAL-VALIDATION); no record created.

### FR-008 — Customer Details
- **AC-008-1:** Viewing a non-archived Customer returns Credit Limit, Outstanding Balance, Remaining Credit, Risk Level, Credit Score, and Customer Status.
- **AC-008-2 (A1):** A restricted role sees only the fields its role permits (server-omitted, not client-hidden).
- **AC-008-3:** An Archived Customer is returned read-only, restore-eligible.

### FR-009 — Customer Update
- **AC-009-1:** Valid field changes persist; an Edited event is recorded, or a Credit Limit Changed event specifically when that field changed.
- **AC-009-2:** A name/phone change re-runs Duplicate Detection under the same non-blocking rules as FR-007.
- **AC-009-3 (E2):** Updating an Archived Customer is rejected — must be restored first.

### FR-010 — Customer Archive
- **AC-010-1:** Archiving a non-archived Customer applies AC-GLOBAL-ARCHIVE; an Archived event is recorded.
- **AC-010-2 (E2):** Archiving an already-archived Customer is a no-op.

### FR-011 — Customer Restore
- **AC-011-1:** Restoring an Archived Customer applies AC-GLOBAL-RESTORE; a Restored event is recorded.
- **AC-011-2 (E2):** Restoring a non-archived Customer is a no-op.

### FR-012 — Customer Status Management
- **AC-012-1:** Setting Customer Status to any of the 7 approved values succeeds; a Status Changed event is recorded.
- **AC-012-2 (E1):** A value outside the approved 7 is rejected.

### FR-013 — Credit Profile
- **AC-013-1:** Remaining Credit displayed always equals Credit Limit − Outstanding Balance at the moment of viewing.
- **AC-013-2:** Updating Credit Limit succeeds for an authorized role (AC-GLOBAL-RBAC); a Credit Limit Changed event is recorded.
- **AC-013-3 (E2):** A negative or non-numeric Credit Limit is rejected.
- **AC-013-4:** Outstanding Balance is never directly editable through this or any Customer action.

### FR-014 — Duplicate Customer Detection
- **AC-014-1:** A close name/phone match on create or import surfaces "This customer may already exist" with the matched record's identity.
- **AC-014-2:** "Open Existing Customer" navigates to the existing record; no new record is created.
- **AC-014-3:** "Continue Anyway" creates the new record; the check never blocks submission (AC-GLOBAL-WARNING).

### FR-015 — Customer Search
- **AC-015-1:** A search term returns matching, non-archived, role-permitted Customers.
- **AC-015-2:** Customer Status / Risk Level / Credit Score filters narrow results correctly.
- **AC-015-3:** Archived Customers are excluded unless explicitly included.

### FR-016 — Customer Import
- **AC-016-1:** Uploading a well-formed file produces a Preview (parsed data, validation status, duplicate-match status per row) with no record created yet.
- **AC-016-2:** Committing applies each row's chosen resolution (Skip/Update/New) exactly; Created or Edited events are recorded per affected row.
- **AC-016-3 (E1):** An unsupported/corrupted file is rejected before Preview; no rows processed.
- **AC-016-4:** Cancelling before Commit creates/modifies no records.

---

## 4. Module 3 — Debt Register

### FR-017 — Debt Creation
- **AC-017-1:** Valid amount/due date against a non-archived Customer → Debt created with a unique `DBT-000001`-format reference; Created event recorded.
- **AC-017-2:** The Customer's Outstanding Balance and Remaining Credit are recalculated immediately.
- **AC-017-3 (E3):** Creation against an Archived Customer is rejected.
- **AC-017-4 (E1):** A non-positive amount or invalid due date is rejected.

### FR-018 — Credit Limit Soft Warning at Debt Entry
- **AC-018-1:** Outstanding + new Debt amount exceeding the Credit Limit surfaces the warning with the limit and projected total.
- **AC-018-2:** "Continue Anyway" still creates the Debt (AC-GLOBAL-WARNING; BC-001).
- **AC-018-3:** A total within the limit shows no warning.

### FR-019 — Debt Details
- **AC-019-1:** Viewing a Debt returns amount, due date, Debt Status, Recovery Stage, Recovery Timeline, and Notes/Attachments.
- **AC-019-2:** An Archived Debt is returned read-only, restore-eligible.

### FR-020 — Debt Update
- **AC-020-1:** Valid non-financial field changes persist; Edited event recorded.
- **AC-020-2:** This action never transitions Debt Status to Paid/Partial Paid.

### FR-021 — Debt Status Tracking
- **AC-021-1:** A Debt's due date passing with no qualifying payment transitions it to Overdue automatically.
- **AC-021-2:** An authorized role may manually set Cancelled or Written Off; Status Changed event recorded.
- **AC-021-3 (E1):** Manually forcing Paid without a qualifying payment is rejected — reachable only via Module 6.

### FR-022 — Debt Archive
- **AC-022-1:** Archiving a non-archived Debt applies AC-GLOBAL-ARCHIVE; Archived event recorded.
- **AC-022-2 (E2):** Archiving an already-archived Debt is a no-op.

### FR-023 — Debt Restore
- **AC-023-1:** Restoring an Archived Debt applies AC-GLOBAL-RESTORE; Restored event recorded.
- **AC-023-2 (E2):** Restoring a non-archived Debt is a no-op.

### FR-024 — Recovery Timeline Display
- **AC-024-1:** The Timeline reflects every recorded event for the Debt in chronological order, sourced only from Follow-up History/Payments/Collection data — no independent write path.
- **AC-024-2:** Stages/events not yet reached are shown as pending, not complete.

### FR-025 — Recovery Stage Display & Override
- **AC-025-1:** Current Recovery Stage (1–6) accurately reflects the automation engine's last determination.
- **AC-025-2:** An authorized role's override with a non-empty reason is applied; a Recovery Stage Override event is recorded with that reason.
- **AC-025-3 (E1):** An override with an empty/missing reason is rejected.
- **AC-025-4 (E2):** A role without override permission cannot access this action (AC-GLOBAL-RBAC).

---

## 5. Module 4 — Credit & Risk Management

### FR-026 — Credit Score Calculation & Recalculation
- **AC-026-1:** A qualifying payment-behavior event triggers recalculation, normalized to 0–100 with the correct band label; a Credit Score Recalculated event is recorded. **(Pending DD-009 for exact point/threshold values — this criterion validates that recalculation occurs and the result stays within 0–100, not a specific resulting number.)**
- **AC-026-2:** The displayed Credit Score always reflects the most recent recalculation — never a stale cached value.

### FR-027 — Risk Level Assignment
- **AC-027-1:** An authorized role can set Risk Level to a value from the tenant's configured set; Edited event recorded.
- **AC-027-2 (E1):** A value outside the configured set is rejected.

### FR-028 — Credit Limit Reached Notification Trigger
- **AC-028-1:** A Customer's Outstanding Balance reaching/exceeding their Credit Limit emits a Credit Limit Reached event that surfaces in the Notification Center.
- **AC-028-2:** At least one notification is generated per genuinely new breach. **(Pending DD-011 for exact re-trigger/suppression behavior on repeat breaches.)**

---

## 6. Module 5 — Recovery Workflow

### FR-029 — Automated Reminder Scheduling (Smart Daily Reminder)
- **AC-029-1:** A Debt meeting the tenant's configured reminder-timing criteria receives an automated reminder without manual action; logged in Follow-up History with a Reminder Sent event.
- **AC-029-2:** A Debt not meeting the criteria (not due, Paid/Cancelled/Written Off/Archived) receives no automated reminder.

### FR-030 — Manual Reminder (WhatsApp / SMS / Call)
- **AC-030-1:** An authorized role sending a manual reminder or logging a call records it in Follow-up History with the corresponding event.
- **AC-030-2 (A1):** A logged call with no outcome is still recorded, not dropped.

### FR-031 — Promise to Pay
- **AC-031-1:** A valid future-dated promise is recorded and scheduled on the Calendar/Notifications.
- **AC-031-2:** Payment on/before the promised date marks it Fulfilled; non-payment marks it Broken and emits a qualifying event to FR-026 and SM-008.

### FR-032 — Recovery Stage Automation
- **AC-032-1:** A qualifying event advances Recovery Stage per the approved sequence, reflected immediately on Debt Details/Timeline.
- **AC-032-2:** An event with no defined mapping leaves Recovery Stage unchanged.
- **AC-032-3:** A manual override (FR-025) is not silently reverted by the next automated cycle absent a new qualifying event.

### FR-033 — Follow-up History
- **AC-033-1:** Every action defined in FR-029–031 and Modules 6/7 produces exactly one Follow-up History entry, correctly attributed.

---

## 7. Module 6 — Payment Tracking

### FR-034 — Payment Recording
- **AC-034-1:** A valid positive-amount payment against a non-archived Debt succeeds; Payment Added event recorded.
- **AC-034-2 (E3):** A role without permission cannot record a payment.
- **AC-034-3 (E2):** Recording against an Archived Debt is rejected.
- **AC-034-4:** A non-positive or non-numeric amount is rejected.

### FR-035 — Payment History
- **AC-035-1:** Viewing a Debt's or Customer's payment history returns every recorded Payment, chronologically, with correct amount/date.

### FR-036 — Outstanding Balance & Remaining Credit Recalculation
- **AC-036-1:** Immediately after a Payment, the Debt's remaining balance, Customer's Outstanding Balance, and Remaining Credit all reflect it correctly.

### FR-037 — Debt Status Update via Payment
- **AC-037-1:** A payment less than the full remaining balance sets Debt Status to Partial Paid.
- **AC-037-2:** A payment completing the remaining balance sets Debt Status to Paid.

### FR-038 — Payment Receipt Generation Trigger
- **AC-038-1:** Every successful Payment automatically triggers Receipt generation with a unique `RCT-000001`-format reference, with no separate user action; Receipt Generated event recorded.

### FR-039 — Downstream Event Emission
- **AC-039-1:** A recorded Payment emits a correctly-classified (on-time/late/partial) event to FR-026.
- **AC-039-2:** An open Promise to Pay on the Debt has its fulfillment evaluated (FR-031).
- **AC-039-3:** A Payment Received notification reaches the Notification Center.

---

## 8. Module 7 — Professional Collection

### FR-040 — Escalation & Collection Case Creation
- **AC-040-1:** A Debt reaching Recovery Stage 5 (or an authorized manual escalation) creates a Collection Case with a unique `COL-000001` reference; Collection Requested event recorded.
- **AC-040-2 (A1):** A Debt with an existing open Case does not receive a second one. **(Pending DD-023 for reject-vs-surface UX — this criterion validates no duplicate open Case is ever created.)**

### FR-041 — Collection Case Assignment

> **Retired (RBAC Architecture Amendment, Product Owner Decision, 2026-07-31).** FR-041 itself was retired in `03_Functional_Requirements.md` v1.8 — Version 1 has exactly one account per tenant (the Business Owner), so there is no second tenant user to assign a Collection Case to, and Collection Officer is no longer a tenant-side role. The criteria below are preserved for history, not deleted, per this project's Documentation Rules; they no longer apply to any implemented endpoint.

- **AC-041-1:** Assigning to a Collection Officer-role user succeeds; Edited event recorded.
- **AC-041-2 (E2):** Assigning to a non-Collection-Officer user is rejected.

### FR-042 — Collection Case Details
- **AC-042-1:** Viewing a Case returns linked Debt, assigned Officer, status, Notes/Attachments.

### FR-043 — Collection Case Update
- **AC-043-1:** Non-financial changes to an open Case persist; Edited event recorded.
- **AC-043-2 (E3):** Updating a Closed Case is rejected.
- **AC-043-3:** No financial field is editable through this action.

### FR-044 — Collection Activity Recording
- **AC-044-1:** Logging activity against an open Case records it and reflects in Follow-up History/Recovery Timeline.
- **AC-044-2:** A payment-related activity reflects Module 6's event without creating/editing the payment.
- **AC-044-3 (E2):** Logging against a Closed Case is rejected.

### FR-045 — Collection Case Closure
- **AC-045-1:** Closing an open Case with a recorded outcome sets status to Closed; Status Changed event recorded; the linked Debt's financial state is not altered by this action alone.
- **AC-045-2 (E2):** Closing an already-Closed Case is a no-op.

### FR-046 — Collection Case History
- **AC-046-1:** Viewing history returns all activities, assignments, and status changes chronologically.

### FR-072 — Submit Professional Collection Request
- **AC-072-1:** Submitting an open Case with no active Request creates one with status Submitted; Professional Collection Request Submitted event recorded.
- **AC-072-2 (E2):** Submitting against a Closed Case is rejected.
- **AC-072-3 (A1):** Submitting against a Case with an existing active Request does not create a second one.

### FR-073 — Professional Collection Request Status Tracking
- **AC-073-1:** The Deendoon Platform Administrator transitions a Request through the approved sequence; each transition records a Professional Collection Request Status Changed event and is immediately visible to the submitting tenant.
- **AC-073-2 (E1):** A transition outside the approved sequence is rejected.
- **AC-073-3:** No tenant-scoped session — including the Tenant Super Admin — can perform a status transition (`403`); only the Deendoon Platform Administrator can (`08` §5, §7's least-privilege verification).
- **AC-073-4:** "Assigned" status is represented purely as accepted ownership — no field, endpoint, or record anywhere associates it with a second Deendoon-side individual.

### FR-074 — Professional Collection Request List & History (Tenant-Facing)
- **AC-074-1:** A tenant session sees only its own submitted Requests, with correct current status and submission date.
- **AC-074-2:** A tenant with no submitted Requests sees an empty state, not an error.

### FR-075 — Professional Collection Request Conversation
- **AC-075-1:** A message from either party is recorded with sender/timestamp/content and visible to both in the shared thread.
- **AC-075-2:** No message can be edited or deleted by either party (AC-GLOBAL-IMMUTABLE).
- **AC-075-3:** A new message triggers a Notification to the other party.

### FR-076 — Professional Collection Request Outcome & Closure
- **AC-076-1:** The Deendoon Platform Administrator setting a final outcome updates status and records a terminal Professional Collection Request Status Changed event.
- **AC-076-2:** Closing a Request does not, by itself, alter the linked Collection Case's own status. **(Pending `06` Decisions Required item on Request/Case closure coupling.)**

---

## 9. Module 8 — Documents

### FR-047 — Digital Receipt Generation
- **AC-047-1:** Generation occurs only as a consequence of FR-038 — no independent creation path exists.
- **AC-047-2:** The generated Receipt is immediately viewable/downloadable, linked to its originating Payment.

### FR-048 — Demand Letter Generation
- **AC-048-1:** Generating against a non-archived Debt with a selected template (First Reminder / Second Reminder / Final Demand / Legal Notice) produces a PDF with a `DL-000001`-format reference shared across all four templates; Demand Letter Generated event recorded.
- **AC-048-2 (E2):** Generation against an Archived Debt is rejected.

### FR-049 — Customer Statement of Account Generation
- **AC-049-1:** Generating from either the Customer Profile or a specific Debt produces a PDF with a unique `ST-000001`-format reference; Statement Generated event recorded.

### FR-050 — Document Viewing
- **AC-050-1:** An authorized role can view any of the three document types; an unauthorized role is denied.

### FR-051 — Document Downloading
- **AC-051-1:** An authorized role can download the document as a PDF matching what was viewable.

### FR-052 — Document History
- **AC-052-1:** Every Generated/Downloaded/Regenerated event is captured chronologically — no other event type appears.

---

## 10. Module 9 — Reporting & Analytics

### FR-053 — Dashboard Summary (Executive KPI Cards)
- **AC-053-1:** KPI cards are scoped correctly — tenant-only on the Customer Mobile App, system-wide on the Super Admin dashboard.
- **AC-053-2:** Selecting a different historical period recalculates and redisplays the same KPI set for that period.

### FR-054 — Aging Analysis Report
- **AC-054-1:** Every open Debt is categorized into exactly one of the five approved buckets by due date, with correctly summed totals.
- **AC-054-2:** The widget, full report, pie chart, and bar chart all reflect the same underlying totals consistently.

### FR-055 — Standard Operational Reports
- **AC-055-1:** Each report category returns only role-permitted records, reflecting current owning-module data without independent computation.
- **AC-055-2:** Archived records are excluded unless explicitly included.

### FR-056 — Report Filtering
- **AC-056-1:** A documented filter narrows results to exactly the matching records; multiple filters combine cumulatively.

### FR-057 — Report Export
- **AC-057-1:** An export in PDF/Excel/CSV contains exactly the data and filters currently applied on screen.
- **AC-057-2 (E1):** A role without export permission cannot trigger an export.

---

## 11. Module 10 — Notifications & Calendar

### FR-058 — In-App Notification Delivery
- **AC-058-1:** Each qualifying event produces exactly one Notification visible to the correct recipient.
- **AC-058-2:** No Notification is ever created by a direct client request — confirmed by the absence of a creation endpoint (`07` §11).

### FR-059 — Notification Read/Unread & Mark All as Read
- **AC-059-1:** Marking one Notification read updates only that one; Mark All as Read updates every unread Notification for that user.

### FR-060 — Notification Filter by Type
- **AC-060-1:** Filtering by type returns only Notifications of the selected type(s).

### FR-061 — Notification History
- **AC-061-1:** History includes both read and unread Notifications, chronologically.

### FR-062 — Calendar View
- **AC-062-1:** The Calendar correctly positions Due Dates, Promise to Pay dates, Call Reminders, and Collection Activities by date, scoped to role-permitted data.
- **AC-062-2:** No action on this screen changes Recovery Stage or any other business state.

---

## 12. Module 11 — Search & Productivity

### FR-063 — Global Search
- **AC-063-1:** A search term returns matching, role-permitted Customers, Debts, Payments, Documents, and Collection Cases, grouped by entity type.
- **AC-063-2:** An entity type the role cannot view is omitted entirely, never shown-then-blocked.
- **AC-063-3:** Archived records are excluded unless explicitly included.

### FR-064 — Advanced Filtering
- **AC-064-1:** The same filter architecture behaves identically everywhere it's applied (Customer list, Debt list, Reports).

### FR-065 — Quick Actions
- **AC-065-1:** Each shortcut navigates directly into its target workflow without bypassing that workflow's own validation or permission checks.

---

## 13. Module 12 — Administration & Settings

### FR-066 — User Administration
- **AC-066-1:** Creating a user within a tenant succeeds for an authorized role; Created event recorded.
- **AC-066-2:** Deactivating a user revokes their active tokens (`08` §3) and excludes them from active user lists without deleting the row.
- **AC-066-3 (E1):** An unauthorized role cannot perform any User Administration action.

### FR-067 — Role & Permission Management

> **Amended (RBAC Architecture Amendment, Product Owner Decision, 2026-07-31).** Version 1 has exactly one approved role (Business Owner, `admin`) — AC-067-1 updated accordingly; no meaningful role-change scenario remains under the one-account-per-tenant model, matching FR-067's own "deprecated, left functional" status (`03_Functional_Requirements.md`).

- **AC-067-1:** Assigning the one approved role (Business Owner, `admin`) succeeds; Role Changed event recorded; the user's effective permissions update (AC-006-2).
- **AC-067-2 (E2):** An unrecognized role value is rejected.

### FR-068 — Company Profile & Branding
- **AC-068-1:** Updated Company Profile fields apply to every subsequently generated document.
- **AC-068-2 (E1):** An unauthorized role cannot update Company Profile.

### FR-069 — System Preferences
- **AC-069-1:** An updated System Preference is reflected the next time a consuming module evaluates it; this module never itself executes the consuming workflow.
- **AC-069-2 (E2):** An invalid value (e.g., negative reminder interval) is rejected.

### FR-070 — Lookup & Reference Data
- **AC-070-1:** A new/edited reference value becomes available wherever that category is consumed.
- **AC-070-2:** Deactivating an in-use value preserves existing records referencing it while removing it from future selection.

### FR-071 — Audit Trail Viewing
- **AC-071-1:** An authorized role views the full Audit Trail, filterable by user/date/module/action, showing User, Timestamp, Action, Entity, and Reason where applicable.
- **AC-071-2:** No edit or delete control exists anywhere on this screen (AC-GLOBAL-IMMUTABLE, confirmed by the absence of a write endpoint in `07` §12).
- **AC-071-3 (E1):** An unauthorized role cannot view the Audit Trail.

---

## 14. Module 13 — Subscription & Storage Self-Service *(added — closes a pre-existing documentation gap, Manual Mobile-Money Subscription Payment Flow Amendment)*

> **Added 2026-08-19.** Module 13 (`03_Functional_Requirements.md` FR-077–FR-084, FR-086) was approved and retroactively documented (Subscription & Storage Self-Service Catch-Up, `03` Revision History 1.13) but this document was never updated to add its Acceptance Criteria — every FR-077–FR-084 "Acceptance Criteria References" line pointed here to nothing. Closed alongside the Manual Mobile-Money Subscription Payment Flow Amendment, which also added FR-086. FR-085 (Invoice Generation, Module 8) is a separate, pre-existing gap not touched here — out of this amendment's scope.

### FR-077 — View Subscription & Plan Catalog
- **AC-077-1:** A Business Owner viewing the Subscription screen sees their tenant's current plan, trial/subscription status, billing dates, Customer/Storage usage vs. limits, Analytics availability, and read-only state.
- **AC-077-2 (A1):** A tenant with no Subscription record at all is shown as being on the Free Plan for display purposes, not an error.
- **AC-077-3:** The Plan Catalog always shows exactly the five fixed plans (Trial, Free, Small Business, Medium Business, Corporate) with their real price, Customer Limit (or Unlimited), Storage allowance, and Analytics inclusion — never a client-invented value.

### FR-078 — Request Subscription Plan Change
- **AC-078-1:** Submitting a target plan with a Payment Phone (Payment Reference optional) creates a Subscription Change Request with status Pending; Subscription Upgrade Requested event recorded; the tenant's active plan is unchanged.
- **AC-078-2 (E2):** A submission missing Payment Phone or the requested plan is rejected with a field-level validation error; a submission missing only Payment Reference is **not** rejected (BRL-092).
- **AC-078-3 (E3):** A second submission while one is already Pending for the tenant is rejected (`409`); an Approved, Rejected, or Cancelled prior request never blocks a new submission.
- **AC-078-4 (E4):** A submission naming the tenant's current plan is rejected — there is nothing for the Deendoon Platform Administrator to approve.
- **AC-078-5:** The request never becomes anything other than Pending as a direct result of submission — activation happens only via FR-084.

### FR-079 — Subscription Change Request History & Cancellation
- **AC-079-1:** A Business Owner sees only their own tenant's Subscription Change Request history — requested plan, prior plan, status, submitted date, and, once reviewed, the decision and any Rejection Reason(s).
- **AC-079-2:** Cancelling a still-Pending request sets its status to Cancelled; the current Subscription and Plan Catalog are unaffected.
- **AC-079-3 (E2):** Cancelling a request that is no longer Pending is rejected.

### FR-080 — Storage Overview
- **AC-080-1:** The Storage screen shows current usage (bytes and GB), effective Storage Limit (base plan allowance plus every active Storage Add-on), remaining allowance, and the list of purchased Add-ons with their status.

### FR-081 — Request Storage Add-on
- **AC-081-1:** Selecting one of the four fixed packages and submitting a Payment Reference creates a Storage Add-on Request with status Pending, server-derived size/price; Storage Addon Requested event recorded.
- **AC-081-2 (E2):** A submission missing the package or Payment Reference is rejected with a field-level validation error.
- **AC-081-3 (E3):** A second submission while one is already Pending for the tenant is rejected (`409`); an Approved, Rejected, or Cancelled prior request never blocks a new one.
- **AC-081-4:** The size/price actually stored always matches the server's fixed package table, never a client-supplied value.

### FR-082 — Storage Add-on Request History & Cancellation
- **AC-082-1:** A Business Owner sees only their own tenant's Storage Add-on Request history with status, submitted date, and, once reviewed, the decision and any Rejection Reason(s).
- **AC-082-2:** Cancelling a still-Pending request sets its status to Cancelled.
- **AC-082-3 (E2):** Cancelling a request that is no longer Pending is rejected.

### FR-083 — Subscription-Driven Customer Read-Only
- **AC-083-1:** A Customer beyond the tenant's effective Customer Limit (oldest-first ordering) becomes read-only — not editable, not archivable, no document generation — while remaining fully viewable and searchable.
- **AC-083-2:** A Customer newly within the limit (e.g., after a plan upgrade, or after an over-limit Customer is archived) is restored to editable.
- **AC-083-3:** Attempting to create a new Customer while already at or over the effective limit is blocked outright, distinct from the read-only-existing-Customer behavior.
- **AC-083-4 (A1):** A tenant whose Subscription cannot be resolved at all (not even the Free Plan fallback) has every Customer read-only and cannot create a new one — fails closed, never treated as unlimited.

### FR-084 — Platform Administrator Review of Subscription & Storage Requests
- **AC-084-1:** The Deendoon Platform Administrator sees every tenant's pending (and, filtered, historical) Subscription Change Requests and Storage Add-on Requests via the Deendoon Super Admin Web Panel.
- **AC-084-2:** Approving a Subscription Change Request activates the requested plan (tenant's Subscription updated, status Active, new billing cycle) and triggers an immediate Customer read-only recalculation (FR-083); approving a Storage Add-on Request activates it with its own billing cycle. Both record a status-change event and notify the tenant's Business Owner.
- **AC-084-3:** Rejecting a request without selecting at least one predefined Rejection Reason is rejected with a validation error (E4); a valid rejection records the reason(s), any free-text notes, and notifies the Business Owner. Nothing is activated.
- **AC-084-4 (E2):** Actioning a request that is no longer Pending (already Approved/Rejected/Cancelled) is rejected.
- **AC-084-5 (E3):** Approving a Subscription Change Request whose requested plan now equals the tenant's *current* plan (changed since submission) is rejected — re-checked at approval time, not against the request's original snapshot.
- **AC-084-6:** No tenant-scoped session — including the Business Owner — can perform an approval/rejection action (`403`); only the Deendoon Platform Administrator can.

### FR-086 — Platform Payment Destination Number *(added, Manual Mobile-Money Subscription Payment Flow Amendment)*
- **AC-086-1:** The Deendoon Platform Administrator setting or updating the destination mobile-money number persists it as a single platform-level value and records the change in the Audit Trail (actor, timestamp).
- **AC-086-2:** Every Business Owner's Payment Saved / Send Money step shows the current number, fetched live — never a value baked into the app build.
- **AC-086-3 (A1):** Before any number has ever been set, the Payment Saved / Send Money step shows an explicit "not set yet" message, never a blank or placeholder number.
- **AC-086-4 (E1):** A Business Owner session attempting to set or change the number is rejected (`403`); only the Deendoon Platform Administrator can.
- **AC-086-5 (E2):** Submitting an empty value is rejected with a validation error.
- **AC-086-6:** Tapping SAALAM BANK, EVC PLUS, or E-DAHAB (opening the device dialer pre-filled with that operator's fixed USSD code) never, by itself, changes any Subscription Change Request's status — the request remains exactly Pending Verification regardless of whether the dialer opened successfully.

---

## 15. Traceability Confirmation

Every Functional Requirement from **FR-001 through FR-076** and **FR-077 through FR-084, FR-086** has at least one corresponding Acceptance Criterion above — 85 of 86 approved FRs (FR-085, Invoice Generation, is a separate pre-existing gap, out of scope for this amendment — see the note at the top of Section 14). No FR in scope was skipped; no criterion was written for a capability without an approved FR to trace to.

| Module | FR Range | AC Coverage |
|---|---|---|
| 1 — Authentication & User Session | FR-001–006 | Complete |
| 2 — Customer Management | FR-007–016 | Complete |
| 3 — Debt Register | FR-017–025 | Complete |
| 4 — Credit & Risk Management | FR-026–028 | Complete |
| 5 — Recovery Workflow | FR-029–033 | Complete |
| 6 — Payment Tracking | FR-034–039 | Complete |
| 7 — Professional Collection | FR-040–046, FR-072–076 | Complete |
| 8 — Documents | FR-047–052 | Complete (FR-085 not covered — see Section 14 note) |
| 9 — Reporting & Analytics | FR-053–057 | Complete |
| 10 — Notifications & Calendar | FR-058–062 | Complete |
| 11 — Search & Productivity | FR-063–065 | Complete |
| 12 — Administration & Settings | FR-066–071 | Complete |
| 13 — Subscription & Storage Self-Service | FR-077–084, FR-086 | Complete *(added, 2026-08-19)* |

---

## 16. Criteria Pending Business Rule Resolution

Consistent with `06`/`07`/`08`/`09`'s own registers, the following criteria are written to validate an invariant rather than a specific outcome, because the underlying `04_Business_Rules.md` Deferred Decision is unresolved:

| Criterion | Pending Decision | What's validated now | What can't be finalized yet |
|---|---|---|---|
| AC-026-1 | DD-009 (point/band thresholds) | Recalculation occurs; result stays within 0–100 | The specific resulting score for a given event sequence |
| AC-028-2 | DD-011 (re-trigger/suppression) | At least one notification per new breach | Exact repeat-breach suppression behavior |
| AC-040-2 | DD-023 (duplicate escalation) | No duplicate open Case is ever created | Whether the UX rejects or redirects |
| AC-076-2 | `06` Decisions Required (Request/Case closure coupling) | No unintended side effect on the Case | Whether closure is coupled or independent |

None of the above block this document from being usable now — each already defines a genuine pass/fail test; only the more specific follow-up criterion awaits its Business Rule.

---

**End of 10_Acceptance_Criteria.md — Awaiting review and approval.**
