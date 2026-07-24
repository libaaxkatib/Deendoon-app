# 03. Functional Requirements

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-03 |
| **Document Title** | Functional Requirements |
| **Version** | 1.4 (In Progress) |
| **Status** | Draft — Modules 1–11 Approved; Module 12 of 12 (final) Submitted for Review |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Pending |
| **Last Updated** | 2026-07-24 |
| **Scope Baseline** | `01_Project_Overview.md` (Approved) · `02_Business_Requirements.md` (Approved) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 0.1 | 2026-07-24 | Module 1 — Authentication & User Session drafted for review. | Claude |
| 0.2 | 2026-07-24 | Module 1 polish pass: clarified configurable login identifier (FR-001), added session-expiry-during-unfinished-action alternate flow (FR-003), clarified configurable recovery channel (FR-004), referenced other-session invalidation policy (FR-005), clarified permission refresh on role change (FR-006), added Related Modules column to Traceability Summary. No scope or functionality changes. | Claude |
| 0.3 | 2026-07-24 | Module 1 approved and frozen. Module 2 — Customer Management drafted for review (FR-007–FR-016). | Claude |
| 0.4 | 2026-07-24 | Module 2 polish pass: clarified Customer Status meaning/transitions are defined in `04_Business_Rules.md` (FR-012); clarified Outstanding Balance is read-only within Customer Management (FR-013); clarified partial-import behavior is intentionally deferred (Open Item #2). Module 2 approved and frozen. No scope, functionality, or traceability changes. | Claude |
| 0.5 | 2026-07-24 | Module 3 — Debt Register drafted for review (FR-017–FR-025). | Claude |
| 0.6 | 2026-07-24 | Module 3 polish pass: FR-017 no longer hardcodes initial Recovery Stage, now references Module 5 / `04_Business_Rules.md`. Module 3 approved and frozen. Module 4 — Credit & Risk Management drafted for review (FR-026–FR-028). | Claude |
| 0.7 | 2026-07-24 | Module 4 polish pass: FR-026 no longer hardcodes Credit Score point values (referenced as not-yet-formally-approved), FR-028 clarified once-per-qualifying-event notification with re-trigger/suppression deferred to `04_Business_Rules.md`. Module 4 approved and frozen. Module 5 — Recovery Workflow drafted for review (FR-029–FR-033). | Claude |
| 0.8 | 2026-07-24 | Module 5 approved and frozen. Module 6 — Payment Tracking drafted for review (FR-034–FR-039). | Claude |
| 0.9 | 2026-07-24 | Module 6 approved and frozen. Module 7 — Professional Collection drafted for review (FR-040–FR-046). | Claude |
| 1.0 | 2026-07-24 | Module 7 approved and frozen. Module 8 — Documents drafted for review (FR-047–FR-052). Included Customer Statement of Account (approved BR-021, not listed in this module's scope message but already forward-referenced by Modules 2/3) and preserved previously approved DL-000001 numbering for Legal Notice (a Demand Letter template, not a separate numbered document type) — both flagged as consistency notes rather than silently decided. | Claude |
| 1.1 | 2026-07-24 | Module 8 approved and frozen. Module 9 — Reporting & Analytics drafted for review (FR-053–FR-057). Consolidated five named report categories into one FR (no per-report detail was ever approved beyond Aging Analysis/KPI Cards); excluded Scheduled Reports as unapproved and logged as an Open Item rather than invented. | Claude |
| 1.2 | 2026-07-24 | Module 9 approved and frozen. Module 10 — Notifications & Calendar drafted for review (FR-058–FR-062). Excluded Email as an unapproved channel; scoped SMS/WhatsApp strictly to Module 5's already-approved ownership, implementing this module as in-app-only per the frozen Notification Center definition in `01_Project_Overview.md`. | Claude |
| 1.3 | 2026-07-24 | Module 10 approved and frozen. Module 11 — Search & Productivity drafted for review (FR-063–FR-065). Excluded Saved Views, Recent Activity, and Favorites as unapproved Version 1 scope; implemented Quick Actions (approved) in place of "Quick Navigation"; flagged a pre-existing traceability gap (Quick Actions has no dedicated BR in `02_Business_Requirements.md`). | Claude |
| 1.4 | 2026-07-24 | Module 11 approved and frozen. Module 12 — Administration & Settings drafted for review (FR-066–FR-071), the final module. Added FR-071 (Audit Trail Viewing) beyond the suggested numbering to close a coverage gap: BR-030 was never implemented as a viewable capability in any prior module. Corrected an erroneous "Module 13" reference in the request — Module 12 is the last of 12. | Claude |

---

## Document Purpose

This document specifies **how** Deendoon Version 1 must behave to satisfy the approved Business Requirements in `02_Business_Requirements.md`. It is organized into twelve functional modules, produced and reviewed one at a time. Each Functional Requirement (FR-xxx) traces to one or more approved Business Requirements (BR-xxx); no FR introduces functionality beyond the approved scope in `01_Project_Overview.md` §1.6.

Detailed field-level business logic is deferred to `04_Business_Rules.md`; screen-level detail is deferred to `05_UI_UX_Specification.md`; data structures to `06_Database_Design.md`; endpoint contracts to `07_API_Design.md`; role/permission matrices to `08_Security_and_RBAC.md`; testable pass/fail conditions to `10_Acceptance_Criteria.md`. References to these documents below are forward references and will be finalized when those documents are produced.

## Module Tracker

| # | Module | Status |
|---|---|---|
| 1 | Authentication & User Session | Approved |
| 2 | Customer Management | Approved |
| 3 | Debt Register | Approved |
| 4 | Credit & Risk Management | Approved |
| 5 | Recovery Workflow | Approved |
| 6 | Payment Tracking | Approved |
| 7 | Professional Collection | Approved |
| 8 | Documents | Approved |
| 9 | Reporting & Analytics | Approved |
| 10 | Notifications & Calendar | Approved |
| 11 | Search & Productivity | Approved |
| 12 | Administration & Settings | Submitted for Review |

---

# Module 1 — Authentication & User Session

## 1. Functional Overview

Authentication and session management are not a named line item in the Version 1 Feature Freeze, but they are the necessary operational foundation for two approved capabilities: Role-Based Access Control (BR-028, BR-029) cannot restrict access without first establishing *who* is acting, and the Audit Trail's approved **Login** and **Logout** event types (BR-030) cannot be recorded without an authentication event to record.

This module therefore defines the minimum functional behavior required to identify a user, establish and end a session, and resolve that user's role for use by every RBAC-gated module thereafter (Modules 2–12).

**Scope boundary:** This module defines *functional* behavior only — what the user does and what the system does in response. Security hardening detail (password complexity rules, failed-login lockout policy, token/encryption specifics, multi-session policy) belongs to `08_Security_and_RBAC.md` and `09_Non_Functional_Requirements.md` and is referenced, not restated, here.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-001 | The system shall authenticate a user by validated identifier and credential before granting access to any module. | BR-028 |
| FR-002 | The system shall allow an authenticated user to terminate their own session on demand. | BR-028, BR-030 |
| FR-003 | The system shall automatically terminate a session after a period of inactivity. | BR-028 |
| FR-004 | The system shall allow a user who cannot recall their credential to reset it through a verified recovery channel. | BR-028 |
| FR-005 | The system shall allow an authenticated user to change their own credential. | BR-028 |
| FR-006 | The system shall resolve and attach the authenticated user's assigned role and associated permissions to every session, for use by all RBAC-gated modules. | BR-028, BR-029 |

---

### FR-001 — User Login

**Preconditions**
- A user account exists, belongs to exactly one Tenant, and is not Archived (see `01_Project_Overview.md`, Tenant definition).
- The account is assigned at least one Role (per BR-029).

**Triggers**
- The user submits an identifier (email or username) and credential on the Customer Mobile App or the Deendoon Super Admin Web Panel login screen.

**Main Flow**
1. User submits identifier and credential. The identifier type (email or username) is a platform-configurable setting (see `09_Non_Functional_Requirements.md`); Version 1 does not mandate one specific identifier type over the other, but a given tenant uses one consistent, configured identifier type.
2. System validates the credential against the stored account record.
3. System confirms the account is active (not Archived).
4. System resolves the user's assigned Role and permissions (FR-006).
5. System establishes an authenticated session.
6. System records a **Login** event in the Audit Trail (User, Timestamp, Action = Login).
7. User is directed to the landing view appropriate to their role and client (Customer Mobile App for business-side roles; Super Admin Web Panel for the Platform Administrator role).

**Alternate Flows**
- **A1 — Invalid credential:** System rejects the attempt, does not establish a session, and does not record a Login event. Detailed lockout/rate-limiting behavior is specified in `08_Security_and_RBAC.md`.
- **A2 — Account archived:** System rejects the attempt with a message indicating the account is not active; no session is established.

**Exceptions**
- **E1 — System unavailable during authentication:** The request fails without establishing a partial or invalid session; the user may safely retry.

**Business Rule References:** BRL-003 (attributable action) — detailed in `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /auth/login` — see `07_API_Design.md`.
**Related Database Entities (reference only):** User, Role, Session, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-001.

---

### FR-002 — User Logout

**Preconditions**
- User holds an active, authenticated session.

**Triggers**
- User selects the Logout action.

**Main Flow**
1. User initiates logout.
2. System invalidates the current session.
3. System records a **Logout** event in the Audit Trail (User, Timestamp, Action = Logout).
4. User is returned to the login screen.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Logout requested on an already-expired session:** System treats this as a no-op and returns the user to the login screen without error.

**Business Rule References:** BRL-003 — detailed in `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /auth/logout` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Session, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-002.

---

### FR-003 — Session Expiry (Timeout)

**Preconditions**
- User holds an active, authenticated session.

**Triggers**
- The session's idle duration exceeds the configured timeout threshold (threshold value defined in `09_Non_Functional_Requirements.md`).

**Main Flow**
1. System detects that session inactivity has exceeded the configured threshold.
2. System invalidates the session.
3. On the user's next action, system redirects to the login screen and requires re-authentication (FR-001).

**Alternate Flows**
- **A1 — User is actively using the system:** The idle timer resets on each authenticated action (sliding-window expiry); the session remains valid.
- **A2 — Session expires during an unfinished user action (e.g., mid-form entry):** The in-progress action is not committed. The user is required to re-authenticate (FR-001) before the action can be resubmitted; no partial or inconsistent record is created as a result of the expired session.

**Exceptions**
- None beyond FR-001 exceptions upon re-authentication.

**Business Rule References:** Detailed timeout threshold and configurability governed in `09_Non_Functional_Requirements.md`.
**Related APIs (reference only):** Session validation is enforced on every authenticated request — see `07_API_Design.md`.
**Related Database Entities (reference only):** Session — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-003.

---

### FR-004 — Forgot Password / Password Reset

**Preconditions**
- A user account exists with a verified recovery contact on file, via whichever recovery channel(s) the platform is configured to support (e.g., email, SMS, or other supported channel — see `09_Non_Functional_Requirements.md`).

**Triggers**
- User selects "Forgot Password" and submits their identifier.

**Main Flow**
1. User requests a password reset via their registered identifier.
2. System issues a time-limited, single-use reset token to the account's verified recovery contact, delivered via the platform-configured recovery channel.
3. User submits a new credential together with the reset token.
4. System validates the token, updates the stored credential, and invalidates the token.
5. System records the change as an **Edited** event in the Audit Trail against the User entity (Section 04 defines exactly which fields constitute an auditable edit); this reuses the approved "Edited" audit event type rather than introducing a new one.

**Alternate Flows**
- **A1 — Token expired or already used:** System rejects the reset attempt and instructs the user to request a new token.

**Exceptions**
- **E1 — Recovery contact undeliverable:** Reset cannot proceed; user is directed to contact an administrator (see Module 12 — Administration & Settings, not yet drafted).

**Business Rule References:** BRL-003 — detailed in `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /auth/forgot-password`, `POST /auth/reset-password` — see `07_API_Design.md`.
**Related Database Entities (reference only):** User, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-004.

---

### FR-005 — Change Password (Authenticated)

**Preconditions**
- User holds an active, authenticated session.

**Triggers**
- User selects "Change Password" from their account settings and submits their current and new credential.

**Main Flow**
1. User submits current credential and desired new credential.
2. System validates the current credential.
3. System updates the stored credential.
4. System records the change as an **Edited** event in the Audit Trail against the User entity.
5. Other active sessions for the same account are invalidated per the session-invalidation policy governed in `08_Security_and_RBAC.md`.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Current credential does not match:** System rejects the change; stored credential remains unchanged.

**Business Rule References:** BRL-003 — detailed in `04_Business_Rules.md`. Other-session invalidation policy governed in `08_Security_and_RBAC.md`.
**Related APIs (reference only):** `POST /auth/change-password` — see `07_API_Design.md`.
**Related Database Entities (reference only):** User, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-005.

---

### FR-006 — Role & Permission Resolution on Login

**Preconditions**
- User account is assigned exactly the role(s) granted by an authorized administrator (see Module 12 and `08_Security_and_RBAC.md`).

**Triggers**
- Successful completion of FR-001 (Login), or resumption of a valid session on any authenticated request.

**Main Flow**
1. System retrieves the user's assigned Role.
2. System retrieves the permission set associated with that Role.
3. System attaches the resolved Role and permission set to the session context.
4. Every subsequent module (2–12) consults this session context to determine what the user may view or do.

**Alternate Flows**
- **A1 — Role assignment changes while a session is active:** Permission resolution is refreshed to reflect the updated role assignment; the session context is updated so the user's effective permissions never remain stale relative to the last-assigned role. Exact refresh timing (e.g., next request vs. immediate invalidation) is governed in `08_Security_and_RBAC.md`.

**Exceptions**
- **E1 — User has no assigned role:** Access is denied to all role-gated modules until an administrator assigns a role (see Module 12).

**Business Rule References:** BRL-002 (role-restricted actions), detailed role/permission matrix in `08_Security_and_RBAC.md`.
**Related APIs (reference only):** `GET /auth/me` (or equivalent session-context endpoint) — see `07_API_Design.md`.
**Related Database Entities (reference only):** User, Role, Permission — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-006.

---

## Module 1 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-001 | BR-028 | Module 12 (Administration & Settings — account status/role assignment); Module 8 (Documents — Audit Trail consumer, forward reference) |
| FR-002 | BR-028, BR-030 | — |
| FR-003 | BR-028 | Module 9 (Reporting & Analytics — session-bound report/export actions) |
| FR-004 | BR-028 | Module 12 (Administration & Settings — recovery-channel configuration) |
| FR-005 | BR-028 | Module 12 (Administration & Settings — session/security policy configuration) |
| FR-006 | BR-028, BR-029 | Modules 2–12 (all RBAC-gated modules consume resolved role/permissions); Module 12 (Administration & Settings — role assignment source) |

---

**End of Module 1.** Approved.

---

# Module 2 — Customer Management

## 1. Functional Overview

Customer Management defines the lifecycle of the **Customer** entity — the business's own debtor, referenced throughout the rest of this SRS (Debt Register, Recovery Workflow, Payment Tracking, Professional Collection, Reporting). This module governs how a Customer record is created, viewed, updated, archived/restored, how its Status is managed, how its Credit Profile is displayed and maintained, and how duplication, search, and bulk import are handled.

As with Authentication in Module 1, the ability to create and maintain a Customer record is not itself a separately numbered Business Requirement — it is the necessary precondition for BR-001 through BR-007, each of which describes a capability "for each customer" (Credit Limit, Credit Score, Risk Level, Customer Status) that cannot exist without a Customer record to attach to. This module supplies that foundation.

**Scope boundary:**
- Credit Score calculation logic and the Credit Limit soft-warning behavior triggered *at debt entry* are specified in **Module 3 — Debt Register** and **Module 4 — Credit & Risk Management**, not restated here. This module covers only the Credit Profile's display and direct maintenance (e.g., setting the Credit Limit) at the Customer level.
- The full cross-module Global Search and Advanced Search & Filters architecture is specified in **Module 11 — Search & Productivity**. This module specifies only the Customer-scoped application of that capability.
- Role/permission matrices are specified in `08_Security_and_RBAC.md` and Module 12 — Administration & Settings; this module references permission checks but does not define the permission model itself.

**Design clarification:** The approved Feature Freeze specifies that Recovery Stage and Credit Score are explicitly rule-driven/automated (BR-009, BR-004). No equivalent automation was specified for **Customer Status** — it is therefore treated in this module as a manually managed field, set by an authorized user, rather than a system-derived value. This is the more conservative reading and does not introduce automation beyond approved scope; if an automated Customer Status derivation is intended, that would be a scope addition requiring your confirmation.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-007 | The system shall allow an authorized user to create a new Customer record, applying Duplicate Customer Detection and the tenant's configured Default Credit Limit where applicable. | BR-001, BR-003, BR-004, BR-005, BR-006, BR-034, BR-038 |
| FR-008 | The system shall allow an authorized user to view a Customer's full profile, including Credit Limit, Outstanding Balance, Remaining Credit, Risk Level, Credit Score, and Customer Status. | BR-003, BR-004, BR-005, BR-006 |
| FR-009 | The system shall allow an authorized user to update an existing Customer record. | BR-003, BR-006, BR-030 |
| FR-010 | The system shall allow an authorized user to archive a Customer record without permanently deleting it. | BR-031 |
| FR-011 | The system shall allow an authorized user to restore a previously archived Customer record. | BR-032 |
| FR-012 | The system shall allow an authorized user to manually set a Customer's Status from the approved value set. | BR-006 |
| FR-013 | The system shall display and allow authorized maintenance of a Customer's Credit Profile (Credit Limit, Outstanding Balance, Remaining Credit, Risk Level, Credit Score). | BR-001, BR-003, BR-004, BR-005 |
| FR-014 | The system shall detect likely duplicate Customers by phone number and name at creation and import time, without blocking the user. | BR-038 |
| FR-015 | The system shall allow an authorized user to search and filter Customers by name, phone, status, risk level, and credit score. | BR-026, BR-027 |
| FR-016 | The system shall allow an authorized user to bulk-import Customer records from an Excel file, with per-row duplicate handling. | BR-037, BR-038 |

---

### FR-007 — Customer Creation

**Preconditions**
- User is authenticated (Module 1) and holds a role permitted to create Customers.

**Triggers**
- User initiates "Add Customer" and submits customer details.

**Main Flow**
1. User submits customer details (name, phone number, and any additional fields defined in `06_Database_Design.md`), optionally including an explicit Credit Limit.
2. System performs Duplicate Customer Detection (FR-014) against existing active Customers by phone number and name.
3. If no likely duplicate is found, system proceeds to step 5.
4. If a likely duplicate is found, system presents the match and requires the user to explicitly choose "Open Existing Customer" or "Continue Anyway" before proceeding.
5. System creates the Customer record with Customer Status defaulted to **Active**.
6. If no explicit Credit Limit was provided, system applies the tenant's configured Default Credit Limit (Module 12 — System Settings; BR-034).
7. System records a **Created** event in the Audit Trail (User, Timestamp, Action = Created, Entity = Customer).
8. User is directed to the new Customer's Details view (FR-008).

**Alternate Flows**
- **A1 — Explicit Credit Limit provided:** The submitted value overrides the tenant default; step 6 does not apply.
- **A2 — User selects "Continue Anyway" after a duplicate warning:** The new Customer record is created as a distinct record; both records remain independently active.

**Exceptions**
- **E1 — Required fields missing or invalid:** System rejects submission with field-level validation errors; no record is created.
- **E2 — User lacks permission to create Customers:** Action is not available (RBAC, `08_Security_and_RBAC.md`).

**Business Rule References:** BRL-005 (duplicate detection is advisory, never blocking); BC-003 (default values are configurable, not hardcoded).
**Related APIs (reference only):** `POST /customers` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, AuditLog, SystemSettings (Default Credit Limit) — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-007.

---

### FR-008 — Customer Details

**Preconditions**
- Customer record exists (Active or Archived); user holds permission to view Customer records.

**Triggers**
- User selects a Customer from a list, search result, or direct reference.

**Main Flow**
1. User selects a Customer.
2. System retrieves and displays the Customer Profile: identifying details, Credit Limit, Outstanding Balance, Remaining Credit, Risk Level, Credit Score, and Customer Status (BR-003, BR-004, BR-005, BR-006), together with associated Notes & Attachments and document-generation actions (Module 8, reference only).
3. If the Customer is Archived, system displays the record in a restore-eligible state per BR-032.

**Alternate Flows**
- **A1 — Requesting user's role restricts field-level visibility:** System displays only the fields permitted for that role (e.g., Viewer), per `08_Security_and_RBAC.md`.

**Exceptions**
- **E1 — User lacks permission to view this Customer:** Access is denied.

**Business Rule References:** BRL-004 (archived records remain retrievable, subject to permissions); BRL-006 (Risk Level, Credit Score, Customer Status, Debt Status are independently maintained).
**Related APIs (reference only):** `GET /customers/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, Role, Permission — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-008.

---

### FR-009 — Customer Update

**Preconditions**
- Customer record exists and is not Archived (an Archived Customer must be restored first — FR-011); user holds edit permission.

**Triggers**
- User selects "Edit" on a Customer Profile and submits changed fields.

**Main Flow**
1. User submits updated customer details.
2. System validates the submitted data.
3. If identifying fields (name or phone) changed, system re-runs Duplicate Customer Detection (FR-014) under the same advisory, non-blocking pattern as FR-007.
4. System saves the updated record.
5. System records the change in the Audit Trail using the applicable approved event type: **Credit Limit Changed** if the Credit Limit field was modified, **Edited** for all other field changes (precise field-to-event mapping detailed in `04_Business_Rules.md`).

**Alternate Flows**
- **A1 — Update includes a Credit Limit change:** Handled per Main Flow step 5; Remaining Credit is recalculated immediately (see FR-013).

**Exceptions**
- **E1 — Required fields missing or invalid:** System rejects the update; no changes are saved.
- **E2 — User lacks permission to edit:** Action is not available.

**Business Rule References:** BRL-005 (duplicate re-check); BRL-006 (independent field maintenance).
**Related APIs (reference only):** `PUT /customers/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-009.

---

### FR-010 — Customer Archive

**Preconditions**
- Customer record exists and is not already Archived; user holds archive permission.

**Triggers**
- User selects "Archive" (Delete) on a Customer.

**Main Flow**
1. User initiates Archive on a Customer.
2. System evaluates any archive-eligibility conditions defined in `04_Business_Rules.md` (see open item noted at the end of this module regarding Customers with outstanding Debts).
3. System archives the record; it is excluded from default operational lists and dashboards.
4. System records an **Archived** event in the Audit Trail (User, Timestamp, Action = Archived, Entity = Customer).
5. The Customer remains retrievable via Search and Reports, subject to role permissions (BRL-004).

**Alternate Flows**
- None identified beyond the eligibility evaluation in step 2.

**Exceptions**
- **E1 — User lacks permission to archive:** Action is not available.
- **E2 — Customer already Archived:** Action is not offered (no-op).

**Business Rule References:** BC-002 (financial records never permanently deleted); BRL-004.
**Related APIs (reference only):** `POST /customers/{id}/archive` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-010.

---

### FR-011 — Customer Restore

**Preconditions**
- Customer record exists and is currently Archived; user holds restore permission.

**Triggers**
- User selects "Restore" on an archived Customer, located via Search (BRL-004).

**Main Flow**
1. User initiates Restore.
2. System reactivates the Customer record into default operational lists and dashboards.
3. System records a **Restored** event in the Audit Trail (User, Timestamp, Action = Restored, Entity = Customer).

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks permission to restore:** Action is not available.
- **E2 — Customer is not currently Archived:** Action is not offered (no-op).

**Business Rule References:** BC-002; BRL-004.
**Related APIs (reference only):** `POST /customers/{id}/restore` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-011.

---

### FR-012 — Customer Status Management

**Preconditions**
- Customer record exists and is not Archived; user holds permission to change Customer Status.

**Triggers**
- Authorized user selects a new Customer Status from the approved value set: Active, Good Standing, Late Payer, High Risk, In Collection, Recovered, Blocked.

**Main Flow**
1. User selects a new Customer Status.
2. System validates the value against the approved status set.
3. System updates the Customer's Status.
4. System records a **Status Changed** event in the Audit Trail (User, Timestamp, Action = Status Changed, Entity = Customer).

**Alternate Flows**
- None beyond the general update path.

**Exceptions**
- **E1 — Invalid or unrecognized status value submitted:** System rejects the change.
- **E2 — User lacks permission:** Action is not available.

**Business Rule References:** BRL-006 (Customer Status is independently maintained from Risk Level, Credit Score, and Debt Status). See also the Design Clarification in Section 1 regarding the manual (non-automated) nature of this field in Version 1. The meaning, transition rules, and allowed usage of each Customer Status value (Active, Good Standing, Late Payer, High Risk, In Collection, Recovered, Blocked) are defined in `04_Business_Rules.md`; this module defines only the functional behavior of setting and recording a status change.
**Related APIs (reference only):** `PATCH /customers/{id}/status` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-012.

---

### FR-013 — Credit Profile

**Preconditions**
- Customer record exists; user holds view permission (all fields) or edit permission (Credit Limit only).

**Triggers**
- User views a Customer Profile, or an authorized user updates the Customer's Credit Limit.

**Main Flow**
1. System displays Credit Limit, Outstanding Balance, Remaining Credit, Risk Level, and Credit Score on the Customer Profile (BR-001, BR-003, BR-004, BR-005). Outstanding Balance is **read-only** within Customer Management: it is maintained exclusively by Module 3 — Debt Register (new debt) and Module 6 — Payment Tracking (payments), and is only ever displayed, never directly edited, here.
2. Remaining Credit is computed as Credit Limit minus Outstanding Balance.
3. An authorized user may update the Credit Limit.
4. System recalculates Remaining Credit immediately upon any change to Credit Limit or Outstanding Balance.
5. System records a **Credit Limit Changed** event in the Audit Trail when the Credit Limit is modified.

**Alternate Flows**
- **A1 — Outstanding Balance changes due to new debt or payment activity (Modules 3/6):** Remaining Credit is recalculated automatically; no direct user action is required on the Customer Profile.

**Exceptions**
- **E1 — Credit Limit update attempted by a user without edit permission:** Rejected.
- **E2 — Negative or non-numeric Credit Limit submitted:** Rejected with a validation error.

**Business Rule References:** BRL-006. The Credit Limit soft-warning behavior at debt entry is specified in Module 3 — Debt Register; Credit Score calculation logic is specified in Module 4 — Credit & Risk Management (not restated here).
**Related APIs (reference only):** `GET /customers/{id}/credit-profile`, `PATCH /customers/{id}/credit-limit` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-013.

---

### FR-014 — Duplicate Customer Detection

**Preconditions**
- None; this check runs automatically as part of FR-007 (Creation) and FR-016 (Import).

**Triggers**
- A new Customer submission, or a Customer Import row, containing a phone number and/or name.

**Main Flow**
1. System checks the submitted phone number and name against existing active Customer records.
2. If a likely match is found, system displays: "This customer may already exist."
3. System offers the user a choice: **Open Existing Customer** or **Continue Anyway**.
4. The user's choice determines whether a new record is created or the flow is redirected to the existing record.

**Alternate Flows**
- **A1 — No match found:** Flow proceeds directly to record creation or import-row acceptance without interruption.

**Exceptions**
- None. This check never blocks a user from proceeding (BRL-005).

**Business Rule References:** BRL-005 (advisory, non-blocking).
**Related APIs (reference only):** Duplicate check embedded within `POST /customers` and `POST /customers/import` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-014.

---

### FR-015 — Customer Search

**Preconditions**
- User is authenticated with view permission on Customer Management.

**Triggers**
- User enters a search term or applies filters within Customer Management.

**Main Flow**
1. User enters a search term (name, phone) or selects filters (Customer Status, Risk Level, Credit Score range).
2. System returns matching Customer records the user is permitted to view.
3. Results exclude Archived Customers by default (BRL-004).

**Alternate Flows**
- **A1 — User explicitly includes Archived Customers in the search scope:** Matching archived records are included, subject to permission.

**Exceptions**
- **E1 — No matches found:** System displays an empty-result state.

**Business Rule References:** BRL-004. This FR specifies only the Customer-scoped application of search/filtering; the full cross-module Global Search and Advanced Search & Filters architecture is specified in Module 11 — Search & Productivity.
**Related APIs (reference only):** `GET /customers?search=&status=&riskLevel=&creditScoreMin=&creditScoreMax=` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-015.

---

### FR-016 — Customer Import

**Preconditions**
- User holds import permission; a well-formed Excel file is available.

**Triggers**
- User selects "Import Customers" and uploads an Excel file.

**Main Flow**
1. User uploads an Excel file.
2. System parses the file and presents a Preview of the data to be imported.
3. System validates each row (required fields, data types).
4. System checks each row against existing Customers using Duplicate Customer Detection (FR-014).
5. For each detected duplicate, system presents the user a per-row choice: **Skip Duplicate**, **Update Existing**, or **Import as New**.
6. User confirms the import.
7. System creates or updates Customer records accordingly and records a **Created** or **Edited** event in the Audit Trail for each affected record.

**Alternate Flows**
- **A1 — User cancels after Preview, before confirming:** No records are created or modified.
- **A2 — File contains rows that fail validation:** System reports which rows failed; exact partial-import behavior (proceed with valid rows vs. reject the batch) is confirmed in `04_Business_Rules.md` — see open item below.

**Exceptions**
- **E1 — File format unsupported or corrupted:** Import is rejected before Preview.
- **E2 — User lacks import permission:** Action is not available.

**Business Rule References:** BRL-005 (duplicate handling); detailed field-validation rules in `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /customers/import` (upload + preview), `POST /customers/import/{batchId}/commit` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, ImportBatch, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-016.

---

## Module 2 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-007 | BR-001, BR-003, BR-004, BR-005, BR-006, BR-034, BR-038 | Module 3 (Debt Register); Module 12 (System Settings — Default Credit Limit) |
| FR-008 | BR-003, BR-004, BR-005, BR-006 | Module 4 (Credit & Risk Management); Module 8 (Documents) |
| FR-009 | BR-003, BR-006, BR-030 | Module 4 (Credit & Risk Management) |
| FR-010 | BR-031 | Module 11 (Search & Productivity — archived-record retrieval) |
| FR-011 | BR-032 | Module 11 (Search & Productivity) |
| FR-012 | BR-006 | Module 5 (Recovery Workflow — Status interplay with Recovery Stage) |
| FR-013 | BR-001, BR-003, BR-004, BR-005 | Module 3 (Debt Register — Outstanding Balance source); Module 4 (Credit & Risk Management — Credit Score, soft-limit warning) |
| FR-014 | BR-038 | Module 12 (Administration & Settings — matching sensitivity configuration, if any) |
| FR-015 | BR-026, BR-027 | Module 11 (Search & Productivity) |
| FR-016 | BR-037, BR-038 | Module 12 (Administration & Settings — import permission) |

---

## Open Items Identified During Module 2 Specification

The following were not explicitly addressed in the approved Feature Freeze or Business Requirements. They are flagged here for your decision rather than resolved unilaterally, per your standing instruction to report rather than redesign:

1. **Archiving a Customer with outstanding, unresolved Debts (FR-010):** The approved scope does not state whether this should be permitted, blocked, or warned. Main Flow currently defers this to `04_Business_Rules.md` without presuming an answer.
2. **Partial-import validation failure behavior (FR-016, A2):** The approved scope does not state whether a batch with some invalid rows should import the valid rows and report the rest, or reject the entire batch. Deferred to `04_Business_Rules.md`. This Functional Requirements document intentionally does not prescribe partial-import behavior until that decision is finalized in Business Rules.

Neither item changes Version 1 scope — they are implementation-level decisions needed to make FR-010 and FR-016 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 2.** Approved.

---

# Module 3 — Debt Register

## 1. Functional Overview

The Debt Register is the core record of what a Customer owes. Every other recovery capability in this SRS — reminders, recovery workflow, payment tracking, professional collection, reporting — operates on the Debt records created and maintained here. This module governs Debt creation (including the advisory Credit Limit warning at the point of new debt), Debt Details viewing, Debt Update, Debt Status tracking, Debt Archive/Restore, Recovery Timeline display, and Recovery Stage as it appears on the Debt record.

**Scope boundary:**
- The Credit Limit warning shown when adding a new debt is specified functionally in this module (FR-018), but the underlying Credit Score/Risk Level computations that inform risk assessment are specified in Module 4 — Credit & Risk Management.
- Recovery Stage *progression logic* (which events advance which stage, and the automation engine driving it) is specified in Module 5 — Recovery Workflow. This module defines only how Recovery Stage and the Recovery Timeline are displayed and manually overridden on the Debt Details screen.
- Auto Numbering's generation mechanics are common platform infrastructure; this module specifies only that a Debt receives its identifier at creation (BR-036), not the numbering service itself (deferred to `06_Database_Design.md`).

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-017 | The system shall allow an authorized user to create a new Debt record against a Customer, assigning it a unique Auto Numbering identifier. | BR-036 |
| FR-018 | The system shall warn the user when a new Debt would cause a Customer's total exposure to exceed their approved Credit Limit, without blocking the action. | BR-001, BR-002, BR-003 |
| FR-019 | The system shall allow an authorized user to view full Debt Details, including Debt Status, Recovery Stage, and Recovery Timeline. | BR-008, BR-009, BR-010 |
| FR-020 | The system shall allow an authorized user to update an existing Debt record's non-financial details. | BR-008, BR-030 |
| FR-021 | The system shall track and display the financial state of each Debt (Draft, Pending, Overdue, Partial Paid, Paid, Cancelled, Written Off). | BR-008 |
| FR-022 | The system shall allow an authorized user to archive a Debt record without permanently deleting it. | BR-031 |
| FR-023 | The system shall allow an authorized user to restore a previously archived Debt record. | BR-032 |
| FR-024 | The system shall display the chronological Recovery Timeline of a Debt on the Debt Details screen. | BR-010 |
| FR-025 | The system shall display the current Recovery Stage of a Debt and allow an authorized user to override it with a recorded reason. | BR-009, BR-015 |

---

### FR-017 — Debt Creation

**Preconditions**
- The Customer against whom the Debt is being created exists and is not Archived (Module 2).
- User is authenticated and holds permission to create Debts.

**Triggers**
- User initiates "Add Debt" against a specific Customer and submits debt details (amount, due date, and any additional fields defined in `06_Database_Design.md`).

**Main Flow**
1. User submits debt details against a selected Customer.
2. System calculates the Customer's prospective total exposure (existing Outstanding Balance + new Debt amount) and invokes the Credit Limit check (FR-018).
3. System creates the Debt record with Debt Status defaulted to **Pending** (or **Draft**, per the exact default confirmed in `04_Business_Rules.md`). The system assigns the initial Recovery Stage according to the approved Recovery Workflow rules defined in Module 5 and `04_Business_Rules.md`; this module does not prescribe that initial value.
4. System assigns a unique Auto Numbering identifier to the Debt (`DBT-000001` format).
5. System records a **Created** event in the Audit Trail (User, Timestamp, Action = Created, Entity = Debt).
6. Customer's Outstanding Balance and Remaining Credit are recalculated (Module 2, FR-013).
7. User is directed to the new Debt's Details view (FR-019).

**Alternate Flows**
- **A1 — Credit Limit would be exceeded:** Handled per FR-018; user may proceed or cancel.

**Exceptions**
- **E1 — Required fields missing or invalid (e.g., negative amount, invalid due date):** System rejects submission with field-level validation errors; no record is created.
- **E2 — User lacks permission to create Debts:** Action is not available.
- **E3 — Referenced Customer is Archived:** System rejects the action; the Customer must be restored first (Module 2, FR-011).

**Business Rule References:** BC-001 (Credit Limit enforcement is advisory only); exact default Debt Status at creation confirmed in `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /customers/{id}/debts` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, Customer, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-017.

---

### FR-018 — Credit Limit Soft Warning at Debt Entry

**Preconditions**
- Customer has an approved Credit Limit (Module 2, FR-013).

**Triggers**
- New Debt submission (FR-017) where Outstanding Balance + New Debt amount exceeds the Customer's Credit Limit.

**Main Flow**
1. System calculates Outstanding Balance + New Debt amount.
2. If the total exceeds the Credit Limit, system displays a Soft Warning: "⚠ Credit Limit Reached — This customer has exceeded the approved credit limit," showing the Credit Limit and the prospective Outstanding total.
3. System presents two options: **Continue Anyway** or **Cancel**.
4. If the user selects Continue Anyway, Debt creation proceeds (FR-017 resumes).
5. If the user selects Cancel, Debt creation is abandoned; no record is created.

**Alternate Flows**
- **A1 — Total does not exceed Credit Limit:** No warning is shown; Debt creation proceeds directly.

**Exceptions**
- None. This check never blocks the user from proceeding (BC-001) — Cancel is the user's own choice, not a system-imposed block.

**Business Rule References:** BC-001 (soft limit only, system never blocks); BRL-001.
**Related APIs (reference only):** Warning evaluation embedded within `POST /customers/{id}/debts` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, Debt — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-018.

---

### FR-019 — Debt Details

**Preconditions**
- Debt record exists (Active or Archived); user holds view permission.

**Triggers**
- User selects a Debt from a Customer's profile, a list, or a search result.

**Main Flow**
1. User selects a Debt.
2. System displays Debt Details: amount, due date, Debt Status, Recovery Stage, Recovery Timeline, and any Notes & Attachments (Module 8, reference only).
3. If the Debt is Archived, system displays it in a restore-eligible state (FR-023).

**Alternate Flows**
- **A1 — Requesting user's role restricts field-level visibility:** System displays only the fields permitted for that role.

**Exceptions**
- **E1 — User lacks permission to view this Debt:** Access is denied.

**Business Rule References:** BRL-004; BRL-006.
**Related APIs (reference only):** `GET /debts/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, Customer — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-019.

---

### FR-020 — Debt Update

**Preconditions**
- Debt record exists and is not Archived; user holds edit permission.

**Triggers**
- User selects "Edit" on a Debt and submits changed non-financial details (e.g., due date, notes).

**Main Flow**
1. User submits updated debt details.
2. System validates the submitted data.
3. System saves the update.
4. System records an **Edited** event in the Audit Trail (User, Timestamp, Action = Edited, Entity = Debt).

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Required fields missing or invalid:** System rejects the update.
- **E2 — User lacks permission to edit:** Action is not available.

**Business Rule References:** BRL-006. Financial-state transitions (Debt Status) are governed separately by FR-021 and Module 6 — Payment Tracking, not by this general-purpose update.
**Related APIs (reference only):** `PUT /debts/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-020.

---

### FR-021 — Debt Status Tracking

**Preconditions**
- Debt record exists.

**Triggers**
- A qualifying event occurs: due date passes (→ Overdue), a payment is recorded (→ Partial Paid or Paid, per Module 6), or an authorized user manually sets Cancelled or Written Off.

**Main Flow**
1. System (or an authorized user, for Cancelled/Written Off) determines the applicable Debt Status transition.
2. System updates the Debt Status field.
3. System records a **Status Changed** event in the Audit Trail (User or "System", Timestamp, Action = Status Changed, Entity = Debt).

**Alternate Flows**
- **A1 — Status changes automatically (due date passage, payment recording):** No user action is required; the triggering module (Module 6 — Payment Tracking, or the scheduled due-date evaluation) initiates the change.
- **A2 — Status changes manually (Cancelled, Written Off):** Requires an authorized role; exact role restrictions defined in `08_Security_and_RBAC.md`.

**Exceptions**
- **E1 — Attempted manual transition to a system-controlled status (e.g., manually forcing "Paid" without a recorded payment):** Rejected; Paid status is only reachable through Module 6 — Payment Tracking. Exact transition matrix confirmed in `04_Business_Rules.md`.

**Business Rule References:** BRL-006; full Debt Status transition matrix in `04_Business_Rules.md`.
**Related APIs (reference only):** `PATCH /debts/{id}/status` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-021.

---

### FR-022 — Debt Archive

**Preconditions**
- Debt record exists and is not already Archived; user holds archive permission.

**Triggers**
- User selects "Archive" (Delete) on a Debt.

**Main Flow**
1. User initiates Archive on a Debt.
2. System archives the record; it is excluded from default operational lists and dashboards.
3. System records an **Archived** event in the Audit Trail.
4. The Debt remains retrievable via Search and Reports, subject to role permissions (BRL-004).

**Alternate Flows**
- None identified.

**Exceptions**
- **E1 — User lacks permission to archive:** Action is not available.
- **E2 — Debt already Archived:** Action is not offered (no-op).

**Business Rule References:** BC-002; BRL-004.
**Related APIs (reference only):** `POST /debts/{id}/archive` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-022.

---

### FR-023 — Debt Restore

**Preconditions**
- Debt record exists and is currently Archived; user holds restore permission.

**Triggers**
- User selects "Restore" on an archived Debt, located via Search (BRL-004).

**Main Flow**
1. User initiates Restore.
2. System reactivates the Debt record into default operational lists and dashboards.
3. System records a **Restored** event in the Audit Trail.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks permission to restore:** Action is not available.
- **E2 — Debt is not currently Archived:** Action is not offered (no-op).

**Business Rule References:** BC-002; BRL-004.
**Related APIs (reference only):** `POST /debts/{id}/restore` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-023.

---

### FR-024 — Recovery Timeline Display

**Preconditions**
- Debt record exists; user holds view permission.

**Triggers**
- User opens the Debt Details screen.

**Main Flow**
1. System aggregates all recovery-related events for the Debt: Debt Created, WhatsApp Reminder, SMS Reminder, Phone Call, Promise to Pay, Payment, Professional Collection, Recovered — drawn from Follow-up History, Payment Tracking, and Recovery Stage data (Modules 5, 6, 7).
2. System renders these events as a chronological, read-only visual stepper on the Debt Details screen.

**Alternate Flows**
- **A1 — Not all timeline stages have occurred yet:** Only completed/reached stages are shown as fulfilled; remaining stages are shown as pending.

**Exceptions**
- None; this is a read-only aggregation with no independent write path (per the Product Principle that Recovery Timeline is a view, not a system of record).

**Business Rule References:** None beyond those governing the underlying source data (Modules 5, 6, 7).
**Related APIs (reference only):** `GET /debts/{id}/timeline` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, FollowUpHistory, Payment, CollectionCase — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-024.

---

### FR-025 — Recovery Stage Display & Override

**Preconditions**
- Debt record exists; user holds view permission (display) or override permission (change).

**Triggers**
- User opens the Debt Details screen (display), or an authorized user initiates a manual stage override.

**Main Flow**
1. System displays the Debt's current Recovery Stage (Stage 1–6) on the Debt Details screen.
2. Recovery Stage is normally advanced automatically by the Business Rule Recovery Automation engine (Module 5 — Recovery Workflow); this module does not restate that progression logic.
3. An authorized user may override the current stage, providing a mandatory Reason.
4. System records the override with User, Timestamp, and Reason.
5. System records a **Recovery Stage Override** event in the Audit Trail.

**Alternate Flows**
- None beyond the automated-vs-manual distinction in step 2–3.

**Exceptions**
- **E1 — Override attempted without a Reason:** Rejected; Reason is mandatory (BR-015).
- **E2 — User lacks override permission:** Action is not available (restricted to authorized roles per `08_Security_and_RBAC.md`).

**Business Rule References:** BRL-002 (override requires recorded reason, restricted to authorized roles); full stage-advancement rule set specified in Module 5 — Recovery Workflow and `04_Business_Rules.md`.
**Related APIs (reference only):** `PATCH /debts/{id}/recovery-stage` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-025.

---

## Module 3 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-017 | BR-036 | Module 2 (Customer Management — Outstanding Balance impact) |
| FR-018 | BR-001, BR-002, BR-003 | Module 2 (Customer Management — Credit Profile); Module 4 (Credit & Risk Management) |
| FR-019 | BR-008, BR-009, BR-010 | Module 5 (Recovery Workflow); Module 8 (Documents) |
| FR-020 | BR-008, BR-030 | — |
| FR-021 | BR-008 | Module 6 (Payment Tracking — Paid/Partial Paid transitions) |
| FR-022 | BR-031 | Module 11 (Search & Productivity) |
| FR-023 | BR-032 | Module 11 (Search & Productivity) |
| FR-024 | BR-010 | Module 5 (Recovery Workflow); Module 6 (Payment Tracking); Module 7 (Professional Collection) |
| FR-025 | BR-009, BR-015 | Module 5 (Recovery Workflow) |

---

## Open Items Identified During Module 3 Specification

1. **Default Debt Status at creation (FR-017):** The Feature Freeze lists both "Draft" and "Pending" as valid Debt Status values but does not specify which applies immediately upon creation. Deferred to `04_Business_Rules.md`; not assumed here.
2. **Manual transition restrictions for Cancelled/Written Off (FR-021):** Which roles may apply these manual transitions is deferred to `08_Security_and_RBAC.md` rather than assumed in this module.

Neither item changes Version 1 scope.

---

**End of Module 3.** Approved.

---

# Module 4 — Credit & Risk Management

## 1. Functional Overview

This module specifies the computation and management of the two customer-level risk signals introduced during Version 1 discovery: the quantitative **Credit Score** and the qualitative **Risk Level**, together with the **Credit Limit Reached** notification trigger. Both signals are *displayed* on the Customer Profile (Module 2, FR-013); this module specifies how their values are produced and maintained, not how they are shown.

**Scope boundary:**
- Credit Limit itself (setting, viewing, Remaining Credit calculation) is specified in Module 2, FR-013. The Credit Limit *soft warning at debt entry* is specified in Module 3, FR-018. This module covers only the **notification** triggered when a customer reaches their limit (BR-007), not the limit field or the entry-time warning.
- Recovery Stage and Debt Status are governed by Modules 3 and 5, not this module, per BRL-006 (these four fields — Risk Level, Credit Score, Customer Status, Debt Status — are independently maintained and must not overwrite one another).
- Per BC-007, Credit Score in Version 1 is computed strictly through deterministic business rules; no machine-learning or AI-based scoring is in scope.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-026 | The system shall calculate and maintain a Customer's Credit Score (0–100, banded Excellent/Good/Fair/Poor) using a deterministic, rule-based method triggered by qualifying payment-behavior events. | BR-004 |
| FR-027 | The system shall allow an authorized user to assign or update a Customer's Risk Level from an approved qualitative value set. | BR-005 |
| FR-028 | The system shall notify the business owner when a Customer's outstanding exposure reaches their approved Credit Limit. | BR-007 |

---

### FR-026 — Credit Score Calculation & Recalculation

**Preconditions**
- Customer record exists (Module 2).

**Triggers**
- A qualifying payment-behavior event occurs against the Customer: On-Time Payment, Late Payment, Broken Promise to Pay, Partial Payment, or Long Outstanding Debt.

**Main Flow**
1. A qualifying event occurs against a Customer's Debt (e.g., a payment is recorded on time, a Promise to Pay is broken, per Modules 5 and 6).
2. System applies the corresponding rule-based point adjustment to the Customer's running Credit Score, per the point-value catalog for each qualifying event type (Paid On Time, Late Payment, Broken Promise to Pay, Partial Payment, Long Outstanding Debt) as formally defined in `04_Business_Rules.md`. Illustrative point values were discussed during product discovery but are not restated here as they are not yet formally approved Business Rules.
3. System normalizes the resulting value to the 0–100 scale.
4. System assigns the corresponding band — Excellent, Good, Fair, or Poor (exact band thresholds confirmed in `04_Business_Rules.md`).
5. System updates the Customer's displayed Credit Score (Module 2, FR-013).
6. System records a **Credit Score Recalculated** event in the Audit Trail (User = "System", Timestamp, Action = Credit Score Recalculated, Entity = Customer).

**Alternate Flows**
- **A1 — New Customer with no scoring history:** System assigns a defined baseline score; exact baseline value confirmed in `04_Business_Rules.md` (see open item below).

**Exceptions**
- **E1 — Multiple qualifying events occur concurrently:** System applies each rule's point adjustment cumulatively, in the order the underlying events occurred; exact ordering/concurrency handling confirmed in `04_Business_Rules.md`.

**Business Rule References:** BC-007 (deterministic business rules only, no AI/ML); BRL-006; full rule catalog (event → point value, band thresholds) in `04_Business_Rules.md`.
**Related APIs (reference only):** `GET /customers/{id}/credit-score` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, CreditScoreLedger, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-026.

---

### FR-027 — Risk Level Assignment

**Preconditions**
- Customer record exists; user holds permission to assign Risk Level.

**Triggers**
- Authorized user selects or updates a Customer's Risk Level.

**Main Flow**
1. User selects a Risk Level value for the Customer from the approved qualitative value set.
2. System validates the value against the approved set.
3. System updates the Customer's Risk Level (Module 2, FR-013).
4. System records an **Edited** event in the Audit Trail (User, Timestamp, Action = Edited, Entity = Customer, Field = Risk Level).

**Alternate Flows**
- None beyond the general update path.

**Exceptions**
- **E1 — Invalid or unrecognized Risk Level value submitted:** System rejects the change.
- **E2 — User lacks permission:** Action is not available.

**Business Rule References:** BRL-006 (Risk Level is independently maintained from Credit Score, Customer Status, and Debt Status). See open item below regarding the Risk Level value set.
**Related APIs (reference only):** `PATCH /customers/{id}/risk-level` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-027.

---

### FR-028 — Credit Limit Reached Notification Trigger

**Preconditions**
- Customer has an approved Credit Limit (Module 2, FR-013).

**Triggers**
- A Customer's Outstanding Balance reaches or exceeds their approved Credit Limit (evaluated at Debt creation, per Module 3, FR-018, and/or on a scheduled basis per `04_Business_Rules.md`).

**Main Flow**
1. System detects that a Customer's Outstanding Balance has reached or exceeded their Credit Limit.
2. System generates a Credit Limit Reached event and passes it to the Reminder Engine. The notification is generated once per qualifying event; re-trigger and suppression behavior (e.g., if the balance drops below and later exceeds the limit again) are defined in `04_Business_Rules.md`.
3. Reminder Engine surfaces the event to the business owner via the Notification Center (Module 10 — Notifications & Calendar; not restated here).

**Alternate Flows**
- None; this FR generates the triggering event only. Delivery and display mechanics belong to Module 10.

**Exceptions**
- **E1 — Customer's balance subsequently drops back under the limit before the notification is delivered:** Exact suppression/cancellation behavior confirmed in `04_Business_Rules.md`, per the once-per-qualifying-event principle in step 2.

**Business Rule References:** BC-001 (advisory only; this is a notification, not a block); notification-consumption behavior specified in Module 10, consistent with the Notification Center being consumption-only (per `01_Project_Overview.md` §1.8).
**Related APIs (reference only):** Internal event emitted to the Reminder Engine; consumed via Module 10's endpoints — see `07_API_Design.md`.
**Related Database Entities (reference only):** Customer, Notification — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-028.

---

## Module 4 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-026 | BR-004 | Module 2 (Customer Profile display); Module 5 (Recovery Workflow — triggering events); Module 6 (Payment Tracking — triggering events) |
| FR-027 | BR-005 | Module 2 (Customer Profile display) |
| FR-028 | BR-007 | Module 2 (Credit Limit source); Module 3 (Debt entry evaluation); Module 10 (Notifications & Calendar) |

---

## Open Items Identified During Module 4 Specification

1. **Risk Level value set (FR-027):** Unlike Customer Status, Debt Status, and Recovery Stage, the approved Feature Freeze never enumerated the specific Risk Level values (Risk Levels is a pre-existing feature that predates the Version 1 discovery conversation). This module references "the approved qualitative value set" without inventing specific values; the value set itself must be confirmed and recorded in `04_Business_Rules.md`.
2. **New-Customer baseline Credit Score (FR-026, A1):** No baseline starting score was specified in the Feature Freeze. Deferred to `04_Business_Rules.md`.
3. **Credit Score point values and band thresholds (FR-026):** Illustrative point values per event and illustrative band language (Excellent/Good/Fair/Poor) were discussed during product discovery but are not yet formally approved as Business Rules. The exact point-value catalog and numeric band thresholds must be confirmed and recorded in `04_Business_Rules.md` before implementation.

None of these items change Version 1 scope; they are computation details needed to make Module 4 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 4.** Approved.

---

# Module 5 — Recovery Workflow

## 1. Functional Overview

This module specifies the recovery process itself: the automated and manual channels through which a business pursues repayment (Smart Daily Reminder, Manual WhatsApp/SMS/Call, Promise to Pay), the Recovery Stage progression logic that Modules 3 and 4 reference but do not define, and the escalation hand-off into Professional Collection (fully specified in Module 7).

**Scope boundary:**
- Recovery Stage *display* and manual *override* are specified in Module 3, FR-025. This module specifies the automated progression logic that Module 3 explicitly deferred here.
- Credit Score recalculation *triggers* reference the qualifying events defined in this module (e.g., Broken Promise to Pay); the scoring computation itself remains in Module 4.
- Formal escalation into a Collection Case is specified in Module 7 — Professional Collection; this module covers only the point at which a Debt becomes eligible for that hand-off (Recovery Stage 5).
- Reminder delivery mechanics (message content/channel integration) and Notification Center/Calendar View surfacing are specified in Module 10 — Notifications & Calendar; this module specifies only when a reminder is scheduled and triggered, not how it is displayed.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-029 | The system shall automatically schedule and trigger reminders to a Customer according to the business's configured recovery policy, without requiring manual effort per case. | BR-011 |
| FR-030 | The system shall allow an authorized user to manually send a WhatsApp reminder, SMS reminder, or log a phone call against a Debt. | BR-012 |
| FR-031 | The system shall allow an authorized user to record a Customer's commitment to pay by a specific date and be reminded of it. | BR-013 |
| FR-032 | The system shall automatically advance a Debt's Recovery Stage according to the approved Business Rule Recovery Automation logic. | BR-009 |
| FR-033 | The system shall maintain a chronological Follow-up History of all recovery actions taken on a Debt or Customer. | BR-010 |

---

### FR-029 — Automated Reminder Scheduling (Smart Daily Reminder)

**Preconditions**
- Debt exists and is not Archived, Paid, Cancelled, or Written Off.
- The business's recovery policy (reminder timing) is configured (Module 12 — System Settings; BR-011).

**Triggers**
- A scheduled evaluation cycle (e.g., daily) identifies Debts due for a reminder under the configured recovery policy.

**Main Flow**
1. System evaluates outstanding Debts against the business's configured reminder timing (Module 12).
2. For each Debt due for a reminder, system triggers the appropriate channel (WhatsApp or SMS reminder) automatically.
3. System logs the reminder as a Follow-up History entry (FR-033).
4. System records a **Reminder Sent** event in the Audit Trail (User = "System", Timestamp, Action = Reminder Sent, Entity = Debt).
5. System emits the event to the Reminder Engine, which feeds the Notification Center and Calendar View (Module 10; not restated here).

**Alternate Flows**
- **A1 — Debt reaches a Recovery Stage where automated reminders are no longer the primary channel (e.g., Professional Collection):** Exact interaction between automated reminders and escalation status is defined in `04_Business_Rules.md` and Module 7.

**Exceptions**
- **E1 — Reminder delivery fails (e.g., invalid phone number):** System logs a failed delivery in Follow-up History; exact retry behavior defined in `04_Business_Rules.md`.

**Business Rule References:** Reminder timing is configurable, not hardcoded (BC-003); full scheduling rule set in `04_Business_Rules.md`.
**Related APIs (reference only):** Internal scheduled process; reminder log exposed via `GET /debts/{id}/followup-history` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, FollowUpHistory, AuditLog, SystemSettings — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-029.

---

### FR-030 — Manual Reminder (WhatsApp / SMS / Call)

**Preconditions**
- Debt exists; user holds permission to initiate manual reminders.

**Triggers**
- User selects "Send WhatsApp," "Send SMS," or "Log Call" against a Debt or Customer.

**Main Flow**
1. User initiates a manual WhatsApp message, SMS, or phone call against a Debt.
2. System sends the message (WhatsApp/SMS) or records the call outcome as entered by the user.
3. System logs the action as a Follow-up History entry (FR-033).
4. System records the corresponding Audit Trail event.

**Alternate Flows**
- **A1 — Call reminder logged with no answer/no outcome:** System still records the attempt in Follow-up History.

**Exceptions**
- **E1 — User lacks permission:** Action is not available.
- **E2 — WhatsApp/SMS delivery fails:** System logs the failure in Follow-up History; exact retry behavior defined in `04_Business_Rules.md`.

**Business Rule References:** None beyond general audit/logging rules (BRL-003).
**Related APIs (reference only):** `POST /debts/{id}/reminders/whatsapp`, `POST /debts/{id}/reminders/sms`, `POST /debts/{id}/reminders/call` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, FollowUpHistory, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-030.

---

### FR-031 — Promise to Pay

**Preconditions**
- Debt exists; user holds permission to record a Promise to Pay.

**Triggers**
- User records a customer's verbal or written commitment to pay by a specific date.

**Main Flow**
1. User submits a Promise to Pay date against a Debt.
2. System stores the commitment and schedules a reminder for the promised date (feeding Module 10 — Calendar View and Notification Center).
3. System logs the action as a Follow-up History entry (FR-033).
4. On or after the promised date, system evaluates whether the promise was kept (payment recorded, Module 6) or broken.
5. If broken, system emits a qualifying event to Module 4 (Credit Score recalculation, FR-026) and Module 12/Reporting (SM-008 — Promise Fulfillment Rate).

**Alternate Flows**
- **A1 — Customer pays on or before the promised date:** Promise is marked fulfilled; contributes positively to SM-008.
- **A2 — Customer requests to revise the promised date:** Exact revision handling (replace vs. log as broken-then-renewed) defined in `04_Business_Rules.md`.

**Exceptions**
- **E1 — User lacks permission:** Action is not available.

**Business Rule References:** Broken-promise point adjustment referenced in Module 4, FR-026; exact fulfillment/breach determination logic in `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /debts/{id}/promise-to-pay` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, PromiseToPay, FollowUpHistory — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-031.

---

### FR-032 — Recovery Stage Automation

**Preconditions**
- Debt exists and is not Archived.

**Triggers**
- A qualifying recovery event occurs against the Debt (e.g., reminder sent, call logged, Promise to Pay made or broken, escalation to Professional Collection, payment closing the Debt).

**Main Flow**
1. A qualifying event occurs against a Debt (per the events defined in FR-029–FR-031 and Module 7).
2. System evaluates the event against the approved Business Rule Recovery Automation logic.
3. System advances the Debt's Recovery Stage to the applicable value (Stage 1 — Friendly Reminder, through Stage 6 — Recovered), per the exact stage-transition matrix defined in `04_Business_Rules.md`.
4. System updates the Recovery Stage shown on Debt Details (Module 3, FR-025) and Recovery Timeline (Module 3, FR-024).
5. System records a **Status Changed**-class Audit Trail entry reflecting the stage progression (exact event naming confirmed in `04_Business_Rules.md`, consistent with the approved Audit Trail event catalog).

**Alternate Flows**
- **A1 — An authorized user manually overrides the automatically determined stage:** Handled per Module 3, FR-025, not restated here.

**Exceptions**
- **E1 — No qualifying event matches any defined transition:** Recovery Stage remains unchanged.

**Business Rule References:** BRL-002; full stage-transition matrix in `04_Business_Rules.md`.
**Related APIs (reference only):** Internal automation process; stage reflected via `GET /debts/{id}` (Module 3) — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-032.

---

### FR-033 — Follow-up History

**Preconditions**
- Debt or Customer exists.

**Triggers**
- Any recovery-related action occurs (automated reminder, manual reminder/call, Promise to Pay, payment, escalation).

**Main Flow**
1. System records each recovery-related action as a chronological Follow-up History entry, capturing the action type, timestamp, and initiating user ("System" for automated actions).
2. Follow-up History entries feed the Recovery Timeline (Module 3, FR-024).

**Alternate Flows**
- None; this is a passive, system-maintained log with no independent user-facing creation flow beyond the actions defined in FR-029–FR-031 and Modules 6–7.

**Exceptions**
- None.

**Business Rule References:** BRL-003 (attributable action).
**Related APIs (reference only):** `GET /debts/{id}/followup-history` — see `07_API_Design.md`.
**Related Database Entities (reference only):** FollowUpHistory, Debt, Customer — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-033.

---

## Module 5 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-029 | BR-011 | Module 3 (Debt Register); Module 10 (Notifications & Calendar); Module 12 (System Settings — reminder timing) |
| FR-030 | BR-012 | Module 3 (Debt Register) |
| FR-031 | BR-013 | Module 4 (Credit Score recalculation); Module 6 (Payment Tracking — fulfillment check); Module 9 (Reporting — SM-008) |
| FR-032 | BR-009 | Module 3 (Recovery Stage display/override, FR-025) |
| FR-033 | BR-010 | Module 3 (Recovery Timeline, FR-024); Module 7 (Professional Collection) |

---

## Open Items Identified During Module 5 Specification

1. **Recovery Stage transition matrix (FR-032):** The Feature Freeze names the six stages and states automation should update them "where appropriate," but does not define the exact event-to-stage mapping. Deferred to `04_Business_Rules.md`.
2. **Reminder delivery failure/retry behavior (FR-029, FR-030):** Not specified in the Feature Freeze. Deferred to `04_Business_Rules.md`.
3. **Promise to Pay date-revision handling (FR-031, A2):** Not specified whether revising a promised date replaces it or logs a break-then-renew. Deferred to `04_Business_Rules.md`.

None of these items change Version 1 scope.

---

**End of Module 5.** Approved.

---

# Module 6 — Payment Tracking

## 1. Functional Overview

This module specifies the recording and lifecycle of payments made against a Debt. Payment Tracking is the **sole owner** of payment records in Version 1: Customer Management (Module 2), Debt Register (Module 3), Recovery Workflow (Module 5), Professional Collection (Module 7), and Reporting (Module 9) may all *consume* payment state, but none of them may create, modify, or directly derive Outstanding Balance or Debt Status independently of this module.

Recording a payment is the mechanism through which a Debt's financial position changes, a Customer's Outstanding Balance and Remaining Credit are recalculated, a Debt's status may progress to Partial Paid or Paid, a Digital Receipt is generated, and qualifying events are emitted to Credit Scoring, Promise to Pay fulfillment, and Notifications.

## Scope Boundary

- **Outstanding Balance** (Customer-level, Module 2) is modified only by two events in the entire system: Debt Creation (Module 3, FR-017) and Payment Recording (this module, FR-034). No other module may modify it directly; Module 2 only displays it (Module 2, FR-013, as already clarified).
- **Debt Status** transitions to **Partial Paid** or **Paid** occur only through this module (FR-037). Module 3, FR-021 already excludes these two transitions from its general-purpose Debt Update, deferring them here.
- **Credit Score** is never calculated in this module. This module only emits qualifying payment-behavior events to Module 4 — Credit & Risk Management, which retains sole ownership of the scoring computation (FR-039).
- **Promise to Pay fulfillment** evaluation is triggered by this module but owned by Module 5 — Recovery Workflow (FR-031); this module does not redefine that logic.
- **Receipt generation** (template, PDF structure, Auto Numbering format) is owned by Module 8 — Documents. This module triggers generation automatically upon payment (FR-038) but does not restate Module 8's generation mechanics.
- **Professional Collection** (Module 7) consumes payment state (e.g., to determine whether a Collection Case can be closed) but does not modify payment records; not redefined here.
- **Reporting** (Module 9) and **Notifications** (Module 10) consume payment records/events; neither may edit them.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-034 | The system shall allow an authorized user to record a full or partial payment against a specific Debt. | BR-018 |
| FR-035 | The system shall allow an authorized user to view the chronological payment history of a Debt or Customer. | BR-018 |
| FR-036 | The system shall recalculate a Customer's Outstanding Balance and Remaining Credit whenever a payment is recorded. | BR-003, BR-008 |
| FR-037 | The system shall update a Debt's Status to Partial Paid or Paid based on cumulative payments recorded against it. | BR-008 |
| FR-038 | The system shall automatically trigger Digital Receipt generation upon successful payment recording. | BR-019 |
| FR-039 | The system shall emit qualifying payment-behavior events to Credit & Risk Management and Recovery Workflow without performing their computations itself. | BR-004, BR-013 |

---

### FR-034 — Payment Recording

**Preconditions**
- The Debt exists, is not Archived, and is not already in Cancelled or Written Off status.
- User is authenticated and holds permission to record payments.

**Triggers**
- User selects "Receive Payment" against a specific Debt and submits a payment amount, date, and any optional reference details.

**Main Flow**
1. User selects the specific Debt being paid and submits the payment amount (full or partial), date, and optional reference details.
2. System validates the payment amount is positive and numeric.
3. System creates the Payment record against the selected Debt.
4. System recalculates the Debt's remaining balance and the Customer's Outstanding Balance and Remaining Credit (FR-036).
5. System updates the Debt Status accordingly (FR-037).
6. System records a **Payment Added** event in the Audit Trail (User, Timestamp, Action = Payment Added, Entity = Debt).
7. System triggers downstream processing: Receipt generation (FR-038) and event emission (FR-039).

**Alternate Flows**
- **A1 — Partial payment (amount is less than the remaining balance):** Debt Status moves toward Partial Paid (FR-037); the Debt remains open for further payments.
- **A2 — Full payment (amount completes the remaining balance):** Debt Status moves to Paid (FR-037).

**Exceptions**
- **E1 — Payment amount exceeds the remaining balance (overpayment):** Exact handling (reject, cap, or record a credit) is not defined in the approved Feature Freeze and is not assumed here — deferred to `04_Business_Rules.md`. See Open Items.
- **E2 — Debt is Archived:** Action is not permitted; the Debt must be restored first (Module 3, FR-023).
- **E3 — User lacks permission to record payments:** Action is not available.
- **E4 — Payment submitted against a Debt already Paid, Cancelled, or Written Off:** Exact handling is not defined in the approved Feature Freeze — deferred to `04_Business_Rules.md`. See Open Items.

**Business Rule References:** BC-002 (payments are financial records; correction mechanics deferred — see Open Items); full payment-validation rules in `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /debts/{id}/payments` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Payment, Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-034.

---

### FR-035 — Payment History

**Preconditions**
- Debt or Customer exists; user holds view permission.

**Triggers**
- User opens Debt Details or a Customer Profile and requests payment history.

**Main Flow**
1. User requests payment history for a Debt or a Customer.
2. System retrieves and displays all Payment records in chronological order, including amount, date, and reference details.
3. Payment History entries feed the Recovery Timeline (Module 3, FR-024) and Follow-up History (Module 5, FR-033).

**Alternate Flows**
- **A1 — Customer-level view:** Aggregates payment history across all of the Customer's Debts.

**Exceptions**
- **E1 — User lacks permission:** Access is denied.
- **E2 — No payments recorded:** System displays an empty-result state.

**Business Rule References:** None beyond general view permissions (`08_Security_and_RBAC.md`).
**Related APIs (reference only):** `GET /debts/{id}/payments`, `GET /customers/{id}/payments` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Payment, Debt, Customer — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-035.

---

### FR-036 — Outstanding Balance & Remaining Credit Recalculation

**Preconditions**
- A Payment has been recorded (FR-034) or a new Debt has been created (Module 3, FR-017) — the only two events permitted to affect Outstanding Balance.

**Triggers**
- Successful Payment Recording (FR-034).

**Main Flow**
1. A Payment is recorded against a Debt.
2. System recalculates the Debt's remaining balance (original amount minus cumulative payments).
3. System recalculates the Customer's aggregate Outstanding Balance (sum of remaining balances across the Customer's open Debts).
4. System recalculates the Customer's Remaining Credit (Credit Limit minus Outstanding Balance), reflected on the Customer Profile (Module 2, FR-013).

**Alternate Flows**
- None.

**Exceptions**
- None beyond FR-034's exceptions.

**Business Rule References:** Enforces the approved architecture principle that Outstanding Balance is modified only by Debt Creation (Module 3) and Payment Recording (this module); no other module may modify it directly.
**Related APIs (reference only):** Internal recalculation; reflected via `GET /customers/{id}/credit-profile` (Module 2) — see `07_API_Design.md`.
**Related Database Entities (reference only):** Payment, Debt, Customer — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-036.

---

### FR-037 — Debt Status Update via Payment

**Preconditions**
- A Payment has been recorded against a Debt (FR-034).

**Triggers**
- Successful Payment Recording.

**Main Flow**
1. System compares cumulative payments recorded against the Debt to the Debt's total amount.
2. If cumulative payments are greater than zero but less than the total amount, system sets Debt Status to **Partial Paid**.
3. If cumulative payments equal or complete the total amount, system sets Debt Status to **Paid**.
4. System records a **Status Changed** event in the Audit Trail (User = "System", Timestamp, Action = Status Changed, Entity = Debt).
5. Updated Debt Status is reflected on Debt Details (Module 3, FR-019, FR-021).

**Alternate Flows**
- None beyond the two transition paths above.

**Exceptions**
- **E1 — Overpayment scenario:** Resulting status treatment deferred to `04_Business_Rules.md` (see FR-034, Open Items).

**Business Rule References:** This FR is the only approved mechanism by which a Debt reaches Partial Paid or Paid status; Module 3, FR-021 explicitly excludes these transitions from general Debt Update. Exact numeric thresholds/rounding rules in `04_Business_Rules.md`.
**Related APIs (reference only):** Internal; reflected via `GET /debts/{id}` (Module 3) — see `07_API_Design.md`.
**Related Database Entities (reference only):** Debt, Payment, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-037.

---

### FR-038 — Payment Receipt Generation Trigger

**Preconditions**
- A Payment has been successfully recorded (FR-034).

**Triggers**
- Successful Payment Recording.

**Main Flow**
1. Upon successful Payment Recording, system automatically triggers Digital Receipt generation for the payment.
2. System invokes the Document Generation Service (Module 8 — Documents; not restated here) to produce the Receipt as a PDF, assigned its own Auto Numbering identifier (`RCT-000001`, per BR-036).
3. System records a **Receipt Generated** event in the Audit Trail.
4. The generated Receipt is linked to the Payment and Debt records and made available to the Customer (Module 8; Customer Mobile App).

**Alternate Flows**
- None; per BR-019, receipt generation is automatic, not user-initiated.

**Exceptions**
- **E1 — Document Generation Service fails to produce the Receipt:** Payment Recording itself is not rolled back; exact retry/failure-handling behavior deferred to `04_Business_Rules.md`.

**Business Rule References:** BR-019 (automatic receipt generation). Full generation and template logic is specified in Module 8 — Documents and is not restated here.
**Related APIs (reference only):** Internal trigger to Module 8's receipt-generation endpoint — see `07_API_Design.md`.
**Related Database Entities (reference only):** Payment, Receipt (schema owned by Module 8) — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-038.

---

### FR-039 — Downstream Event Emission

**Preconditions**
- A Payment has been recorded (FR-034).

**Triggers**
- Successful Payment Recording.

**Main Flow**
1. System emits a qualifying payment-behavior event (On-Time Payment, Late Payment, or Partial Payment, based on payment timing/completeness relative to the Debt's due date) to Module 4 — Credit & Risk Management for Credit Score recalculation. This module does not calculate the Credit Score itself.
2. If an open Promise to Pay exists against the Debt, system notifies Module 5 — Recovery Workflow to evaluate promise fulfillment (Module 5, FR-031).
3. System emits a Payment Received event to the Reminder Engine, which feeds the Notification Center (Module 10; not restated here).

**Alternate Flows**
- None.

**Exceptions**
- None beyond FR-034's exceptions; this is an internal event-emission step.

**Business Rule References:** Enforces the approved architecture boundary that Payment Tracking never calculates Credit Score directly (Module 4 retains sole computation ownership); exact event-classification rules (on-time vs. late) in `04_Business_Rules.md`.
**Related APIs (reference only):** Internal event emission consumed by Modules 4, 5, and 10 — see `07_API_Design.md`.
**Related Database Entities (reference only):** Payment, Debt — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-039.

---

## Module 6 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-034 | BR-018 | Module 3 (Debt Register) |
| FR-035 | BR-018 | Module 3 (Recovery Timeline); Module 5 (Follow-up History) |
| FR-036 | BR-003, BR-008 | Module 2 (Customer Profile — Outstanding Balance, Remaining Credit) |
| FR-037 | BR-008 | Module 3 (Debt Status, FR-021) |
| FR-038 | BR-019 | Module 8 (Documents) |
| FR-039 | BR-004, BR-013 | Module 4 (Credit & Risk Management); Module 5 (Recovery Workflow — Promise to Pay); Module 10 (Notifications & Calendar) |

---

## Open Items Identified During Module 6 Specification

The following behaviors are not addressed in the approved Feature Freeze or Business Requirements. None are assumed or invented here; all are deferred to `04_Business_Rules.md` for an explicit decision:

1. **Payment editing:** Whether a recorded payment can be corrected after the fact, and if so, how, is not specified.
2. **Payment deletion / archival:** Whether a Payment record can be removed at all is not specified. If permitted, BC-002 (financial records are never permanently deleted) would require it to follow the Archive/Restore pattern already established for Customers and Debts — but this module does not assume that mechanism applies without confirmation, since Payment was not explicitly named alongside Customer and Debt in the approved Soft Delete/Archive scope.
3. **Payment reversal:** Not specified whether a distinct "reversal" action (as opposed to edit or delete) exists.
4. **Overpayment handling:** Not specified whether an overpayment is rejected, capped at the remaining balance, or recorded as a credit (see FR-034, E1).
5. **Payment against a closed Debt (Paid, Cancelled, Written Off):** Not specified whether this is permitted (see FR-034, E4).
6. **Refund behavior:** Not specified whether refunds are in scope at all for Version 1.
7. **Payment method catalog:** Not specified whether payment method is a fixed, enumerated list (e.g., Cash, Bank Transfer, Mobile Money) or a free-text reference field.

**Resolved, not an open item — Multi-debt payment allocation:** BR-018 already scopes payment recording to "a specific debt" (singular). Version 1 therefore does not support splitting a single payment across multiple Debts; this is a scope boundary already established by the approved Business Requirements, not a gap requiring further decision.

None of the above items change Version 1 scope; they are implementation-level decisions needed to make Module 6 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 6. Approved.**

---

# Module 7 — Professional Collection

## 1. Functional Overview

This module specifies the formal escalation path a Debt follows once the standard Recovery Workflow (Module 5) determines it is eligible for structured collection action. It governs the **Collection Case** — its creation, assignment to a Collection Officer, progress tracking, activity recording, and closure.

Professional Collection is a case-management layer over an existing Debt; it does not own the Debt, the Customer, payments, receipts, or Credit Score. It reacts to state owned elsewhere (Recovery Stage, Debt Status, payment events) and contributes its own activity back into the shared Follow-up History and Recovery Timeline without duplicating ownership of either.

## Scope Boundary

- **Debt Register (Module 3):** Professional Collection consumes the Debt, its Recovery Stage, and its Debt Status. It never modifies Debt financial values.
- **Recovery Workflow (Module 5):** Escalation begins only once Module 5's stage-progression logic determines the Debt has reached Recovery Stage 5 — Professional Collection (or an authorized manual escalation, per FR-040). Module 5 retains sole ownership of stage-transition logic; this module does not redefine it.
- **Payment Tracking (Module 6):** Payments remain owned exclusively by Module 6. Professional Collection never creates, edits, or deletes payments — it only consumes the payment events Module 6 emits (FR-039).
- **Documents (Module 8):** Professional Collection may request document generation (e.g., a Demand Letter); the generation logic, templates, and numbering remain owned by Module 8 and are not restated here.
- **Reporting (Module 9):** Collection KPIs (e.g., Active Collection Cases, SM-006) are consumed by Module 9; this module does not define reports.
- **Notifications (Module 10):** Collection events may be surfaced as notifications; delivery and display remain owned by Module 10.
- **Ownership boundary:** Professional Collection owns only the Collection Case entity. It never owns Customer, Debt, Payment, Receipt, or Credit Score — those remain owned by Modules 2, 3, 6, 8, and 4 respectively.
- **Cardinality:** A Collection Case references exactly one Debt. Version 1 does not support multi-debt Collection Cases.
- **No implied payment:** Closing a Collection Case never implies or creates a payment. Collection closure and Debt payment are separate concepts owned by different modules (this module and Module 6, respectively).

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-040 | The system shall create a Collection Case referencing exactly one Debt when the Debt becomes eligible for escalation to Professional Collection. | BR-014, BR-036 |
| FR-041 | The system shall allow an authorized user to assign a Collection Case to a Collection Officer. | BR-014 |
| FR-042 | The system shall allow an authorized user to view a Collection Case's details. | BR-014 |
| FR-043 | The system shall allow an authorized user to update a Collection Case's non-financial details. | BR-014, BR-030 |
| FR-044 | The system shall allow an authorized user to record a collection activity against a Collection Case. | BR-014, BR-010 |
| FR-045 | The system shall allow an authorized user to close a Collection Case with a recorded outcome. | BR-014 |
| FR-046 | The system shall allow an authorized user to view the chronological history of a Collection Case. | BR-010, BR-014 |

---

### FR-040 — Escalation & Collection Case Creation

**Preconditions**
- The Debt exists, is not Archived, and does not already have an open Collection Case referencing it.
- User is authenticated; escalation is either system-initiated (Module 5) or initiated by a user holding escalation permission.

**Triggers**
- Recovery Workflow (Module 5) determines the Debt has reached Recovery Stage 5 — Professional Collection, or an authorized user manually initiates escalation from Debt Details (Module 3).

**Main Flow**
1. The Debt reaches Recovery Stage 5 — Professional Collection per Module 5's stage-transition logic, or an authorized user manually initiates escalation from Debt Details.
2. System creates a Collection Case referencing exactly one Debt.
3. System assigns the Collection Case a unique Auto Numbering identifier (`COL-000001`, per BR-036).
4. System sets the Collection Case's initial status (exact default value confirmed in `04_Business_Rules.md`; see Open Items).
5. System records a **Collection Requested** event in the Audit Trail (User or "System", Timestamp, Action = Collection Requested, Entity = Debt / Collection Case).
6. The Collection Case becomes visible in Active Collection Cases reporting (Module 9; not restated here).

**Alternate Flows**
- **A1 — Debt already has an open Collection Case:** A duplicate case is not created for the same Debt; exact handling (reject the request vs. surface the existing case) confirmed in `04_Business_Rules.md`.
- **A2 — Manual escalation initiated before Recovery Stage 5 is reached:** Whether early manual escalation is permitted, and under what authorization, is confirmed in `04_Business_Rules.md` — not assumed here.

**Exceptions**
- **E1 — User lacks permission to escalate:** Action is not available.
- **E2 — Referenced Debt is Archived:** Action is not permitted; the Debt must be restored first (Module 3, FR-023).

**Business Rule References:** Recovery Stage eligibility is owned by Module 5 and not redefined here; BR-036 (Auto Numbering); duplicate-case handling and early-escalation eligibility deferred to `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /debts/{id}/collection-cases` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CollectionCase, Debt, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-040.

---

### FR-041 — Collection Case Assignment

**Preconditions**
- Collection Case exists and is open; user holds permission to assign cases.

**Triggers**
- Authorized user selects a Collection Officer to assign to a Collection Case.

**Main Flow**
1. User selects a Collection Officer to assign to an open Collection Case.
2. System updates the Collection Case's assigned officer.
3. System records an **Edited** event in the Audit Trail (Entity = Collection Case, Field = Assigned Officer).

**Alternate Flows**
- **A1 — Reassignment of an already-assigned case:** Follows the same flow; exact reassignment policy (e.g., prior-assignee notification) confirmed in `04_Business_Rules.md`.

**Exceptions**
- **E1 — User lacks permission to assign:** Action is not available.
- **E2 — Assigned user does not hold the Collection Officer role:** Restricted per `08_Security_and_RBAC.md`.

**Business Rule References:** Automatic assignment rules, collector workload balancing, and reassignment policy are explicitly deferred to `04_Business_Rules.md`; this FR covers only manual assignment.
**Related APIs (reference only):** `PATCH /collection-cases/{id}/assign` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CollectionCase, User, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-041.

---

### FR-042 — Collection Case Details

**Preconditions**
- Collection Case exists; user holds view permission.

**Triggers**
- User selects a Collection Case from a list or from its linked Debt's details.

**Main Flow**
1. User selects a Collection Case.
2. System displays the Case's referenced Debt, assigned Collection Officer, current status, and associated Notes & Attachments (Module 8, reference only).

**Alternate Flows**
- **A1 — Case is Closed:** Displayed in a read-only state.

**Exceptions**
- **E1 — User lacks permission:** Access is denied.

**Business Rule References:** BRL-004 (if archived); role-based field visibility per `08_Security_and_RBAC.md`.
**Related APIs (reference only):** `GET /collection-cases/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CollectionCase, Debt, User — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-042.

---

### FR-043 — Collection Case Update

**Preconditions**
- Collection Case exists and is open; user holds edit permission.

**Triggers**
- User edits non-financial Collection Case details.

**Main Flow**
1. User submits updated Collection Case details.
2. System validates and saves the update.
3. System records an **Edited** event in the Audit Trail.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Required fields invalid:** Update is rejected.
- **E2 — User lacks permission:** Action is not available.
- **E3 — Attempted edit of a Closed case:** Rejected; whether a Closed case can be reopened is not specified (see Open Items).

**Business Rule References:** This FR explicitly excludes any financial fields (Outstanding Balance, Remaining Credit, Credit Score, Payment), which remain owned by Modules 2, 4, and 6 respectively — Professional Collection never modifies them.
**Related APIs (reference only):** `PUT /collection-cases/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CollectionCase, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-043.

---

### FR-044 — Collection Activity Recording

**Preconditions**
- Collection Case exists and is open; user holds permission to record collection activity.

**Triggers**
- Authorized user logs a collection activity (e.g., negotiation call, formal notice sent, field visit) against a Collection Case.

**Main Flow**
1. User logs a collection activity against the Collection Case.
2. System records the activity with User, Timestamp, and activity details.
3. The activity is reflected in the Debt's Follow-up History (Module 5, FR-033) and Recovery Timeline (Module 3, FR-024) without duplicating ownership of either.
4. System records the applicable Audit Trail event (an **Edited** event on the Collection Case, or the specific approved event type when the activity corresponds to one already defined elsewhere, such as **Demand Letter Generated** when a letter is requested via Module 8).

**Alternate Flows**
- **A1 — Activity corresponds to a payment received:** Professional Collection consumes the Payment Added event emitted by Module 6 (FR-039) and reflects it in the Case's activity log; it never creates or edits the payment itself.

**Exceptions**
- **E1 — User lacks permission:** Action is not available.
- **E2 — Case is Closed:** Activity logging is rejected; whether a Closed case can be reopened is not specified (see Open Items).

**Business Rule References:** This FR enforces that Collection Activity Recording never creates, edits, or deletes Payment records (Module 6 exclusive ownership); it only consumes payment events.
**Related APIs (reference only):** `POST /collection-cases/{id}/activities` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CollectionCase, FollowUpHistory, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-044.

---

### FR-045 — Collection Case Closure

**Preconditions**
- Collection Case exists and is open; user holds permission to close cases.

**Triggers**
- Authorized user selects "Close Collection Case" and records an outcome.

**Main Flow**
1. User selects a closure outcome for the Collection Case (exact outcome value set confirmed in `04_Business_Rules.md`; see Open Items).
2. System sets the Collection Case status to Closed with the recorded outcome.
3. System records a **Status Changed** event in the Audit Trail (Entity = Collection Case).
4. Closure does not itself change the Debt's financial state (Outstanding Balance, Debt Status) and never implies or creates a payment; those remain governed exclusively by Module 6.

**Alternate Flows**
- **A1 — Case closed with an outcome reflecting recovery:** This reflects that the Debt separately reached Paid status via Module 6; closure records the outcome but does not cause it.

**Exceptions**
- **E1 — User lacks permission to close:** Action is not available.
- **E2 — Attempt to close an already-Closed case:** Rejected (no-op).

**Business Rule References:** Closure policy, abandoned-case handling, and maximum collection duration are explicitly deferred to `04_Business_Rules.md`. This FR enforces that Collection Case closure never triggers or implies payment (Module 6 exclusive ownership).
**Related APIs (reference only):** `POST /collection-cases/{id}/close` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CollectionCase, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-045.

---

### FR-046 — Collection Case History

**Preconditions**
- Collection Case exists; user holds view permission.

**Triggers**
- User requests the chronological history of a Collection Case (activities, assignment changes, status changes).

**Main Flow**
1. User requests Collection Case history.
2. System retrieves and displays all recorded activities, assignments, and status changes for the Case in chronological order.
3. This history is also reflected in the Debt's Follow-up History and Recovery Timeline (Modules 5 and 3) without duplicating the underlying record.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks permission:** Access is denied.
- **E2 — No activity recorded:** System displays an empty-result state.

**Business Rule References:** BRL-003 (attributable action).
**Related APIs (reference only):** `GET /collection-cases/{id}/history` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CollectionCase, FollowUpHistory, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-046.

---

## Module 7 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-040 | BR-014, BR-036 | Module 3 (Debt Register); Module 5 (Recovery Workflow — escalation eligibility) |
| FR-041 | BR-014 | Module 12 (Administration & Settings — Collection Officer role) |
| FR-042 | BR-014 | Module 8 (Documents — Notes & Attachments) |
| FR-043 | BR-014, BR-030 | — |
| FR-044 | BR-014, BR-010 | Module 3 (Recovery Timeline); Module 5 (Follow-up History); Module 6 (payment event consumption); Module 8 (Documents) |
| FR-045 | BR-014 | Module 6 (Payment Tracking — separate, not implied) |
| FR-046 | BR-010, BR-014 | Module 3 (Recovery Timeline); Module 5 (Follow-up History); Module 9 (Reporting) |

---

## Open Items Identified During Module 7 Specification

The following behaviors are not addressed in the approved Feature Freeze or Business Requirements. None are assumed or invented here; all are deferred to `04_Business_Rules.md`:

1. **Automatic assignment rules / collector workload balancing (FR-041):** Not specified whether Collection Cases are auto-assigned or always manually assigned.
2. **Escalation timing / early manual escalation eligibility (FR-040, A2):** Not specified whether a user may escalate a Debt before Module 5 determines Recovery Stage 5 eligibility.
3. **Reassignment policy (FR-041, A1):** Not specified whether reassignment notifies the prior assignee or has other conditions.
4. **Closure policy and outcome value set (FR-045):** The Feature Freeze approved "Recovered" as a Recovery Timeline/Stage endpoint but never enumerated a full Collection Case closure-outcome value set (e.g., Recovered, Unresolved, Written Off).
5. **Abandoned Collection Cases:** No handling for cases with no activity over an extended period is specified.
6. **Maximum collection duration:** Not specified.
7. **External collection agencies:** Not addressed anywhere in the Feature Freeze; no hand-off-to-third-party functionality is implied or included here.
8. **Legal escalation as a distinct process:** The approved scope includes a "Legal Notice" Demand Letter template (Module 8), but no distinct legal-escalation case status or workflow beyond that document is defined.
9. **Duplicate Collection Case handling (FR-040, A1):** Not specified whether a second escalation attempt against an already-escalated Debt is rejected or redirected to the existing case.
10. **Reopening a Closed Collection Case (FR-043, E3; FR-044, E2):** Not specified whether this is possible.
11. **Initial Collection Case status at creation (FR-040):** Not specified.

None of the above items change Version 1 scope; they are implementation-level decisions needed to make Module 7 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 7. Approved.**

---

# Module 8 — Documents

## 1. Functional Overview

This module owns all document generation and document management in Version 1: Digital Receipts, Demand Letters (including the Legal Notice template), Customer Statements of Account, and their viewing, downloading, and history. Other modules *request* document generation or *trigger* it as a side effect of their own events; none of them generate PDFs, assign document numbers, or store document content themselves. Module 8 is the sole owner of documents as an artifact, while remaining strictly a consumer of the data (Debt, Payment, Customer, Collection Case) it renders into those documents.

## Scope Boundary

- **Debt Register (Module 3):** Documents reference Debt records for their content. Documents never modify Debt data.
- **Recovery Workflow (Module 5):** May request Demand Letter (or Legal Notice) generation. Generation itself remains owned here.
- **Payment Tracking (Module 6):** Triggers Receipt generation upon successful payment (Module 6, FR-038). Receipt creation remains owned exclusively by this module; this module never records or validates payments.
- **Professional Collection (Module 7):** May request Demand Letters or Legal Notices as part of a Collection Case. This module generates the documents; Professional Collection never generates them directly.
- **Reporting (Module 9):** Consumes document metadata (counts, types, generation dates). This module never creates reports.
- **Notifications (Module 10):** May notify a user that a document is available. Delivery remains owned by Module 10.
- **Ownership boundary:** This module owns only Documents (Receipt, Demand Letter, Statement) as generated artifacts. It never owns Customer, Debt, Payment, Collection Case, or Credit Score — those remain owned by Modules 2, 3, 6, 7, and 4 respectively. Documents are generated *from* other modules' data; they never become the source of truth for that data.

**Scope note — Customer Statement of Account:** This module also specifies Statement of Account generation (FR-049), even though it was not listed among this module's functional scope in your message. It is included because it is already approved Version 1 scope (BR-021) with its own Auto Numbering identifier under BR-036, and Modules 2 (FR-008) and 3 (FR-019) already forward-reference "Generate Statement" to this module. Omitting it here would leave those two approved forward references unresolved and would contradict the already-approved baseline. Flagging this rather than silently deciding either way.

**Scope note — Legal Notice as a Demand Letter template, not a separate document type:** Your message's examples imply Legal Notice may be a distinct numbered document series (`LNT-000001`) alongside Demand Letter (`DLT-000001`). The already-approved baseline (`01_Project_Overview.md` glossary and BR-036) defines exactly five Auto-Numbered document/record types — Debt, Receipt, Demand Letter, Statement, Collection Case — with Legal Notice explicitly listed as one of the **four templates** of the single Demand Letter Generator feature, not a sixth numbered entity. This module therefore implements Legal Notice as a Demand Letter template sharing the approved `DL-000001` numbering series, consistent with the frozen baseline, rather than introducing a new `LNT-000001` series. Reporting this rather than silently changing the previously approved numbering scope.

**Scope note — numbering format preserved:** For the same reason, this module uses the previously approved formats `RCT-000001` (Receipt), `DL-000001` (Demand Letter, all four templates), and `ST-000001` (Statement) — as already established in `01_Project_Overview.md` and referenced by Modules 2, 3, and 6 — rather than the illustrative `DLT-000001` / `LNT-000001` pattern in your message, to avoid silently modifying frozen documentation.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-047 | The system shall automatically generate a Digital Receipt PDF when triggered by Payment Tracking (Module 6). | BR-019 |
| FR-048 | The system shall generate a Demand Letter PDF (First Reminder, Second Reminder, Final Demand, or Legal Notice template) when requested by an authorized user, Recovery Workflow, or Professional Collection. | BR-020 |
| FR-049 | The system shall generate a Customer Statement of Account PDF when requested from the Customer Profile or Debt Details. | BR-021 |
| FR-050 | The system shall allow an authorized user to view a generated document. | BR-019, BR-020, BR-021 |
| FR-051 | The system shall allow an authorized user to download a generated document as a PDF. | BR-019, BR-020, BR-021 |
| FR-052 | The system shall allow an authorized user to view the chronological history of a document. | BR-019, BR-020, BR-021, BR-030 |

---

### FR-047 — Digital Receipt Generation

**Preconditions**
- A Payment has been successfully recorded (Module 6, FR-034), and Module 6 has issued a receipt-generation trigger (Module 6, FR-038).

**Triggers**
- Successful Payment Recording, via the trigger emitted by Module 6.

**Main Flow**
1. This module receives the receipt-generation request from Module 6 upon successful Payment Recording.
2. System generates a Digital Receipt PDF using the approved Receipt template, populated with payment amount, date, Debt reference, and Company branding (Module 12 — System Settings; not restated here).
3. System assigns the Receipt a unique Auto Numbering identifier (`RCT-000001` format, per BR-036).
4. System records a **Receipt Generated** event in the Audit Trail (User = "System", Timestamp, Action = Receipt Generated, Entity = Payment/Receipt).
5. The generated Receipt is linked to the Payment and made available for viewing/download (FR-050, FR-051) and to the Customer (Customer Mobile App).

**Alternate Flows**
- None; per BR-019, generation is automatic and system-initiated only.

**Exceptions**
- **E1 — Receipt generation fails (e.g., template rendering error):** Payment Recording (Module 6) is not rolled back; exact retry/failure-handling behavior deferred to `04_Business_Rules.md`.

**Business Rule References:** BR-019; BR-036 (Auto Numbering). This module never records or validates the underlying payment — that remains Module 6's exclusive responsibility.
**Related APIs (reference only):** Internal, invoked by Module 6; exposed via `GET /receipts/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Receipt, Payment (reference only, owned by Module 6) — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-047.

---

### FR-048 — Demand Letter Generation

**Preconditions**
- The referenced Debt exists and is not Archived.
- The request originates from an authorized user, Module 5 (Recovery Workflow), or Module 7 (Professional Collection).

**Triggers**
- A user, Recovery Workflow, or Professional Collection requests a Demand Letter against a Debt, selecting one of the four approved templates: First Reminder, Second Reminder, Final Demand, or Legal Notice.

**Main Flow**
1. The requesting user or module selects a Debt and one of the four approved Demand Letter templates.
2. System generates the Demand Letter PDF using the selected template, populated with Debt, Customer, and Company branding details (Module 12 — System Settings).
3. System assigns the Demand Letter a unique Auto Numbering identifier (`DL-000001` format, per BR-036) — shared across all four templates, including Legal Notice, which is a template variant rather than a separate numbered document type (see Scope Boundary).
4. System records a **Demand Letter Generated** event in the Audit Trail (User or "System", Timestamp, Action = Demand Letter Generated, Entity = Debt/Demand Letter).
5. The generated Demand Letter is made available for viewing/download (FR-050, FR-051) and linked to the Debt and, where applicable, the Collection Case (Module 7).

**Alternate Flows**
- **A1 — Request originates from Professional Collection (Module 7):** Same flow; Module 7 requests generation but does not generate the document itself.
- **A2 — Request originates from Recovery Workflow (Module 5):** Same flow.

**Exceptions**
- **E1 — User lacks permission to request Demand Letters:** Action is not available.
- **E2 — Referenced Debt is Archived:** Action is not permitted; the Debt must be restored first (Module 3, FR-023).
- **E3 — Template wording/legal content customization requested:** Deferred to `04_Business_Rules.md` (see Open Items).

**Business Rule References:** BR-020; BR-036 (Auto Numbering, shared across all four templates); template content/wording defined in `04_Business_Rules.md` and managed via Module 12 — System Settings (Document Templates, per BR-035).
**Related APIs (reference only):** `POST /debts/{id}/demand-letters` — see `07_API_Design.md`.
**Related Database Entities (reference only):** DemandLetter, Debt — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-048.

---

### FR-049 — Customer Statement of Account Generation

**Preconditions**
- The referenced Customer exists; user holds permission to generate statements.

**Triggers**
- User requests a Statement of Account from the Customer Profile (Module 2) or Debt Details (Module 3).

**Main Flow**
1. User requests a Statement of Account from either the Customer Profile or a specific Debt's Details screen.
2. System generates the Statement PDF, consolidating the Customer's debt and payment history.
3. System assigns the Statement a unique Auto Numbering identifier (`ST-000001` format, per BR-036).
4. System records a **Statement Generated** event in the Audit Trail.
5. The generated Statement is made available for viewing/download (FR-050, FR-051).

**Alternate Flows**
- **A1 — Requested from Debt Details rather than Customer Profile:** Whether the Statement scope is limited to that single Debt or covers the full Customer is not specified in the approved Feature Freeze — deferred to `04_Business_Rules.md` (see Open Items).

**Exceptions**
- **E1 — User lacks permission:** Action is not available.

**Business Rule References:** BR-021; BR-036 (Auto Numbering).
**Related APIs (reference only):** `POST /customers/{id}/statements`, `POST /debts/{id}/statements` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Statement, Customer, Debt — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-049.

---

### FR-050 — Document Viewing

**Preconditions**
- A Document (Receipt, Demand Letter, or Statement) exists; user holds view permission.

**Triggers**
- User selects a generated document from a Customer Profile, Debt Details, or Collection Case.

**Main Flow**
1. User selects a document.
2. System renders the document for in-app viewing.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks permission:** Access is denied.
- **E2 — Document not found:** System displays a not-found state.

**Business Rule References:** Role-based access per `08_Security_and_RBAC.md`.
**Related APIs (reference only):** `GET /documents/{id}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Receipt, DemandLetter, Statement — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-050.

---

### FR-051 — Document Downloading

**Preconditions**
- A Document exists; user holds view/download permission.

**Triggers**
- User selects "Download" on a viewed document.

**Main Flow**
1. User selects Download.
2. System provides the document as a downloadable PDF file.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks permission:** Action is not available.

**Business Rule References:** Role-based access per `08_Security_and_RBAC.md`; watermarking and digital-signature policy deferred to `04_Business_Rules.md` (see Open Items).
**Related APIs (reference only):** `GET /documents/{id}/download` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Receipt, DemandLetter, Statement — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-051.

---

### FR-052 — Document History

**Preconditions**
- A Document exists; user holds view permission.

**Triggers**
- User requests the history of a document, or of all documents associated with a Debt, Customer, or Collection Case.

**Main Flow**
1. User requests document history.
2. System displays a chronological log of document lifecycle events: **Generated**, **Downloaded**, and **Regenerated** (if regeneration is approved — see Open Items). No additional lifecycle events are introduced.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks permission:** Access is denied.
- **E2 — No documents generated:** System displays an empty-result state.

**Business Rule References:** BRL-003 (attributable action); regeneration policy deferred to `04_Business_Rules.md` (see Open Items).
**Related APIs (reference only):** `GET /documents/{id}/history`, `GET /debts/{id}/documents`, `GET /customers/{id}/documents` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Receipt, DemandLetter, Statement, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-052.

---

## Module 8 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-047 | BR-019 | Module 6 (Payment Tracking — exclusive trigger source) |
| FR-048 | BR-020 | Module 5 (Recovery Workflow); Module 7 (Professional Collection); Module 12 (Document Templates) |
| FR-049 | BR-021 | Module 2 (Customer Profile); Module 3 (Debt Details) |
| FR-050 | BR-019, BR-020, BR-021 | Module 9 (Reporting — document metadata) |
| FR-051 | BR-019, BR-020, BR-021 | — |
| FR-052 | BR-019, BR-020, BR-021, BR-030 | Module 10 (Notifications — document-available events) |

---

## Open Items Identified During Module 8 Specification

The following behaviors are not addressed in the approved Feature Freeze or Business Requirements. None are assumed or invented here; all are deferred to `04_Business_Rules.md`:

1. **Document regeneration policy (FR-052):** Not specified whether a document can be regenerated, and if so, whether regeneration creates a new numbered document or reuses the original number.
2. **Document retention period:** Not specified how long generated documents are retained.
3. **Watermark rules (FR-051):** Not specified whether downloaded PDFs carry a watermark (e.g., "Copy," draft status).
4. **Digital signature policy (FR-051):** Not specified whether generated documents require or support a digital signature.
5. **Numbering format customization:** BR-036 establishes that Debt, Receipt, Demand Letter, Statement, and Collection Case are Auto Numbered, but whether the format itself (prefix, digit count) is tenant-configurable is not specified.
6. **Document template customization scope (FR-048):** Module 12 governs template management (BR-035), but the exact set of customizable fields/wording constraints is not specified.
7. **Legal Notice wording:** Legal content for the Legal Notice template is not specified in the Feature Freeze and would typically require legal review outside SRS scope.
8. **Statement of Account scope when requested from Debt Details (FR-049, A1):** Not specified whether the resulting Statement covers only that Debt or the Customer's full account.

None of the above items change Version 1 scope; they are implementation-level decisions needed to make Module 8 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 8. Approved.**

---

# Module 9 — Reporting & Analytics

## 1. Functional Overview

This module specifies read-only reporting and analytics over data owned by other modules: Aging Analysis, Executive KPI Cards, standard operational reports, report-scoped filtering, and report export. Reporting is strictly passive — it consumes and presents existing records; it never computes new business state, never triggers side effects (notifications, reminders, recovery stage changes, payment changes), and never becomes the system of record for anything it displays.

## Scope Boundary

- **Customer Management (Module 2):** Reporting consumes Customer, Customer Status, and Credit Profile data. It never edits Customer data.
- **Debt Register (Module 3):** Reporting consumes Debt, Debt Status, and Recovery Timeline data. It never edits Debt records.
- **Credit & Risk Management (Module 4):** Reporting consumes Credit Score and Risk Level values. It never recalculates them.
- **Recovery Workflow (Module 5):** Reporting consumes reminder history, Promise to Pay, and Follow-up History. It never creates reminders.
- **Payment Tracking (Module 6):** Reporting consumes Payments, Outstanding Balance, and Payment History. It never records payments.
- **Professional Collection (Module 7):** Reporting consumes Collection Cases, Collection Status, and Collection Outcomes. It never edits Collection Cases.
- **Documents (Module 8):** Reporting consumes Receipt, Demand Letter, and Statement metadata. It never generates documents.
- **Notifications (Module 10):** Not consumed by this module; Reporting never triggers notifications, reminders, recovery stage changes, or payment changes — it is passive.
- **Ownership boundary:** This module owns no business entity. It never owns Customer, Debt, Payment, Collection Case, Document, or Credit Score — those remain owned by Modules 2, 3, 6, 7, 8, and 4 respectively.
- **RBAC:** All reports respect Role-Based Access Control; a user can only report on data their role permits (`08_Security_and_RBAC.md`).

**Scope note — five report categories:** Your message's Functional Scope lists Customer, Debt, Collection, Payment, and Credit Risk Reports as distinct items, but the approved Feature Freeze and Business Requirements only formally specify two report artifacts in detail — Aging Analysis (BR-023) and Executive KPI Cards (BR-024) — plus a general Export capability (BR-025) applying to "all major reports." No column-level or layout-level specification exists for five separate named reports beyond that. To avoid inventing unapproved report logic, this module consolidates the five categories into a single Functional Requirement (FR-055) that presents each entity's already-existing data read-only, rather than defining five distinct new report specifications. Flagging this consolidation rather than silently expanding scope.

**Scope note — Scheduled Reports:** Your message lists this "if already approved." It does not appear anywhere in the approved Feature Freeze or Business Requirements. It is therefore excluded from this module's Functional Requirements and recorded as an Open Item rather than assumed or invented.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-053 | The system shall display Executive KPI Cards on the Customer Mobile App and Super Admin Web Panel dashboards, calculated from existing system data. | BR-024 |
| FR-054 | The system shall categorize outstanding Debts into Aging Analysis buckets (Current, 1–30, 31–60, 61–90, Over 90 days) and present them as a dashboard widget, full report, pie chart, and bar chart. | BR-023 |
| FR-055 | The system shall provide read-only standard reports over Customer, Debt, Collection Case, Payment, and Credit Risk data, without recalculating or duplicating the underlying business logic. | BR-006 |
| FR-056 | The system shall allow an authorized user to filter a report by criteria relevant to that report. | BR-027 |
| FR-057 | The system shall allow an authorized user to export a report as PDF, Excel, or CSV, reflecting exactly the data and filters shown on screen. | BR-025 |

---

### FR-053 — Dashboard Summary (Executive KPI Cards)

**Preconditions**
- User is authenticated; role determines whether the dashboard is tenant-scoped (Customer Mobile App) or system-wide (Super Admin Web Panel).

**Triggers**
- User opens their Dashboard.

**Main Flow**
1. User opens the Dashboard (Customer Mobile App or Super Admin Web Panel).
2. System calculates and displays the approved KPI cards — Total Outstanding Amount, Total Collected (Period), Recovery Rate, Total Overdue Debts, Customers Over Credit Limit, Active Collection Cases (SM-001–006) — scoped to the user's tenant or system-wide, per role.
3. Where applicable, KPI values support historical period selection (day/week/month/year) per BR-024.
4. All values are calculated from existing data owned by Modules 2, 3, 4, 6, and 7; this module introduces no new source data or business logic.

**Alternate Flows**
- **A1 — User selects a different historical period:** Dashboard recalculates and redisplays the same KPIs for the selected period.

**Exceptions**
- **E1 — User's role restricts visibility of certain KPIs:** Restricted cards are not shown, per `08_Security_and_RBAC.md`.

**Business Rule References:** BR-024; KPI calculation timing (real-time vs. periodic) and refresh frequency deferred to `04_Business_Rules.md`.
**Related APIs (reference only):** `GET /dashboard/kpis?period=` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Read-only aggregation over Customer, Debt, Payment, CollectionCase — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-053.

---

### FR-054 — Aging Analysis Report

**Preconditions**
- User holds view permission for reporting.

**Triggers**
- User opens the Aging Analysis dashboard widget or full report.

**Main Flow**
1. User opens Aging Analysis (widget or full report).
2. System categorizes all open Debts into the approved buckets — Current, 1–30 Days, 31–60 Days, 61–90 Days, Over 90 Days — based on each Debt's due date (Module 3).
3. System displays bucket totals as a dashboard widget, a full filterable report, a pie chart (bucket share), and a bar chart (bucket totals), per BR-023.

**Alternate Flows**
- **A1 — User applies filters (customer, date range):** Handled per FR-056, Report Filtering.

**Exceptions**
- **E1 — User lacks permission:** Access is denied.
- **E2 — No open Debts:** System displays an empty/zero-state.

**Business Rule References:** BR-023; exact bucket-boundary rules (e.g., how a partial payment affects bucket placement) deferred to `04_Business_Rules.md`.
**Related APIs (reference only):** `GET /reports/aging-analysis` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Read-only aggregation over Debt (Module 3) — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-054.

---

### FR-055 — Standard Operational Reports

**Preconditions**
- User holds view permission for the relevant entity category.

**Triggers**
- User selects a Customer, Debt, Collection, Payment, or Credit Risk report.

**Main Flow**
1. User selects a report category: Customer, Debt, Collection, Payment, or Credit Risk.
2. System retrieves and displays existing records for the selected category — Customers (Module 2, including Customer Status and Credit Profile), Debts (Module 3, including Debt Status), Collection Cases (Module 7, including status and outcome), Payments (Module 6, including payment history), and Credit Risk data (Module 4, Credit Score and Risk Level) — without recalculating or duplicating any underlying business logic.
3. Results respect RBAC: a user sees only the records and fields their role permits.
4. Results exclude Archived records by default, consistent with the Soft Delete/Archive policy (BRL-004), unless the user explicitly includes them.

**Alternate Flows**
- **A1 — User applies report-scoped filters:** Handled per FR-056.
- **A2 — User exports the report:** Handled per FR-057.

**Exceptions**
- **E1 — User lacks permission for the requested category:** Access is denied, or the category is not shown.
- **E2 — No matching records:** System displays an empty-result state.

**Business Rule References:** BRL-004 (archived-record visibility). This FR strictly consumes data already owned by Modules 2, 3, 4, 6, and 7 and introduces no new computed fields (see Scope Boundary consolidation note).
**Related APIs (reference only):** `GET /reports/customers`, `GET /reports/debts`, `GET /reports/collection-cases`, `GET /reports/payments`, `GET /reports/credit-risk` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Read-only aggregation over Customer, Debt, CollectionCase, Payment — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-055.

---

### FR-056 — Report Filtering

**Preconditions**
- User is viewing a report (FR-053–FR-055).

**Triggers**
- User applies one or more filters to a report.

**Main Flow**
1. User applies filter criteria relevant to the report being viewed (e.g., Customer Status, Debt Status, Recovery Stage, Risk Level, Credit Score, Date Range, Outstanding Amount, Payment Status, Collection Status).
2. System returns the filtered result set, respecting RBAC.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — No matches:** System displays an empty-result state.

**Business Rule References:** This FR specifies only the report-scoped application of filtering; the full cross-module Advanced Search & Filters architecture is specified in Module 11 — Search & Productivity and is not restated here.
**Related APIs (reference only):** Query parameters on the report endpoints in FR-053–FR-055 — see `07_API_Design.md`.
**Related Database Entities (reference only):** None new.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-056.

---

### FR-057 — Report Export

**Preconditions**
- User is viewing a report; user holds export permission.

**Triggers**
- User selects "Export" and a target format (PDF, Excel, or CSV).

**Main Flow**
1. User selects Export and a target format.
2. System generates the export file reflecting exactly the report data and filters currently applied on screen; no export-only calculations are introduced.
3. System provides the file for download.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks export permission:** Action is not available.
- **E2 — Export size exceeds a configured limit:** Exact limit and handling deferred to `04_Business_Rules.md` (see Open Items).

**Business Rule References:** BR-025; export size limits deferred to `04_Business_Rules.md`.
**Related APIs (reference only):** `GET /reports/{reportType}/export?format=` — see `07_API_Design.md`.
**Related Database Entities (reference only):** None new.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-057.

---

## Module 9 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-053 | BR-024 | Module 2 (Customer); Module 3 (Debt); Module 4 (Credit Risk); Module 6 (Payment); Module 7 (Collection) |
| FR-054 | BR-023 | Module 3 (Debt Register) |
| FR-055 | BR-006 (explicit report-filter mention); supports BG-005 broadly across Modules 2–7 data | Modules 2, 3, 4, 6, 7 |
| FR-056 | BR-027 | Module 11 (Search & Productivity) |
| FR-057 | BR-025 | Module 8 (Documents — export as a document-adjacent artifact) |

---

## Open Items Identified During Module 9 Specification

The following behaviors are not addressed in the approved Feature Freeze or Business Requirements. None are assumed or invented here; all are deferred to `04_Business_Rules.md`:

1. **Scheduled Reports:** Not found anywhere in the approved Feature Freeze or Business Requirements. Excluded from this module's Functional Requirements; flagged here rather than silently omitted, per your conditional instruction ("if already approved").
2. **Dashboard refresh frequency / caching (FR-053):** Not specified whether KPI values are real-time or periodically recalculated.
3. **Export size limits (FR-057):** Not specified.
4. **Historical data retention for reporting:** Not specified how far back historical KPI periods (BR-024) extend.
5. **KPI calculation timing (FR-053):** Not specified precisely when Recovery Rate, Total Collected, etc., are computed relative to underlying events.
6. **Archived-record visibility nuance in reports (FR-055):** BRL-004 establishes the default (excluded unless explicitly included); whether each specific report category needs a different default is not specified.
7. **Timezone handling:** Not specified for date-based groupings (Aging Analysis buckets, KPI historical periods).

None of the above items change Version 1 scope; they are implementation-level decisions needed to make Module 9 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 9. Approved.**

---

# Module 10 — Notifications & Calendar

## 1. Functional Overview

This module specifies the in-app Notification Center and Calendar View: the presentation-only surfaces that display business events already generated by other modules. Per the frozen definition in `01_Project_Overview.md` (§1.9, Product Principles, and Glossary), the Notification Center "never generates, schedules, or originates events itself — it exclusively displays events already produced elsewhere in the system," and the Calendar View is "a read-only calendar visualization... aggregated from existing reminder and follow-up data." This module implements exactly that: event consumption, in-app display, read/unread state, filtering, history, and calendar aggregation — nothing more.

## Scope Boundary

- **Debt Register (Module 3):** Owns Debt Due Date and Debt Status. This module only consumes those values for Calendar View and reminder-related notifications; it never edits Debt.
- **Recovery Workflow (Module 5):** Owns reminder stages, Promise to Pay, and Follow-up actions, and — per Module 5, FR-029/FR-030, already approved and frozen — owns the actual triggering of WhatsApp, SMS, and Call reminders. This module never changes Recovery Stages and never independently sends WhatsApp/SMS/Call messages; see the Scope Note below.
- **Payment Tracking (Module 6):** Owns Payment Recorded events. This module may surface an in-app notification after payment; it never records payments.
- **Professional Collection (Module 7):** Owns Collection Cases. This module may notify assigned staff of case-related events; it never edits Collection Cases.
- **Documents (Module 8):** Owns Receipt, Demand Letter, and Statement generation. This module only informs users that a document is available; it never generates documents.
- **Reporting (Module 9):** Consumes notification metadata; this module never creates reports.
- **Administration & Settings (Module 12):** Owns notification templates, provider configuration, calendar configuration, and notification preferences. This module consumes that configuration only.
- **Ownership boundary:** This module owns no business entity. It never owns Customer, Debt, Payment, Collection Case, Document, or Credit Score.
- **Notification History vs. Audit Trail:** Notification History (FR-061) records delivery activity only — which notifications were generated and shown — and never replaces or duplicates the Audit Trail, which remains the authoritative record of business actions (Module 12).

**Scope note — Email Notifications excluded:** Your message's Functional Scope lists "Email Notifications." Email does not appear anywhere in the approved Feature Freeze, Business Requirements, or any previously approved module — the only approved reminder/communication channels are WhatsApp, SMS, and Call (Module 5), plus the in-app Notification Center itself. Introducing Email as a new delivery channel would add scope not present in the frozen baseline. It is therefore excluded from this module's Functional Requirements and recorded as an Open Item rather than implemented.

**Scope note — SMS "sending" is not owned here:** Your message lists "Send SMS Notification" as a Module 10 capability. Per `01_Project_Overview.md` and Module 5 (FR-029, FR-030 — both approved and frozen), the triggering and sending of SMS (and WhatsApp and Call) reminders is already exclusively owned by Module 5 via the Reminder Engine. The Notification Center is explicitly defined as a **consumption-only, in-app** surface. If Module 10 independently sent SMS messages, it would duplicate Module 5's already-approved ownership of that channel and contradict the frozen "consumption-only" definition of the Notification Center. This module therefore implements only the **in-app** display of notifications (including those describing an SMS/WhatsApp/Call reminder that Module 5 already sent); it does not send SMS, WhatsApp, or Email itself. Flagging this rather than silently duplicating Module 5's ownership or silently dropping the requested capability.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-058 | The system shall display an in-app Notification for each qualifying business event emitted by another module, without generating, scheduling, or originating any event itself. | BR-007, BR-017 |
| FR-059 | The system shall allow an authorized user to mark an individual Notification as read, or mark all Notifications as read. | BR-017 |
| FR-060 | The system shall allow an authorized user to filter Notifications by type. | BR-017 |
| FR-061 | The system shall allow an authorized user to view the history of past Notifications, including those already read. | BR-017 |
| FR-062 | The system shall display a read-only Calendar View aggregating Due Dates, Promise to Pay Dates, Call Reminders, Collection Appointments, and other scheduled follow-ups. | BR-016 |

---

### FR-058 — In-App Notification Delivery

**Preconditions**
- A qualifying business event has occurred in another module: Credit Limit Reached (Module 4, FR-028), Payment Received (Module 6, FR-039), Document Available (Module 8), Collection Case Assignment (Module 7, FR-041), Reminder Sent (Module 5, FR-029), or Promise to Pay Due (Module 5, FR-031).

**Triggers**
- The Reminder Engine receives a qualifying event from another module.

**Main Flow**
1. A qualifying event occurs in an owning module (Modules 4–8, as enumerated above).
2. The owning module emits the event to the Reminder Engine.
3. The Reminder Engine creates an in-app Notification entry, linked to the originating entity (Debt, Payment, Document, or Collection Case, as applicable).
4. The Notification appears in the user's Notification Center (Customer Mobile App or Super Admin Web Panel, per role).

**Alternate Flows**
- None; this FR is consumption-only, per the approved Notification Center definition.

**Exceptions**
- **E1 — User's role does not permit visibility of the underlying entity (e.g., a Collection Assignment notification for a case the user cannot access):** The notification is not shown, per `08_Security_and_RBAC.md`.

**Business Rule References:** Implements the Notification Center strictly as defined in `01_Project_Overview.md` (consumption-only; never generates, schedules, or originates events). See Scope Notes above regarding Email and SMS. Duplicate-event suppression (e.g., repeated Credit Limit Reached notifications) inherits the open question already flagged in Module 4, FR-028, and is not re-decided here.
**Related APIs (reference only):** Internal event consumption; exposed via `GET /notifications` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Notification, with read-only references to Debt, Payment, Document, CollectionCase — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-058.

---

### FR-059 — Notification Read/Unread & Mark All as Read

**Preconditions**
- One or more Notifications exist for the user.

**Triggers**
- User opens the Notification Center, or selects "Mark All as Read."

**Main Flow**
1. User opens the Notification Center.
2. System displays each Notification with its Read/Unread state.
3. User may mark an individual Notification as Read, or select "Mark All as Read" to mark every Notification as Read.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — No notifications exist:** System displays an empty state.

**Business Rule References:** None beyond RBAC.
**Related APIs (reference only):** `PATCH /notifications/{id}/read`, `PATCH /notifications/mark-all-read` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Notification — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-059.

---

### FR-060 — Notification Filter by Type

**Preconditions**
- Notifications exist for the user.

**Triggers**
- User applies a type filter within the Notification Center.

**Main Flow**
1. User selects a notification type filter (e.g., Credit Limit Reached, Payment Received, Document Available, Collection Assignment, Reminder Sent, Promise to Pay Due).
2. System displays only Notifications matching the selected type(s).

**Alternate Flows**
- None.

**Exceptions**
- **E1 — No matches:** System displays an empty-result state.

**Business Rule References:** None beyond RBAC.
**Related APIs (reference only):** `GET /notifications?type=` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Notification — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-060.

---

### FR-061 — Notification History

**Preconditions**
- User holds view permission.

**Triggers**
- User requests historical (including already-read) Notifications.

**Main Flow**
1. User requests Notification History.
2. System displays all past Notifications, including read ones, in chronological order.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — No history exists:** System displays an empty state.

**Business Rule References:** This is a delivery-activity log only; it does not replace or duplicate the Audit Trail (Module 12), which remains the authoritative record of business actions.
**Related APIs (reference only):** `GET /notifications/history` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Notification — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-061.

---

### FR-062 — Calendar View

**Preconditions**
- User holds view permission.

**Triggers**
- User opens the Calendar View.

**Main Flow**
1. User opens the Calendar View.
2. System aggregates and displays, on a calendar, all Due Dates (Module 3), Promise to Pay Dates (Module 5), Call Reminders (Module 5), Collection Appointments (Module 7, where recorded), and other Scheduled Follow-ups (Module 5) relevant to the user's permitted data.

**Alternate Flows**
- **A1 — User navigates between calendar periods (day/week/month):** System redisplays the same underlying data for the selected period.

**Exceptions**
- **E1 — No scheduled items:** System displays an empty calendar state.

**Business Rule References:** This FR is a read-only aggregation; Calendar entries never own or modify Recovery Stage or any other business state.
**Related APIs (reference only):** `GET /calendar?from=&to=` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Read-only aggregation over Debt, PromiseToPay, FollowUpHistory, CollectionCase — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-062.

---

## Module 10 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-058 | BR-007, BR-017 | Module 4 (Credit Limit Reached); Module 5 (Reminder Sent, Promise to Pay Due); Module 6 (Payment Received); Module 7 (Collection Assignment); Module 8 (Document Available) |
| FR-059 | BR-017 | — |
| FR-060 | BR-017 | — |
| FR-061 | BR-017 | Module 12 (Audit Trail — distinct, not duplicated) |
| FR-062 | BR-016 | Module 3 (Due Dates); Module 5 (Promise to Pay, Call Reminders, Follow-ups); Module 7 (Collection Appointments) |

---

## Open Items Identified During Module 10 Specification

The following behaviors are not addressed in the approved Feature Freeze or Business Requirements. None are assumed or invented here; all are deferred to `04_Business_Rules.md`:

1. **Email Notifications:** Not an approved channel anywhere in the Feature Freeze or Business Requirements — excluded from this module (see Scope Note above).
2. **SMS/WhatsApp sending ownership:** Already owned by Module 5, not duplicated here (see Scope Note above) — not an open item, but flagged for visibility since it diverges from your message's literal wording.
3. **Retry policy for failed in-app notification delivery:** Not specified.
4. **Delivery priority when multiple notifications occur simultaneously:** Not specified.
5. **Provider failover (SMS/WhatsApp):** This concern belongs to Module 5/Module 12 (provider configuration), not this module's in-app-only scope; redirected rather than addressed here.
6. **Quiet hours (suppressing notification delivery during certain times):** Not specified.
7. **Duplicate suppression for repeated event types:** Inherits the open question already flagged in Module 4, FR-028; not re-decided here.
8. **Notification expiry (auto-archiving old notifications):** Not specified.
9. **Push notification policy (native OS push vs. in-app only):** Not specified whether "in-app" notification implies a native mobile push notification as well.
10. **Timezone handling for Calendar View:** Not specified.
11. **Collection Appointments as a distinct schedulable entity:** Module 7 does not define a distinct "appointment" sub-feature beyond Collection Case, Assignment, and Activity Recording. Calendar View will surface future-dated Collection Activities if recorded as such; exact mechanics deferred to `04_Business_Rules.md`.

None of the above items change Version 1 scope; they are implementation-level decisions needed to make Module 10 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 10. Approved.**

---

# Module 11 — Search & Productivity

## 1. Functional Overview

This module owns the cross-cutting search and filter architecture referenced but not defined by earlier modules: Global Search (referenced by Module 2, FR-015, and Module 9, FR-055) and Advanced Filtering (referenced by Module 2, FR-015, and Module 9, FR-056). It also specifies Quick Actions — the dashboard shortcut mechanism named in the approved Version 1 scope (`01_Project_Overview.md` §1.6). This module consumes data owned entirely by other modules; it never creates, edits, or deletes any business entity.

## Scope Boundary

- **Customer Management (Module 2):** Owns Customer records, Profile, and Status. This module only searches and filters that data; it never edits Customer information.
- **Debt Register (Module 3):** Owns Debt records, Debt Status, and Recovery Timeline. This module consumes searchable Debt metadata only.
- **Credit & Risk Management (Module 4):** Owns Credit Score and Risk Level. This module may search and filter these values; it never recalculates or modifies them.
- **Recovery Workflow (Module 5):** Owns reminder history, Follow-up History, and Promise to Pay. This module may locate workflow records; it never changes workflow state.
- **Payment Tracking (Module 6):** Owns Payments, Outstanding Balance, and Payment History. This module only searches authorized payment records.
- **Professional Collection (Module 7):** Owns Collection Cases and Collection Status. This module provides search and navigation only.
- **Documents (Module 8):** Owns Receipts, Demand Letters, and Statements. This module may locate document records; it never generates documents.
- **Reporting & Analytics (Module 9):** Owns Reports and Dashboard Metrics. This module may provide navigation into reports; it never generates reports.
- **Notifications & Calendar (Module 10):** Owns the Notification Center and Calendar View. This module may locate notification records; it never creates notifications.
- **Ownership boundary:** This module owns no business entity and never becomes the source of truth for Customers, Debts, Credit Scores, Recovery Workflows, Payments, Collection Cases, Documents, Reports, or Notifications.
- **Indexing technology:** Search indexing is an implementation concern (e.g., database indexing strategy) and is not defined in this functional specification; it belongs in technical design, not the SRS.

**Scope note — Saved Views, Recent Activity, and Favorites excluded:** These three items appear in your message's Functional Scope but do not appear anywhere in the approved Version 1 scope. `01_Project_Overview.md` §1.6 (Scope of Version 1, frozen and approved) enumerates the complete Productivity & UX feature set — Notification Center, Calendar View, Global Search, Quick Actions, Advanced Search & Filters, Duplicate Customer Detection, Customer Import — and none of these three appear in it, in the Business Requirements, or in any prior module. Implementing them here would introduce new Version 1 functionality with invented business rules (e.g., how many favorites a user may have, how long recent activity is retained), which the standing instructions direct me not to do. They are recorded as Open Items, not implemented, and flagged as candidates for the Version 2+ Roadmap rather than decided here.

**Scope note — "Quick Navigation" implemented as the approved "Quick Actions":** Your message lists "Quick Navigation" as a distinct item. The approved Version 1 scope names "Quick Actions" (dashboard shortcuts to Add Debt, Receive Payment, Send WhatsApp, Call Customer, Generate Receipt, Generate Statement) — this module implements that approved capability (FR-065). A broader "jump to any recently viewed record" interpretation of Quick Navigation is not separately approved and is not assumed here.

**Numbering note:** Only three Functional Requirements in this module trace to approved scope (Global Search, Advanced Filtering, Quick Actions). To avoid assigning identifiers to unapproved functionality, this module uses FR-063–FR-065 only; FR-066 onward is reserved for Module 12.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-063 | The system shall allow an authorized user to search across Customers, Debts, Payments, Documents, and Collection Cases from a single Global Search entry point. | BR-026 |
| FR-064 | The system shall allow an authorized user to filter operational data by criteria relevant to recovery work, applicable across list and report views. | BR-027 |
| FR-065 | The system shall provide Quick Action shortcuts from the Dashboard into existing workflows, without introducing independent business logic or bypassing the destination workflow's own rules. | BG-005 |

---

### FR-063 — Global Search

**Preconditions**
- User is authenticated.

**Triggers**
- User enters a search term into Global Search, accessible from the Customer Mobile App and Super Admin Web Panel.

**Main Flow**
1. User enters a search term into Global Search.
2. System searches across Customer (Module 2), Debt (Module 3), Payment (Module 6), Receipt/Demand Letter/Statement (Module 8), and Collection Case (Module 7) records for matches against the entered term (e.g., name, phone number, identifier).
3. System returns matching records, grouped by entity type, filtered to only what the requesting user's role permits (RBAC).
4. Archived records are excluded by default, consistent with the Soft Delete/Archive policy (BRL-004), unless the user explicitly includes them.

**Alternate Flows**
- **A1 — User selects a result:** System navigates to that record's detail view in its owning module.

**Exceptions**
- **E1 — No matches:** System displays an empty-result state.
- **E2 — User has no permission to search a given entity type:** That entity type is omitted from results entirely, not merely hidden after retrieval.

**Business Rule References:** BR-026; BRL-004. Search ranking, result ordering, and pagination deferred to `04_Business_Rules.md`. Indexing technology is an implementation concern and is not defined here.
**Related APIs (reference only):** `GET /search?q=` — see `07_API_Design.md`.
**Related Database Entities (reference only):** Read-only aggregation over Customer, Debt, Payment, Receipt, DemandLetter, Statement, CollectionCase — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-063.

---

### FR-064 — Advanced Filtering

**Preconditions**
- User is authenticated and viewing a filterable list or report (Modules 2, 3, 6, 7, 9).

**Triggers**
- User applies one or more filter criteria.

**Main Flow**
1. User applies filter criteria relevant to the list or report being viewed: Customer, Debt Status, Recovery Stage, Risk Level, Credit Score, Date Range, Outstanding Amount, Payment Status, Collection Status.
2. System returns the filtered result set, respecting RBAC and the default Archive exclusion (BRL-004).

**Alternate Flows**
- **A1 — User combines multiple filter criteria:** System applies them cumulatively; exact combination logic (AND vs. OR across values within the same filter) deferred to `04_Business_Rules.md`.

**Exceptions**
- **E1 — No matches:** System displays an empty-result state.

**Business Rule References:** BR-027; BRL-004. This module owns the general cross-cutting filter architecture already referenced (and not restated) by Module 2 (FR-015, Customer Search) and Module 9 (FR-056, Report Filtering).
**Related APIs (reference only):** Shared filter query parameters across `GET /customers`, `GET /debts`, `GET /reports/*` — see `07_API_Design.md`.
**Related Database Entities (reference only):** No new entities; filters existing Customer, Debt, Payment, CollectionCase data — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-064.

---

### FR-065 — Quick Actions

**Preconditions**
- User is authenticated and holds permission for the underlying action.

**Triggers**
- User selects a Quick Action shortcut from the Dashboard.

**Main Flow**
1. User selects a Quick Action shortcut from the Dashboard (Add Debt, Receive Payment, Send WhatsApp, Call Customer, Generate Receipt, Generate Statement).
2. System navigates the user directly into the corresponding workflow already specified in its owning module (Module 3 — Debt Creation; Module 6 — Payment Recording; Module 5 — Manual WhatsApp/Call; Module 8 — Receipt/Statement generation), pre-selecting context where applicable (e.g., a previously selected Customer).
3. The underlying workflow proceeds exactly as specified in its owning module; this FR provides only the shortcut entry point and performs no independent business logic, validation bypass, or data mutation.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — User lacks permission for the underlying action:** The shortcut is not shown, or the destination workflow rejects the action per its own owning module's rules; no separate validation is introduced here.

**Business Rule References:** This FR never bypasses authentication, authorization, or workflow validation owned by the destination module (Modules 3, 5, 6, 8). Approved as part of Version 1 scope per `01_Project_Overview.md` §1.6; no dedicated Business Requirement individually enumerates it — see Open Items regarding this traceability gap.
**Related APIs (reference only):** None new; navigates to existing endpoints of Modules 3, 5, 6, 8 — see `07_API_Design.md`.
**Related Database Entities (reference only):** None new.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-065.

---

## Module 11 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-063 | BR-026 | Module 2 (Customer); Module 3 (Debt); Module 6 (Payment); Module 7 (Collection Case); Module 8 (Documents) |
| FR-064 | BR-027 | Module 2 (FR-015); Module 9 (FR-056) |
| FR-065 | BG-005 (no dedicated BR — see Open Items) | Module 3 (Debt Creation); Module 5 (Manual WhatsApp/Call); Module 6 (Payment Recording); Module 8 (Receipt/Statement) |

---

## Out of Scope (Explicitly Confirmed)

Per your instruction, none of the following appear in this module, consistent with their absence from the approved Feature Freeze: AI Search, Semantic Search, OCR Search, full-text document indexing beyond approved scope, Elasticsearch/OpenSearch/Solr, Vector Search, Voice Search, Natural Language Search, Search Recommendations, Smart Suggestions, or Cross-device Recent Activity Synchronization.

## Open Items Identified During Module 11 Specification

The following behaviors are not addressed in the approved Feature Freeze or Business Requirements. None are assumed or invented here; all are deferred to `04_Business_Rules.md`, except items 1–3, which are scope decisions for the Version 2+ Roadmap rather than Business Rules:

1. **Saved Views:** Not part of approved Version 1 scope (see Scope Note above). Not implemented; candidate for Version 2+ Roadmap if desired.
2. **Recent Activity:** Not part of approved Version 1 scope. Not implemented; candidate for Version 2+ Roadmap if desired.
3. **Favorites:** Not part of approved Version 1 scope. Not implemented; candidate for Version 2+ Roadmap if desired.
4. **Quick Actions traceability gap (FR-065):** This is approved Version 1 scope (`01_Project_Overview.md` §1.6) but has no dedicated Business Requirement in `02_Business_Requirements.md`. Traced here at the Business Goal level (BG-005) instead. `02_Business_Requirements.md` is frozen and not modified by this observation; flagging it for your awareness rather than editing that document.
5. **Search ranking / result ordering (FR-063):** Not specified.
6. **Pagination limits (FR-063, FR-064):** Not specified.
7. **Filter combination logic — AND vs. OR (FR-064, A1):** Not specified.
8. **Filter persistence across sessions (FR-064):** Not specified whether the last-used filter is remembered between sessions.
9. **Default sorting (FR-063, FR-064):** Not specified.
10. **Wildcard / partial-match search behavior (FR-063):** Not specified.

None of the above items change Version 1 scope; they are implementation-level decisions needed to make Module 11 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 11. Approved.**

---

# Module 12 — Administration & Settings

## 1. Functional Overview

This module owns administrative configuration and system governance: user accounts, role assignment, Company Profile/Branding, System Preferences (the configurable policy values every other module reads rather than hardcodes), Lookup & Reference Data, and viewing the Audit Trail. Per the approved architecture, Administration **configures**; business modules **execute**. This module never runs a recovery workflow, records a payment, generates a document, or authenticates a user — it only sets the values and assignments those modules consume.

## Scope Boundary

- **Authentication & User Session (Module 1):** Owns Login, Logout, Password Authentication, Session Management, and the Password Reset process. This module only administers user accounts and assigns roles; it never authenticates users.
- **Customer Management (Module 2):** Owns Customer records and lifecycle. This module may configure customer-related lookup values only; it never edits customer business data.
- **Debt Register (Module 3):** Owns Debt records, lifecycle, and status. This module may configure debt-related lookup values only; it never edits Debt records.
- **Credit & Risk Management (Module 4):** Owns credit policies' *application* and risk scoring computation. This module stores the configurable policy values (e.g., Default Credit Limit) but never calculates or changes Credit Scores.
- **Recovery Workflow (Module 5):** Owns Recovery Stages and follow-up workflow execution. This module maintains configurable reference values (e.g., reminder timing) only; it never executes recovery actions.
- **Payment Tracking (Module 6):** Owns Payments and payment history. This module may configure payment-method reference data only.
- **Professional Collection (Module 7):** Owns Collection Cases. This module never manages collection operations.
- **Documents (Module 8):** Owns Receipts, Demand Letters, and Statements. This module never generates documents; it stores the templates and branding those documents are rendered from.
- **Reporting & Analytics (Module 9):** Owns Reports and Dashboards. This module never creates reports.
- **Notifications & Calendar (Module 10):** Owns the Notification Center and Calendar View. This module exposes only already-approved configuration references (e.g., Notification Settings); it never sends notifications.
- **Search & Productivity (Module 11):** Owns Search, Filters, and Quick Actions execution. This module never manages search execution.
- **Ownership boundary:** This module owns no business entity — it owns only administrative configuration (User accounts, Role assignment, Company Profile, System Preferences, Lookup & Reference Data) and read-only access to the Audit Trail.
- **Permission enforcement:** Role assignment performed here never bypasses Authentication or Authorization; enforcement remains owned by Module 1 and `08_Security_and_RBAC.md`.

**Scope note — Lookup & Reference Data traceability:** This capability is not named as a distinct feature anywhere in the Feature Freeze. It is included because it is the natural, already-implied home for configuration values this SRS previously deferred as Open Items — the Risk Level value set (Module 4), the Payment Method catalog (Module 6), and the Collection Case closure-outcome value set (Module 7) — consistent with the already-approved Product Principle "Configuration over hardcoding" (`01_Project_Overview.md` §1.9, Principle 5; BC-003). It does not introduce any reference-data category beyond those already flagged. Flagging this rather than silently inventing an open-ended admin capability.

## 2. Functional Requirements

| ID | Requirement | Traces To |
|---|---|---|
| FR-066 | The system shall allow an authorized administrator to create, view, update, and deactivate user accounts. | BR-028, BR-029 |
| FR-067 | The system shall allow an authorized administrator to assign or change a user's Role from the six approved roles. | BR-029 |
| FR-068 | The system shall allow an authorized administrator to configure the Company Profile and Branding used on generated documents. | BR-035 |
| FR-069 | The system shall allow an authorized administrator to configure system-wide preferences: Credit Policy, Recovery Policy, Notification Settings, and Document Templates. | BR-034, BR-035, BR-011 |
| FR-070 | The system shall allow an authorized administrator to manage configurable Lookup & Reference Data value sets. | BC-003 |
| FR-071 | The system shall allow an authorized administrator to view the Audit Trail. | BR-030 |

---

### FR-066 — User Administration

**Preconditions**
- Requesting user holds Administration permission (typically Super Admin).

**Triggers**
- Administrator creates, views, updates, or deactivates a user account.

**Main Flow**
1. Administrator creates a new user account (name, identifier — per Module 1, FR-001's configurable identifier type).
2. System creates the User record; exact sequencing of initial credential issuance relative to Role assignment (FR-067) is deferred to `04_Business_Rules.md` (see Open Items).
3. Administrator may view, update, or deactivate an existing user account.
4. System records a **Created** or **Edited** event in the Audit Trail (Entity = User).
5. Deactivation follows the Archive/Restore pattern (BC-002); a user account is never permanently deleted by this action.

**Alternate Flows**
- **A1 — Administrator deactivates the sole holder of a required role (e.g., the only Super Admin):** Exact handling (block vs. warn) is deferred to `04_Business_Rules.md` (see Open Items).

**Exceptions**
- **E1 — Requesting user lacks Administration permission:** Action is not available.
- **E2 — Required fields missing or invalid:** Submission is rejected.

**Business Rule References:** BR-028, BR-029; BC-002 (deactivation follows Archive/Restore); initial credential/invitation mechanism deferred to `04_Business_Rules.md`.
**Related APIs (reference only):** `POST /admin/users`, `GET /admin/users/{id}`, `PUT /admin/users/{id}`, `POST /admin/users/{id}/deactivate` — see `07_API_Design.md`.
**Related Database Entities (reference only):** User, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-066.

---

### FR-067 — Role & Permission Management

**Preconditions**
- User account exists (FR-066); requesting administrator holds permission to assign roles.

**Triggers**
- Administrator assigns or changes a user's Role.

**Main Flow**
1. Administrator selects a user and assigns one of the six approved roles: Super Admin, Operations Manager, Collection Officer, Finance, Support, Viewer.
2. System updates the user's Role assignment.
3. System records a **Role Changed** event in the Audit Trail.
4. Per Module 1, FR-006 (Alternate Flow A1, already approved), the affected user's effective permissions are refreshed to reflect the new Role without requiring re-login; exact refresh timing is governed in `08_Security_and_RBAC.md`.

**Alternate Flows**
- **A1 — User is assigned more than one Role:** Whether multi-role assignment is supported is not specified in the approved Feature Freeze; deferred to `04_Business_Rules.md` (see Open Items).

**Exceptions**
- **E1 — Requesting administrator lacks permission to assign roles:** Action is not available.
- **E2 — Invalid or unrecognized Role selected:** Rejected.

**Business Rule References:** BR-029; BRL-002 (role-restricted actions); detailed role/permission matrix in `08_Security_and_RBAC.md`, already referenced by Module 1.
**Related APIs (reference only):** `PATCH /admin/users/{id}/role` — see `07_API_Design.md`.
**Related Database Entities (reference only):** User, Role, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-067.

---

### FR-068 — Company Profile & Branding

**Preconditions**
- Requesting user holds Administration permission.

**Triggers**
- Administrator updates the Company Profile.

**Main Flow**
1. Administrator submits Company Profile details: business name, logo, address, and contact details (per BR-035).
2. System validates and saves the submitted details.
3. System records an **Edited** event in the Audit Trail (Entity = CompanySettings).
4. Updated branding is reflected on all subsequently generated documents (Module 8 — Demand Letter, Receipt, Statement).

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Requesting user lacks permission:** Action is not available.
- **E2 — Invalid data (e.g., unsupported logo file format):** Rejected with a validation error; exact supported format/size constraints deferred to `04_Business_Rules.md` (see Open Items).

**Business Rule References:** BR-035.
**Related APIs (reference only):** `GET /admin/settings/company-profile`, `PUT /admin/settings/company-profile` — see `07_API_Design.md`.
**Related Database Entities (reference only):** CompanySettings — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-068.

---

### FR-069 — System Preferences

**Preconditions**
- Requesting user holds Administration permission.

**Triggers**
- Administrator updates a configurable system-wide preference.

**Main Flow**
1. Administrator navigates to System Preferences, organized into: Credit Policy (Default Credit Limit, Credit Limit Reminder, Soft Limit Warning threshold — consumed by Modules 2, 3), Recovery Policy (WhatsApp/SMS/Call Reminder Timing — Module 5; Professional Collection Threshold — Module 7), Notification Settings (Module 10), and Document Templates (the four Demand Letter templates — Module 8).
2. Administrator updates one or more preference values.
3. System validates and saves the updated values.
4. System records an **Edited** event in the Audit Trail (Entity = SystemSettings, Field = the specific preference changed).
5. Consuming modules read the updated values on their next evaluation; this module never itself executes a workflow using these values, per the approved architecture principle that Administration configures and business modules execute.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Requesting user lacks permission:** Action is not available.
- **E2 — Invalid value submitted (e.g., a negative reminder interval):** Rejected with a validation error.

**Business Rule References:** BR-034, BR-035, BR-011 (configurable reminder timing); BC-003 (configuration over hardcoding). Exact validation ranges for each preference deferred to `04_Business_Rules.md`.
**Related APIs (reference only):** `GET /admin/settings/preferences`, `PUT /admin/settings/preferences` — see `07_API_Design.md`.
**Related Database Entities (reference only):** SystemSettings, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-069.

---

### FR-070 — Lookup & Reference Data

**Preconditions**
- Requesting user holds Administration permission.

**Triggers**
- Administrator manages a configurable reference value set.

**Main Flow**
1. Administrator manages configurable reference value sets used elsewhere in the system — for example, the Risk Level qualitative value set (Module 4, Open Item), the Payment Method catalog (Module 6, Open Item), and the Collection Case closure-outcome value set (Module 7, Open Item), once each is formally defined in `04_Business_Rules.md`.
2. System validates and saves changes to a reference value set.
3. System records an **Edited** event in the Audit Trail (Entity = ReferenceData).
4. Business validation logic for how these values are applied remains owned by the consuming module (e.g., Module 4 for Risk Level); this module only stores the configurable value set itself.

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Requesting user lacks permission:** Action is not available.
- **E2 — Attempt to remove a reference value currently in use by existing records:** Exact handling (block vs. warn) deferred to `04_Business_Rules.md` (see Open Items).

**Business Rule References:** BC-003 (Product Principle 5, configuration over hardcoding). This FR exists specifically to hold the configurable value sets already flagged as Open Items in Modules 4, 6, and 7 — it does not introduce new reference-data categories beyond those already identified.
**Related APIs (reference only):** `GET /admin/reference-data/{type}`, `PUT /admin/reference-data/{type}` — see `07_API_Design.md`.
**Related Database Entities (reference only):** ReferenceData, AuditLog — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-070.

---

### FR-071 — Audit Trail Viewing

**Preconditions**
- Requesting user holds Administration/audit-view permission.

**Triggers**
- Administrator requests to view the Audit Trail / Activity Log.

**Main Flow**
1. Administrator opens the Audit Trail / Activity Log in the Super Admin Web Panel.
2. System displays all recorded events — Created, Edited, Archived, Restored, Status Changed, Reminder Sent, Payment Added, Collection Requested, Login, Logout, Role Changed, Credit Limit Changed, Credit Score Recalculated, Demand Letter Generated, Receipt Generated, Statement Generated, Recovery Stage Override — each showing User, Timestamp, Action, Entity, and Reason where applicable.
3. Administrator may filter by user, date range, module/entity, or action type, per Module 11's Advanced Filtering architecture (not restated here).

**Alternate Flows**
- None.

**Exceptions**
- **E1 — Requesting user lacks permission:** Access is denied.

**Business Rule References:** BR-030; BRL-003 (attributable action). The Audit Trail is immutable — no update or delete capability is provided anywhere in this module or any other, consistent with BR-030's requirement that audit records cannot be altered by normal users.
**Related APIs (reference only):** `GET /admin/audit-trail` — see `07_API_Design.md`.
**Related Database Entities (reference only):** AuditLog (written by every other module; read-only from this module's perspective) — see `06_Database_Design.md`.
**Acceptance Criteria References:** To be defined in `10_Acceptance_Criteria.md` under FR-071.

---

## Module 12 — Traceability Summary

| FR | Business Requirement(s) | Related Modules |
|---|---|---|
| FR-066 | BR-028, BR-029 | Module 1 (identifier type, permission resolution) |
| FR-067 | BR-029 | Module 1 (FR-006, permission refresh); Module 7 (Collection Officer role) |
| FR-068 | BR-035 | Module 8 (Documents — branding on generated PDFs) |
| FR-069 | BR-034, BR-035, BR-011 | Module 2, 3 (Credit Policy); Module 5 (Recovery Policy); Module 7 (Collection Threshold); Module 8 (Document Templates); Module 10 (Notification Settings) |
| FR-070 | BC-003 (no dedicated BR — see Scope Note) | Module 4 (Risk Level values); Module 6 (Payment Method catalog); Module 7 (Collection outcome values) |
| FR-071 | BR-030 | All modules (as the universal Audit Trail write source) |

---

## Out of Scope (Explicitly Confirmed)

Per your instruction, none of the following appear in this module, consistent with their absence from the approved Feature Freeze: Tenant Management, Subscription Management, Billing Configuration, Feature Flags, API Key Management, self-service Backup & Restore, Email Server Configuration, SMS Gateway Configuration, WhatsApp Provider Configuration, Third-party Integrations, Webhooks, Audit Configuration, Environment Management, Plugin Management, or License Management.

## Open Items Identified During Module 12 Specification

The following behaviors are not addressed in the approved Feature Freeze or Business Requirements. None are assumed or invented here; all are deferred to `04_Business_Rules.md`:

1. **Initial credential/invitation mechanism (FR-066):** Not specified whether an administrator sets an initial password or a self-service invitation link is used.
2. **Deactivating the sole holder of a required role (FR-066, A1):** Not specified.
3. **Multi-role assignment per user (FR-067, A1):** Not specified whether a user may hold more than one Role simultaneously.
4. **Logo/branding file format and size constraints (FR-068):** Not specified.
5. **Validation ranges for each System Preference (FR-069):** Not specified (e.g., minimum/maximum reminder interval).
6. **Removing a reference value currently in use (FR-070):** Not specified whether this is blocked or merely warned.
7. **Lookup & Reference Data traceability (FR-070):** Not a named feature in the Feature Freeze; included as the implementation of the already-approved "configuration over hardcoding" principle (see Scope Note above), not a new capability.

None of the above items change Version 1 scope; they are implementation-level decisions needed to make Module 12 fully unambiguous before `04_Business_Rules.md` is finalized.

---

**End of Module 12. Awaiting review and approval.** This is the final module (12 of 12) — once approved, `03_Functional_Requirements.md` is complete and the SRS proceeds to `04_Business_Rules.md`, not a "Module 13."
