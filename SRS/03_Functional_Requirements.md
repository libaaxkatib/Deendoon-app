# 03. Functional Requirements

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-03 |
| **Document Title** | Functional Requirements |
| **Version** | 0.1 (In Progress) |
| **Status** | Draft — Module 1 of 12 Submitted for Review |
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

---

## Document Purpose

This document specifies **how** Deendoon Version 1 must behave to satisfy the approved Business Requirements in `02_Business_Requirements.md`. It is organized into twelve functional modules, produced and reviewed one at a time. Each Functional Requirement (FR-xxx) traces to one or more approved Business Requirements (BR-xxx); no FR introduces functionality beyond the approved scope in `01_Project_Overview.md` §1.6.

Detailed field-level business logic is deferred to `04_Business_Rules.md`; screen-level detail is deferred to `05_UI_UX_Specification.md`; data structures to `06_Database_Design.md`; endpoint contracts to `07_API_Design.md`; role/permission matrices to `08_Security_and_RBAC.md`; testable pass/fail conditions to `10_Acceptance_Criteria.md`. References to these documents below are forward references and will be finalized when those documents are produced.

## Module Tracker

| # | Module | Status |
|---|---|---|
| 1 | Authentication & User Session | Submitted for Review |
| 2 | Customer Management | Not Started |
| 3 | Debt Register | Not Started |
| 4 | Credit & Risk Management | Not Started |
| 5 | Recovery Workflow | Not Started |
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

**End of Module 1.** Awaiting review and approval before proceeding to Module 2 — Customer Management.
