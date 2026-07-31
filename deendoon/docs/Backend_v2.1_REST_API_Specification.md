# Backend v2.1 — REST API Specification

**Source of truth:**
- `docs/Mobile_UI_V1_Frozen.md` (UI Version 1.0 — APPROVED, FROZEN, 2026-07-27)
- `docs/Backend_v2.1_UI_Mapping.md` (Backend v2.1 UI Mapping)

This document is an **API contract only**. It defines every endpoint
required to support the frozen UI, exactly as already identified in
`Backend_v2.1_UI_Mapping.md`. No endpoint below exists for any reason
other than a specific, traceable requirement in those two documents. No
UI behavior, business rule, or feature is added, removed, or reinterpreted
here.

> **Amendment note (2026-07-31, Product Vision Amendment, Product Owner Decision).** All Required Permission lines throughout this document previously listed Sales & Finance Staff and Collections Staff alongside Business Owner/Administrator, and some referenced a "manager-level role" — Version 1 has exactly one tenant-level role, the Business Owner, matching `SRS/08_Security_and_RBAC.md` v1.4. Every permission reference now reads "Business Owner" only.
>
> **Second amendment note (2026-07-31, same decision, follow-up correction).** The "Assign Officer" endpoint (formerly §6.5's Case Assignment action) is now marked **Retired** — Version 1 has no second tenant user to assign a Case to, so an endpoint that exists solely to perform that assignment is itself obsolete, not merely mis-permissioned. Content preserved below for history, not deleted. The `assigned_officer` read-only response field on **Get Case Details** is unaffected — the underlying column remains in the schema (approved decision) and continues to be displayed read-only; only the write endpoint is retired.

---

# 1. Introduction

## Purpose

This document specifies the complete REST API contract required to
implement the backend defined in `Backend_v2.1_UI_Mapping.md`, itself
derived from the frozen UI in `Mobile_UI_V1_Frozen.md`. It is the
reference against which Backend Developers implement endpoints, Flutter
Developers integrate against them, and QA Engineers validate them.

## Scope

This specification covers every endpoint identified in
`Backend_v2.1_UI_Mapping.md` Section 11 (API Inventory) and the
per-screen "Required APIs" entries in its Sections 2–6, plus the minimal
authentication endpoints necessary to establish the authenticated,
tenant-scoped session that every one of those endpoints requires. It
does not cover any screen, workflow, or business rule beyond what
`Mobile_UI_V1_Frozen.md` specifies.

## API Design Principles

- **One endpoint, one purpose.** No endpoint serves more than one screen
  requirement; where two screens require the same data, they call the
  same shared endpoint (Section 8) rather than each getting a duplicate.
- **Traceable.** Every endpoint's heading cites the frozen UI section
  that requires it.
- **Consistent envelope.** Every response — success or error — uses the
  single response structure defined in Section 9, with no per-module
  variation.
- **Tenant-scoped by default.** Every endpoint in this document operates
  within the authenticated user's own tenant; no endpoint returns or
  accepts data belonging to another tenant, per `Mobile_UI_V1_Frozen.md`
  §11's Tenant Isolation rule.
- **No endpoint without a citation.** If a capability is not required by
  the frozen UI, it is not in this document, regardless of how
  conventional it might be in a typical REST API.

## Authentication Strategy

The API uses bearer-token authentication. A client obtains a token via
the Login endpoint (Section 2), presents it on every subsequent request
in the `Authorization` header, and renews it via the Refresh endpoint
before it expires. `Mobile_UI_V1_Frozen.md` §4 documents the Home
Dashboard as the application's "entry point after login," establishing
login as a precondition for every screen this specification supports;
every other endpoint in this document requires a valid token unless
explicitly marked otherwise. Token lifetime, refresh, and related
security properties are defined in full in Section 11.

---

# 2. Authentication APIs

Scope note: `Mobile_UI_V1_Frozen.md` does not document a login screen's
UI (it begins at the Home Dashboard, "the first screen presented after
login"), so this section defines only the minimal endpoints necessary to
issue, renew, and end the authenticated session every other endpoint in
this document depends on — not a full account-management feature set.

## Login

- **Endpoint Name:** Login
- **HTTP Method:** POST
- **URL:** `/api/v1/auth/login`
- **Purpose:** Authenticate a user and issue an access token, establishing
  the session required to enter the Home Dashboard.
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| email | string | Yes | The user's account email address |
| password | string | Yes | The user's account password |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| access_token | string | Bearer token for subsequent requests |
| refresh_token | string | Token used to obtain a new access token |
| expires_in | integer | Access token lifetime, in seconds |
| user | object | Authenticated user's id, name, role, and tenant_id |

- **Success Responses:** `200 OK` — see Section 9 Standard Success
  Response.
- **Error Responses:** `422 Validation Error` (missing/malformed fields);
  `401 Unauthorized` (invalid credentials); `429 Rate Limited` (excessive
  attempts).
- **Required Permission:** None (public endpoint).

## Refresh Token

- **Endpoint Name:** Refresh Token
- **HTTP Method:** POST
- **URL:** `/api/v1/auth/refresh`
- **Purpose:** Exchange a valid refresh token for a new access token
  without requiring the user to re-enter credentials.
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| refresh_token | string | Yes | A previously issued, unexpired refresh token |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| access_token | string | New bearer token |
| expires_in | integer | New access token lifetime, in seconds |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized` (refresh token invalid,
  expired, or revoked).
- **Required Permission:** None (requires a valid refresh token, not an
  access token).

## Logout

- **Endpoint Name:** Logout
- **HTTP Method:** POST
- **URL:** `/api/v1/auth/logout`
- **Purpose:** Invalidate the current access and refresh tokens, ending
  the authenticated session.
- **Request Fields:** None.
- **Response Fields:** None (`data` is `null`).
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized` (no valid session to end).
- **Required Permission:** Authenticated.

---

# 3. Dashboard APIs

*Supports `Mobile_UI_V1_Frozen.md` §4 (Home Dashboard) and its components
§4.1–4.5, per `Backend_v2.1_UI_Mapping.md` Section 2.*

## Get Business Health

- **Endpoint Name:** Get Business Health
- **HTTP Method:** GET
- **URL:** `/api/v1/dashboard/business-health`
- **Purpose:** Retrieve the current Business Health score and status
  band (§4.1).
- **Request Fields:** None.
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| score | integer | Composite score, 0–100 |
| status_band | string enum | `healthy` \| `needs_attention` \| `at_risk` |
| status_label | string | Display label matching the status band |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `500 Server Error`.
- **Required Permission:** Business Owner.

## Get Dashboard KPIs

- **Endpoint Name:** Get Dashboard KPIs
- **HTTP Method:** GET
- **URL:** `/api/v1/dashboard/kpis`
- **Purpose:** Retrieve the four headline KPI cards with their
  month-over-month deltas (§4.2).
- **Request Fields:** None.
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| total_outstanding | object | `{ value, delta_percentage, delta_direction }` |
| collected_this_month | object | `{ value, delta_percentage, delta_direction }` |
| overdue_amount | object | `{ value, delta_percentage, delta_direction }` |
| high_risk_customers | object | `{ value, delta_percentage, delta_direction }` |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `500 Server Error`.
- **Required Permission:** Business Owner.

## Get Today's Overview

- **Endpoint Name:** Get Today's Overview
- **HTTP Method:** GET
- **URL:** `/api/v1/dashboard/todays-overview`
- **Purpose:** Retrieve today's follow-up workload counts (§4.3). Reuses
  the Reminder Summary data documented in Section 6.
- **Request Fields:** None.
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| reminders_due_today | integer | Total reminders due today, status not Completed |
| payments_due | integer | Payment Due-type reminders due today |
| client_visits | integer | Client Visit-type reminders due today |
| follow_up_calls | integer | Follow-up Call-type reminders due today |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `500 Server Error`.
- **Required Permission:** Business Owner.

## Get Recent Cases

- **Endpoint Name:** Get Recent Cases
- **HTTP Method:** GET
- **URL:** `/api/v1/dashboard/recent-cases`
- **Purpose:** Retrieve a small, most-recently-active-first preview of
  cases (§4.5).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| limit | integer | No | Preview count; defaults to a small fixed number |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| cases | array | List of `{ case_id, customer_name, outstanding_amount, risk_level, last_activity_at }` |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `500 Server Error`.
- **Required Permission:** Business Owner.

## Quick Actions

§4.4's four Quick Actions do not have dedicated dashboard endpoints —
each delegates directly to its owning module's creation endpoint, per
`Backend_v2.1_UI_Mapping.md` §4.4:

| Quick Action | Delegates To |
|---|---|
| Add Case | Create Case — Section 5 |
| Add Payment | Record Payment — Section 5 |
| Scan Invoice | Invoice Scan Capture — Section 8 |
| Send Message | Render Message / Send via WhatsApp / Send via SMS — Section 8 |

---

# 4. Analytics APIs

*Supports `Mobile_UI_V1_Frozen.md` §5 (Analytics) and its components
§5.1–5.6, per `Backend_v2.1_UI_Mapping.md` Section 3.*

## Get Analytics Overview

- **Endpoint Name:** Get Analytics Overview
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/overview`
- **Purpose:** Retrieve the composed Collection Analytics and Aging
  Analysis figures for a date range (§5.1).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| date_from | date | No | Range start; defaults to current period |
| date_to | date | No | Range end; defaults to current period |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| collection_analytics | object | See Get Collection Analytics KPIs |
| aging_analysis | object | See Get Aging Analysis |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (date_to before date_from);
  `401 Unauthorized`; `500 Server Error`.
- **Required Permission:** Business Owner.

## Get Customers Report

- **Endpoint Name:** Get Customers Report
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/reports/customers`
- **Purpose:** Retrieve the filterable Customers report (§5.2).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| status | string | No | Customer status filter |
| risk_level | string enum | No | `high` \| `medium` \| `low` |
| page, per_page | integer | No | Pagination — see Section 10 |
| sort | string | No | Sort field and direction — see Section 10 |

- **Response Fields:** Paginated list of customer records; see Section
  10 for the pagination envelope shape.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Debts Report

- **Endpoint Name:** Get Debts Report
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/reports/debts`
- **Purpose:** Retrieve the filterable Debts report (§5.2).
- **Request Fields:** `status`, `date_from`, `date_to`, `page`,
  `per_page`, `sort`.
- **Response Fields:** Paginated list of debt records.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Collection Cases Report

- **Endpoint Name:** Get Collection Cases Report
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/reports/collection-cases`
- **Purpose:** Retrieve the filterable Collection Cases report (§5.2).
- **Request Fields:** `status`, `page`, `per_page`, `sort`.
- **Response Fields:** Paginated list of case records.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Payments Report

- **Endpoint Name:** Get Payments Report
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/reports/payments`
- **Purpose:** Retrieve the filterable Payments report (§5.2).
- **Request Fields:** `date_from`, `date_to`, `page`, `per_page`, `sort`.
- **Response Fields:** Paginated list of payment records.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Credit Risk Report

- **Endpoint Name:** Get Credit Risk Report
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/reports/credit-risk`
- **Purpose:** Retrieve the Credit Risk report (§5.2) — customers ordered
  by risk indicators.
- **Request Fields:** `risk_level`, `page`, `per_page`, `sort`.
- **Response Fields:** Paginated list of customer records with credit
  risk fields.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Export Report

- **Endpoint Name:** Export Report
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/reports/{report_type}/export`
- **Purpose:** Export the filtered dataset of any report above as a
  downloadable file (§5.2).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| report_type | string (path) | Yes | One of: customers, debts, collection-cases, payments, credit-risk, aging-analysis |
| format | string enum | Yes | `csv` \| `xlsx` |
| *(all filters accepted by the corresponding report above)* | — | No | Same filters applied to the export |

- **Response Fields:** Binary file stream (not a JSON envelope).
- **Success Responses:** `200 OK` with the file attached.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`; `404
  Not Found` (unknown report_type).
- **Required Permission:** Business Owner.

## Get Collections Trend

- **Endpoint Name:** Get Collections Trend
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/trends`
- **Purpose:** Retrieve a time-series of a selected metric across a date
  range (§5.3).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| date_from | date | Yes | Range start |
| date_to | date | Yes | Range end |
| metric | string enum | Yes | `collected_amount` \| `outstanding_amount` \| `risk_concentration` |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| metric | string | Echoes the requested metric |
| series | array | List of `{ date, value }`, one point per interval |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (invalid range or metric);
  `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Collection Analytics KPIs

- **Endpoint Name:** Get Collection Analytics KPIs
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/collection-kpis`
- **Purpose:** Retrieve Collection Rate, Total Collected, and Average
  Days for a date range (§5.4).
- **Request Fields:** `date_from`, `date_to` (optional, default to
  current period).
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| collection_rate | object | `{ value_percentage, delta }` |
| total_collected | object | `{ value, delta }` |
| average_days | object | `{ value, delta }` |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Aging Analysis

- **Endpoint Name:** Get Aging Analysis
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/aging-analysis`
- **Purpose:** Retrieve open-debt distribution across age brackets
  (§5.5).
- **Request Fields:** `date_from`, `date_to` (optional).
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| total_remaining_balance | number | Sum across all open debts |
| buckets | array | `{ bracket, count, total_remaining_balance, percentage }` for Current, 1–30, 31–60, 61–90, 90+ |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Risk Distribution

- **Endpoint Name:** Get Risk Distribution
- **HTTP Method:** GET
- **URL:** `/api/v1/analytics/risk-distribution`
- **Purpose:** Retrieve the active customer base's distribution across
  risk classifications (§5.6).
- **Request Fields:** None.
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| segments | array | `{ risk_level, customer_count, percentage }` for High, Medium, Low |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Business Owner.

---

# 5. Cases APIs

*Supports `Mobile_UI_V1_Frozen.md` §6 (Cases) and its components
§6.1–6.5, per `Backend_v2.1_UI_Mapping.md` Section 4.*

## List Cases

- **Endpoint Name:** List Cases
- **HTTP Method:** GET
- **URL:** `/api/v1/cases`
- **Purpose:** Retrieve the filterable, paginated Case List (§6.1, §6.2).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| tab | string enum | No | `all` \| `high_risk` \| `follow_up` \| `promise_due`; defaults to `all` |
| page, per_page | integer | No | Pagination — Section 10 |
| sort | string | No | Section 10 |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| total_count | integer | Count matching the active tab |
| cases | array | `{ case_id, customer_name, avatar_initial, outstanding_amount, status_pill, risk_badge, last_activity_at }` |
| pagination | object | Section 10 |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (unknown tab value); `401
  Unauthorized`.
- **Required Permission:** Business Owner.

## Create Case

- **Endpoint Name:** Create Case
- **HTTP Method:** POST
- **URL:** `/api/v1/cases`
- **Purpose:** Create a new case (Home §4.4 "Add Case" Quick Action).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| customer_id | string | Yes | The customer this case belongs to |
| debt_id | string | Yes | The debt this case tracks |

- **Response Fields:** The created case object, same shape as List
  Cases' item.
- **Success Responses:** `201 Created`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`; `403
  Forbidden`.
- **Required Permission:** Business Owner.

## Get Case Details

- **Endpoint Name:** Get Case Details
- **HTTP Method:** GET
- **URL:** `/api/v1/cases/{case_id}`
- **Purpose:** Retrieve the complete profile of a single case (§6.3).
- **Request Fields:** `case_id` (path).
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| case_id | string | — |
| customer_name | string | — |
| case_reference | string | — |
| outstanding_amount | number | — |
| risk_level | string | — |
| case_status | string | — |
| assigned_officer | object \| null | `{ user_id, name }` |
| debt_summary | object | Debt fields relevant to the case |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`.
- **Required Permission:** Same as List Cases.

## Get Case Timeline

- **Endpoint Name:** Get Case Timeline
- **HTTP Method:** GET
- **URL:** `/api/v1/cases/{case_id}/timeline`
- **Purpose:** Retrieve the full chronological activity history of a
  case (§6.4).
- **Request Fields:** `case_id` (path); `page`, `per_page` (optional).
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| timeline | array | `{ icon_type, description, actor_name, occurred_at, related_record_type, related_record_id }`, reverse-chronological |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`.
- **Required Permission:** Same as List Cases.

## Record Payment

- **Endpoint Name:** Record Payment
- **HTTP Method:** POST
- **URL:** `/api/v1/cases/{case_id}/payments`
- **Purpose:** Record a payment against a case's debt (§6.5).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| amount | number | Yes | Payment amount |
| payment_date | date | Yes | Date the payment was received |
| payment_method | string | Yes | Payment method used |
| notes | string | No | — |

- **Response Fields:** The created payment record and the case's
  updated summary.
- **Success Responses:** `201 Created`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`; `403
  Forbidden`; `404 Not Found`; `409 Conflict` (case not in a status that
  permits recording a payment).
- **Required Permission:** Business Owner.

## Assign Officer

> **Retired (Product Vision Amendment, Product Owner Decision, 2026-07-31).** Version 1 has exactly one account per tenant (the Business Owner), so there is no second tenant user to assign a Case to, and Collections Staff/Collection Officer is no longer a tenant-side role — matching the retirement already recorded for `SRS/03_Functional_Requirements.md` FR-041, `SRS/05_UI_UX_Specification.md` SCR-026, and `SRS/10_Acceptance_Criteria.md` AC-041. This endpoint does not exist in the active API and must not be implemented. Preserved below for history, not deleted, per this project's Documentation Rules.

- **Endpoint Name:** Assign Officer
- **HTTP Method:** PATCH
- **URL:** `/api/v1/cases/{case_id}/assign-officer`
- **Purpose:** Assign a Collections Staff member to a case (§6.5).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| officer_user_id | string | Yes | The user to assign |

- **Response Fields:** The updated case object.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`; `403
  Forbidden`; `404 Not Found`.
- **Required Permission:** Business Owner.

## Escalate Case

- **Endpoint Name:** Escalate Case
- **HTTP Method:** POST
- **URL:** `/api/v1/cases/{case_id}/escalate`
- **Purpose:** Escalate a case, triggering Demand Letter generation
  (§6.5; `Mobile_UI_V1_Frozen.md` §8.4's escalation-triggered rule).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| reason | string | No | Free-text escalation reason |

- **Response Fields:** The updated case object and the generated Demand
  Letter's document_id.
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`; `409 Conflict` (case status does not permit escalation).
- **Required Permission:** Business Owner.

## Close Case

- **Endpoint Name:** Close Case
- **HTTP Method:** POST
- **URL:** `/api/v1/cases/{case_id}/close`
- **Purpose:** Close a case with a recorded outcome (§6.5).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| closure_outcome | string | Yes | Required outcome for the closure |

- **Response Fields:** The updated case object.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (missing closure_outcome);
  `401 Unauthorized`; `403 Forbidden`; `404 Not Found`; `409 Conflict`
  (case already closed).
- **Required Permission:** Business Owner.

---

# 6. Reminder APIs

*Supports `Mobile_UI_V1_Frozen.md` §7 (Reminder Center) and its
components §7.1–7.9, per `Backend_v2.1_UI_Mapping.md` Section 5.*

## Get Reminder Summary

- **Endpoint Name:** Get Reminder Summary
- **HTTP Method:** GET
- **URL:** `/api/v1/reminders/summary`
- **Purpose:** Retrieve today's total due count, per-type sub-counts, and
  Overdue count (§7.1). Also used by Get Today's Overview (Section 3).
- **Request Fields:** None.
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| total_due_today | integer | — |
| per_type | object | `{ client_visit, follow_up_call, payment_due, contract_renewal, promise_to_pay }` counts |
| overdue_count | integer | — |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Business Owner.

## List Reminders

- **Endpoint Name:** List Reminders
- **HTTP Method:** GET
- **URL:** `/api/v1/reminders`
- **Purpose:** Retrieve the filterable Reminder List (§7.3). Also
  accepts the `search` parameter defined in Section 8.
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| tab | string enum | No | `all` \| `today` \| `upcoming` \| `overdue` \| `completed`; defaults to `all` |
| search | string | No | Free-text search — see Section 8 |
| page, per_page | integer | No | Section 10 |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| reminders | array | `{ reminder_id, type, title, related_entity_name, due_label, status, available_actions }` |
| pagination | object | Section 10 |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Same as Get Reminder Summary.

## Get Reminder Details

- **Endpoint Name:** Get Reminder Details
- **HTTP Method:** GET
- **URL:** `/api/v1/reminders/{reminder_id}`
- **Purpose:** Retrieve the complete detail of a single reminder (§7.4).
- **Request Fields:** `reminder_id` (path).
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| reminder_id | string | — |
| type | string enum | `client_visit` \| `follow_up_call` \| `payment_due` \| `contract_renewal` \| `promise_to_pay` |
| title | string | — |
| related_entity | object | `{ type, id, name }` |
| due_date | datetime | — |
| amount_due | number \| null | Present only for `payment_due` and `promise_to_pay` types |
| related_case_id | string \| null | — |
| created_by | object | `{ user_id, name }` |
| created_on | datetime | — |
| notes | string \| null | — |
| status | string enum | `today` \| `upcoming` \| `overdue` \| `completed` |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`.
- **Required Permission:** Same as Get Reminder Summary.

## Create Reminder

- **Endpoint Name:** Create Reminder
- **HTTP Method:** POST
- **URL:** `/api/v1/reminders`
- **Purpose:** Create a new reminder (§7.5).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| type | string enum | Yes | One of the five defined Reminder Types (§7.2) |
| related_entity_type | string | Yes | The entity this reminder relates to |
| related_entity_id | string | Yes | — |
| due_date | datetime | Yes | — |
| timing_rule | string enum | Yes | `one_day_before` \| `same_day` \| `one_hour_before` \| `custom` |
| custom_fire_at | datetime | Conditional | Required if `timing_rule` is `custom`; must be on or before `due_date` |
| delivery_methods | array of string enum | Yes | At least one of: `in_app`, `push`, `whatsapp`, `sms` |
| notes | string | No | — |

- **Response Fields:** The created reminder, same shape as Get Reminder
  Details.
- **Success Responses:** `201 Created`.
- **Error Responses:** `422 Validation Error` (missing timing option,
  missing custom date/time, zero delivery methods selected); `401
  Unauthorized`; `403 Forbidden`.
- **Required Permission:** Same as Get Reminder Summary.

## Update Reminder

- **Endpoint Name:** Update Reminder
- **HTTP Method:** PUT
- **URL:** `/api/v1/reminders/{reminder_id}`
- **Purpose:** Edit a reminder's details, or reschedule it, retaining its
  original Created By/Created On (§7.4, §7.5, §7.9).
- **Request Fields:** Same fields as Create Reminder (all optional on
  update; unspecified fields are unchanged).
- **Response Fields:** The updated reminder.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`; `403
  Forbidden` (not the creator); `404 Not Found`.
- **Required Permission:** The reminder's creator.

## Delete Reminder

- **Endpoint Name:** Delete Reminder
- **HTTP Method:** DELETE
- **URL:** `/api/v1/reminders/{reminder_id}`
- **Purpose:** Permanently remove a reminder from every view (§7.4).
- **Request Fields:** `reminder_id` (path).
- **Response Fields:** None (`data` is `null`).
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`.
- **Required Permission:** The reminder's creator.

## Complete Reminder

- **Endpoint Name:** Complete Reminder
- **HTTP Method:** PATCH
- **URL:** `/api/v1/reminders/{reminder_id}/complete`
- **Purpose:** Mark a reminder as Completed (§7.3, §7.4).
- **Request Fields:** None.
- **Response Fields:** The updated reminder, with `status: "completed"`.
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`; `409 Conflict` (already Completed).
- **Required Permission:** Same as Get Reminder Summary.

## Send Reminder

- **Endpoint Name:** Send Reminder
- **HTTP Method:** POST
- **URL:** `/api/v1/reminders/{reminder_id}/send`
- **Purpose:** Immediately dispatch a reminder via a specified channel,
  used by the Reminder List's inline "Send Reminder" action (§7.3) and
  by Reminder Details' "Send Reminder" button after confirming via
  WhatsApp/SMS Preview (§7.4, §7.7, §7.8).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| channel | string enum | Yes | `whatsapp` \| `sms` |
| template_id | string | Yes | The template used to render the message — see Section 8 |

- **Response Fields:** `{ sent_message_id, status, sent_at }` — see
  Section 8's Send via WhatsApp / Send via SMS for the full shape.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (no valid recipient phone
  number for the channel); `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`.
- **Required Permission:** Same as Get Reminder Summary.

## Get Calendar

- **Endpoint Name:** Get Calendar
- **HTTP Method:** GET
- **URL:** `/api/v1/calendar`
- **Purpose:** Retrieve the aggregated dated items for the Smart Calendar
  (§7.6).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| from | date | Yes | Range start |
| to | date | Yes | Range end |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| entries | array | `{ date, type, related_entity_type, related_entity_id, label }`, covering all five reminder types plus Payment Due and Promise to Pay dates |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## WhatsApp Preview and SMS Preview

§7.7 and §7.8's "Preview" screens are populated by the Get Message
Templates and Render Message endpoints, and their send buttons invoke
Send via WhatsApp / Send via SMS — all four are shared across Reminder
Center and Documents and are fully specified in Section 8, to avoid
duplicating the same contract twice.

## Reminder Workflow

§7.9 introduces no additional endpoint. Its lifecycle (Schedule → Send →
Complete → Reschedule, and the Overdue condition) is expressed entirely
through the endpoints above: Create Reminder (Schedule), Send Reminder /
Send via WhatsApp / Send via SMS (Send), Complete Reminder (Complete),
and Update Reminder (Reschedule).

---

# 7. Documents APIs

*Supports `Mobile_UI_V1_Frozen.md` §8 (Documents) and its components
§8.1–8.8, per `Backend_v2.1_UI_Mapping.md` Section 6.*

## List Documents

- **Endpoint Name:** List Documents
- **HTTP Method:** GET
- **URL:** `/api/v1/documents`
- **Purpose:** Retrieve the type-filterable, searchable document list
  (§8.1).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| type | string enum | No | `all` \| `invoices` \| `receipts` \| `letters` \| `other`; defaults to `all` |
| search | string | No | Free-text search — Section 8 |
| page, per_page | integer | No | Section 10 |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| documents | array | `{ document_id, type, filename, descriptor, generated_at, file_size }` |
| pagination | object | Section 10 |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Business Owner.

## Get Storage Usage

- **Endpoint Name:** Get Storage Usage
- **HTTP Method:** GET
- **URL:** `/api/v1/documents/storage-usage`
- **Purpose:** Retrieve the tenant's document storage consumption
  against its quota (§8.1).
- **Request Fields:** None.
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| used_bytes | integer | — |
| total_bytes | integer | — |
| used_percentage | number | — |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Same as List Documents.

## List Invoices

- **Endpoint Name:** List Invoices
- **HTTP Method:** GET
- **URL:** `/api/v1/documents/invoices`
- **Purpose:** Retrieve all invoice documents (§8.2).
- **Request Fields:** `page`, `per_page`.
- **Response Fields:** Paginated list of invoice records.
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Same as List Documents.

## List Receipts

- **Endpoint Name:** List Receipts
- **HTTP Method:** GET
- **URL:** `/api/v1/documents/receipts`
- **Purpose:** Retrieve all receipt documents (§8.3).
- **Request Fields:** `page`, `per_page`.
- **Response Fields:** Paginated list of receipt records.
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Same as List Documents.

## List Demand Letters

- **Endpoint Name:** List Demand Letters
- **HTTP Method:** GET
- **URL:** `/api/v1/documents/demand-letters`
- **Purpose:** Retrieve all demand letter documents (§8.4).
- **Request Fields:** `page`, `per_page`.
- **Response Fields:** Paginated list of demand letter records.
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Same as List Documents.

## List Statements

- **Endpoint Name:** List Statements
- **HTTP Method:** GET
- **URL:** `/api/v1/documents/statements`
- **Purpose:** Retrieve all account statement documents (§8.5).
- **Request Fields:** `page`, `per_page`.
- **Response Fields:** Paginated list of statement records.
- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Same as List Documents.

## Get Document (Preview)

- **Endpoint Name:** Get Document
- **HTTP Method:** GET
- **URL:** `/api/v1/documents/{document_id}`
- **Purpose:** Retrieve the full content of a single document,
  regardless of its underlying type (§8.6).
- **Request Fields:** `document_id` (path).
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| document_id | string | — |
| type | string enum | `invoice` \| `receipt` \| `demand_letter` \| `statement` |
| reference_number | string | — |
| generated_at | datetime | — |
| content_url | string | Location of the immutable, already-generated content |
| related_entity | object | The customer, debt, or payment this document relates to |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`.
- **Required Permission:** Same as List Documents.

## Download Document

- **Endpoint Name:** Download Document
- **HTTP Method:** GET
- **URL:** `/api/v1/documents/{document_id}/download`
- **Purpose:** Download a document's file, recording the download event
  (§8.7).
- **Request Fields:** `document_id` (path).
- **Response Fields:** Binary file stream (not a JSON envelope).
- **Success Responses:** `200 OK` with the file attached.
- **Error Responses:** `401 Unauthorized`; `403 Forbidden`; `404 Not
  Found`.
- **Required Permission:** Same as List Documents.

## Share Document

- **Endpoint Name:** Share Document
- **HTTP Method:** POST
- **URL:** `/api/v1/documents/{document_id}/share`
- **Purpose:** Send a document to a customer via WhatsApp or SMS,
  recording the share event (§8.8). Internally reuses Send via WhatsApp
  / Send via SMS (Section 8).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| channel | string enum | Yes | `whatsapp` \| `sms` |
| recipient_phone | string | Yes | Must be present and valid for the selected channel |
| template_id | string | No | Defaults to the document type's standard sharing template |

- **Response Fields:** `{ sent_message_id, status, sent_at }`.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (missing/invalid recipient
  contact); `401 Unauthorized`; `403 Forbidden`; `404 Not Found`.
- **Required Permission:** Same as List Documents.

---

# 8. Shared APIs

Endpoints used by more than one module, documented once here and
referenced by name from Sections 3–7. Only endpoints required by the
frozen UI are included.

## Search

Search is not a separate endpoint. It is a shared query parameter,
`search`, accepted by List Reminders (Section 6, per §7.1's search
icon) and List Documents (Section 7, per §8.1's search icon). No
cross-entity global search exists, because the frozen UI shows a search
icon scoped to each screen's own list, not a unified search screen.

## Invoice Scan Capture

- **Endpoint Name:** Invoice Scan Capture
- **HTTP Method:** POST
- **URL:** `/api/v1/documents/invoices/scan`
- **Purpose:** Upload a captured invoice image or file, behind the Home
  Dashboard's "Scan Invoice" Quick Action (§4.4) — the one file-upload
  action required by the frozen UI.
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| file | file (multipart) | Yes | The captured invoice image or document |
| customer_id | string | No | Associates the capture with a known customer, if selected |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| invoice_id | string | — |
| status | string enum | `processing` \| `captured` |

- **Success Responses:** `201 Created`.
- **Error Responses:** `422 Validation Error` (missing or unreadable
  file); `401 Unauthorized`.
- **Required Permission:** Same permission required by the Home
  Dashboard's Quick Actions (§4.4).

## Get Message Templates

- **Endpoint Name:** Get Message Templates
- **HTTP Method:** GET
- **URL:** `/api/v1/message-templates`
- **Purpose:** Retrieve available message templates, used by WhatsApp
  Preview and SMS Preview (§7.7, §7.8) and Document Share (§8.8).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| channel | string enum | No | `whatsapp` \| `sms`; filters templates applicable to that channel |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| templates | array | `{ template_id, name, channel, body_with_placeholders }` |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Same as Get Reminder Summary (Section 6).

## Render Message

- **Endpoint Name:** Render Message
- **HTTP Method:** POST
- **URL:** `/api/v1/messages/render`
- **Purpose:** Substitute live data into a selected template, producing
  the exact text shown in WhatsApp/SMS Preview (§7.7, §7.8).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| template_id | string | Yes | — |
| reminder_id | string | Conditional | Provide when rendering for a reminder |
| case_id | string | Conditional | Provide when rendering for a case |
| document_id | string | Conditional | Provide when rendering for a document share |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| rendered_text | string | The fully substituted message body |
| recipient_name | string | — |
| recipient_phone | string | — |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (no matching source
  entity supplied); `401 Unauthorized`; `404 Not Found`.
- **Required Permission:** Same as Get Reminder Summary.

## Send via WhatsApp

- **Endpoint Name:** Send via WhatsApp
- **HTTP Method:** POST
- **URL:** `/api/v1/messages/send/whatsapp`
- **Purpose:** Dispatch a rendered message via WhatsApp (§7.7), invoked
  by Send Reminder (Section 6) and Share Document (Section 7).
- **Request Fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| template_id | string | Yes | — |
| recipient_phone | string | Yes | — |
| reminder_id | string | Conditional | — |
| case_id | string | Conditional | — |
| document_id | string | Conditional | — |

- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| sent_message_id | string | — |
| status | string enum | `sent` \| `failed` |
| sent_at | datetime | — |

- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error` (invalid/missing
  recipient_phone); `401 Unauthorized`.
- **Required Permission:** Same as Get Reminder Summary.

## Send via SMS

- **Endpoint Name:** Send via SMS
- **HTTP Method:** POST
- **URL:** `/api/v1/messages/send/sms`
- **Purpose:** Dispatch a rendered message via SMS (§7.8), invoked by
  Send Reminder (Section 6) and Share Document (Section 7).
- **Request Fields:** Identical shape to Send via WhatsApp.
- **Response Fields:** Identical shape to Send via WhatsApp.
- **Success Responses:** `200 OK`.
- **Error Responses:** `422 Validation Error`; `401 Unauthorized`.
- **Required Permission:** Same as Get Reminder Summary.

## List Notifications

- **Endpoint Name:** List Notifications
- **HTTP Method:** GET
- **URL:** `/api/v1/notifications`
- **Purpose:** Retrieve the per-user, chronological notification feed
  implied by `Mobile_UI_V1_Frozen.md` §2.10 and §9's reference to
  "notification entries." Per `Backend_v2.1_UI_Mapping.md` Section 9,
  this is the full extent of Notifications behavior the frozen UI
  specifies — no read/unread state or filtering is defined, because
  neither is textually present in the frozen UI.
- **Request Fields:** `page`, `per_page`.
- **Response Fields:**

| Field | Type | Description |
|---|---|---|
| notifications | array | `{ notification_id, event_type, message, related_entity, created_at }` |
| pagination | object | Section 10 |

- **Success Responses:** `200 OK`.
- **Error Responses:** `401 Unauthorized`.
- **Required Permission:** Any authenticated user (scoped to their own
  notifications).

---

# 9. Standard Response Format

Every endpoint in this specification returns the same envelope shape.
No module deviates from it.

## Success

```
{
  "success": true,
  "message": "<human-readable confirmation>",
  "data": { ... } | [ ... ] | null
}
```

`data` is `null` for actions with no return payload (e.g., Logout,
Delete Reminder).

## Validation Error — `422`

```
{
  "success": false,
  "message": "<summary of the validation failure>",
  "data": null,
  "errors": {
    "<field_name>": ["<reason>"]
  }
}
```

## Unauthorized — `401`

```
{
  "success": false,
  "message": "Unauthenticated.",
  "data": null
}
```

Returned when no valid access token is present, or the token has
expired.

## Forbidden — `403`

```
{
  "success": false,
  "message": "This action is unauthorized.",
  "data": null
}
```

Returned when the authenticated user's role or tenant does not permit
the requested action, per Section 10 of `Backend_v2.1_UI_Mapping.md`.

## Not Found — `404`

```
{
  "success": false,
  "message": "The requested resource was not found.",
  "data": null
}
```

Returned both when a resource genuinely does not exist and when it
belongs to another tenant — tenant isolation never distinguishes the two
outcomes.

## Server Error — `500`

```
{
  "success": false,
  "message": "An unexpected error occurred. Please try again.",
  "data": null
}
```

## Rate Limited — `429`

```
{
  "success": false,
  "message": "Too many attempts. Please try again later.",
  "data": null
}
```

---

# 10. Pagination Standard

Every list endpoint in this specification returns pagination metadata in
the following shape, embedded in `data.pagination`:

| Field | Type | Description |
|---|---|---|
| page | integer | The current page number, 1-indexed |
| per_page | integer | Number of items per page |
| total | integer | Total number of matching items across all pages |
| last_page | integer | The final page number available |

`page` and `per_page` are accepted as request query parameters on every
list endpoint; `per_page` is capped at a fixed maximum to prevent
excessively large responses.

## Sorting

List endpoints that support sorting accept a `sort` query parameter in
the form `field` (ascending) or `-field` (descending). Only fields
already exposed in that endpoint's response are valid sort targets.

## Filtering

Each list endpoint's specific filter fields are documented individually
in Sections 3–7 above (e.g., `tab`, `status`, `risk_level`, `date_from`/
`date_to`). No endpoint accepts a filter field not already documented
for it.

## Search

Where an endpoint supports search (List Reminders, List Documents — see
Section 8), it is accepted as a `search` query parameter performing a
free-text match against that endpoint's user-facing display fields
(e.g., title, filename).

---

# 11. API Security

## Authentication

Every endpoint except Login and Refresh Token requires a valid bearer
token, presented as `Authorization: Bearer <access_token>`. A missing or
invalid token results in `401 Unauthorized`.

## Authorization

Every authenticated request is additionally checked against the
requesting user's role and tenant, per the Permissions mapping in
`Backend_v2.1_UI_Mapping.md` Section 10. A role or tenant mismatch
results in `403 Forbidden`; an attempt to access another tenant's
resource by identifier results in `404 Not Found`, per Section 9's Not
Found definition above.

## Token Lifetime

Access tokens are short-lived. Refresh tokens are longer-lived and are
exchanged for a new access token via the Refresh Token endpoint (Section
2) before expiry, without requiring the user to re-authenticate with
credentials.

## Refresh Tokens

A refresh token is issued alongside every access token at Login and is
single-purpose: it is only accepted by the Refresh Token endpoint, never
as a substitute for an access token on any other endpoint. Logout
invalidates both the access token and its associated refresh token.

## Rate Limiting

Login, Refresh Token, and any endpoint that dispatches a customer-facing
message (Send Reminder, Send via WhatsApp, Send via SMS, Share Document)
are rate-limited per authenticated user (or, for Login, per requesting
IP/credential pair) to prevent abuse. A limit breach returns `429 Rate
Limited`, per Section 9.

## Request Validation

Every endpoint validates its request fields before performing any
action; a validation failure returns `422 Validation Error` with the
specific field-level reasons, per Section 9, and performs no partial
side effect.

## Audit Logging

Per `Backend_v2.1_UI_Mapping.md` Section 7 (Audit Trail Service), the
following actions are recorded for audit purposes: every Case Timeline
event (§6.4), every Document Download and Share (§8.7, §8.8), and every
Send Reminder / Send via WhatsApp / Send via SMS dispatch (Section 6, 8).
No endpoint outside this list has an audit-logging requirement in the
frozen UI.

---

# 12. API Versioning

Every endpoint in this specification is served under the `/api/v1/`
prefix. `v1` corresponds to `Mobile_UI_V1_Frozen.md`, UI Version 1.0 —
the two are versioned together deliberately, so that any future UI
version requiring a materially different API contract is served under a
new prefix (`/api/v2/`) rather than altering `v1`'s existing behavior.

## Future Compatibility

- `/api/v1/` remains stable and unchanged for as long as UI Version 1.0
  is in production use, per the Freeze Policy in
  `Mobile_UI_V1_Frozen.md` §1.4.
- A future UI revision (Version 1.1, 2.0, etc.) that requires new or
  changed endpoints is served under a new version prefix, with its own
  REST API Specification document, rather than modifying this one.
- Existing `v1` clients (a given Flutter app release) are never broken by
  the introduction of a `v2` prefix; both may run concurrently until the
  `v1`-dependent client is retired.

---

# 13. Endpoint Inventory

Master inventory of every endpoint defined in this specification.

| Module | Method | Endpoint | Purpose | Authentication |
|---|---|---|---|---|
| Authentication | POST | /api/v1/auth/login | Authenticate and issue tokens | None |
| Authentication | POST | /api/v1/auth/refresh | Exchange a refresh token for a new access token | None (valid refresh token) |
| Authentication | POST | /api/v1/auth/logout | Invalidate the current session | Authenticated |
| Dashboard | GET | /api/v1/dashboard/business-health | Business Health score and status | Authenticated |
| Dashboard | GET | /api/v1/dashboard/kpis | Home KPI cards | Authenticated |
| Dashboard | GET | /api/v1/dashboard/todays-overview | Today's follow-up counts | Authenticated |
| Dashboard | GET | /api/v1/dashboard/recent-cases | Recently active cases preview | Authenticated |
| Analytics | GET | /api/v1/analytics/overview | Composed Overview figures | Authenticated |
| Analytics | GET | /api/v1/analytics/reports/customers | Customers report | Authenticated |
| Analytics | GET | /api/v1/analytics/reports/debts | Debts report | Authenticated |
| Analytics | GET | /api/v1/analytics/reports/collection-cases | Collection Cases report | Authenticated |
| Analytics | GET | /api/v1/analytics/reports/payments | Payments report | Authenticated |
| Analytics | GET | /api/v1/analytics/reports/credit-risk | Credit Risk report | Authenticated |
| Analytics | GET | /api/v1/analytics/reports/{report_type}/export | Export a report | Authenticated |
| Analytics | GET | /api/v1/analytics/trends | Collections Trend time series | Authenticated |
| Analytics | GET | /api/v1/analytics/collection-kpis | Collection Rate / Total Collected / Average Days | Authenticated |
| Analytics | GET | /api/v1/analytics/aging-analysis | Aging bracket distribution | Authenticated |
| Analytics | GET | /api/v1/analytics/risk-distribution | Risk classification distribution | Authenticated |
| Cases | GET | /api/v1/cases | List cases (filterable) | Authenticated |
| Cases | POST | /api/v1/cases | Create a case | Authenticated |
| Cases | GET | /api/v1/cases/{case_id} | Case details | Authenticated |
| Cases | GET | /api/v1/cases/{case_id}/timeline | Case activity timeline | Authenticated |
| Cases | POST | /api/v1/cases/{case_id}/payments | Record a payment | Authenticated |
| ~~Cases~~ | ~~PATCH~~ | ~~/api/v1/cases/{case_id}/assign-officer~~ | **Retired** — see "Assign Officer" section above | — |
| Cases | POST | /api/v1/cases/{case_id}/escalate | Escalate a case | Authenticated |
| Cases | POST | /api/v1/cases/{case_id}/close | Close a case | Authenticated |
| Reminders | GET | /api/v1/reminders/summary | Today's reminder counts | Authenticated |
| Reminders | GET | /api/v1/reminders | List reminders (filterable, searchable) | Authenticated |
| Reminders | GET | /api/v1/reminders/{reminder_id} | Reminder details | Authenticated |
| Reminders | POST | /api/v1/reminders | Create a reminder | Authenticated |
| Reminders | PUT | /api/v1/reminders/{reminder_id} | Update / reschedule a reminder | Authenticated |
| Reminders | DELETE | /api/v1/reminders/{reminder_id} | Delete a reminder | Authenticated |
| Reminders | PATCH | /api/v1/reminders/{reminder_id}/complete | Complete a reminder | Authenticated |
| Reminders | POST | /api/v1/reminders/{reminder_id}/send | Send a reminder now | Authenticated |
| Reminders | GET | /api/v1/calendar | Smart Calendar aggregation | Authenticated |
| Documents | GET | /api/v1/documents | List documents (filterable, searchable) | Authenticated |
| Documents | GET | /api/v1/documents/storage-usage | Storage usage | Authenticated |
| Documents | GET | /api/v1/documents/invoices | List invoices | Authenticated |
| Documents | GET | /api/v1/documents/receipts | List receipts | Authenticated |
| Documents | GET | /api/v1/documents/demand-letters | List demand letters | Authenticated |
| Documents | GET | /api/v1/documents/statements | List statements | Authenticated |
| Documents | GET | /api/v1/documents/{document_id} | Document preview/detail | Authenticated |
| Documents | GET | /api/v1/documents/{document_id}/download | Download a document | Authenticated |
| Documents | POST | /api/v1/documents/{document_id}/share | Share a document | Authenticated |
| Shared | POST | /api/v1/documents/invoices/scan | Invoice scan capture (file upload) | Authenticated |
| Shared | GET | /api/v1/message-templates | List message templates | Authenticated |
| Shared | POST | /api/v1/messages/render | Render a message from a template | Authenticated |
| Shared | POST | /api/v1/messages/send/whatsapp | Send a message via WhatsApp | Authenticated |
| Shared | POST | /api/v1/messages/send/sms | Send a message via SMS | Authenticated |
| Shared | GET | /api/v1/notifications | List the user's notifications | Authenticated |
