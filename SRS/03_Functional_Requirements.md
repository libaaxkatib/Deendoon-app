# 03. Functional Requirements

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-03 |
| **Document Title** | Functional Requirements |
| **Version** | 0.7 (In Progress) |
| **Status** | Draft — Modules 1–4 Approved; Module 5 of 12 Submitted for Review |
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
| 5 | Recovery Workflow | Submitted for Review |
| 6 | Payment Tracking | Not Started |
| 7 | Professional Collection | Not Started |
| 8 | Documents | Not Started |
| 9 | Reporting & Analytics | Not Started |
| 10 | Notifications & Calendar | Not Started |
| 11 | Search & Productivity | Not Started |
| 12 | Administration & Settings | Not Started |

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

**End of Module 5.** Awaiting review and approval before proceeding to Module 6 — Payment Tracking.
