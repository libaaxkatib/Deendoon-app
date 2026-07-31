# 07. API Design

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-07 |
| **Document Title** | API Design |
| **Version** | 1.5 |
| **Status** | Reopened — Section 5.4 (Collection Cases) amended |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Pending |
| **Last Updated** | 2026-07-31 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened v1.5) · `02_Business_Requirements.md` (Reopened v1.6) · `03_Functional_Requirements.md` (v1.10 — **Module 12 still awaiting its original approval**) · `04_Business_Rules.md` (Reopened v1.6) · `05_UI_UX_Specification.md` (Reopened, v1.3) · `06_Database_Design.md` (Reopened v1.6 — §6.1 amended) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: full API specification derived from Documents 01–06 — every endpoint already committed in `03_Functional_Requirements.md`'s "Related APIs" annotations, consolidated, organized, and given complete request/response models, validation rules, and error semantics. No controller code, routes, or OpenAPI/Swagger generated — specification only, per instruction. | Claude |
| 1.1 | 2026-07-24 | Consolidated architecture review: (1) Section 2 now states Laravel Sanctum (Bearer Token mode) explicitly as the authentication mechanism, with no reference to Passport or a custom implementation as alternatives; (2) removed any implication that Sanctum replaces or restructures `06_Database_Design.md`'s approved `sessions` table — the Sanctum/database mapping is now stated as an implementation-time concern only, with `06` reaffirmed as the sole source of truth for database architecture; (3) verified every endpoint against `03`, `05`, and `06` — no untraceable endpoint found, none removed; (4) consistency pass: added `/professional-requests` to the Pagination section's applicable-endpoints list (was missing), extended the `data`+`warning` response envelope note to explicitly cover Duplicate Customer Detection (FR-014) alongside Credit Limit (FR-018) rather than showing only one example, and added an explicit "no dedicated endpoint" note for FR-056 (Report Filtering) matching the existing FR-064 treatment. No new actor, workflow, permission, module, or business behavior introduced. | Claude |
| 1.2 | 2026-07-26 | Product Owner decision (Deendoon Backend Excellence Phase, Sprint 1.1): Section 5.1's Authentication endpoints corrected from the drafted `/auth/*` path prefix to the flat path convention actually implemented and approved for production (`/register`, `/login`, `/logout`, `/forgot-password`, `/reset-password`) — the `/auth/` prefix was never built and is not adopted. `/register` (FR-001) added to the table; it was implemented from Module 1 but never listed here. `/change-password` (FR-005) and `/me` (FR-006) corrected to the same flat convention; both remain approved-but-unimplemented, unchanged from v1.1 in that respect. Section 5's endpoint-count note, Section 12's audit-logging note, and Section 13's traceability matrix updated to match. No endpoint, method, request/response shape, FR, or business rule changed — path prefix only. | Claude |
| 1.3 | 2026-07-31 | RBAC Architecture Amendment (Product Owner Decision — see `docs/RBAC_Architecture_Amendment_Proposal.md` and `08_Security_and_RBAC.md` v1.2): Version 1 has exactly one account per tenant (the Business Owner) and Collection Officer is no longer a login role, so there is no second tenant user to assign a Collection Case to. Section 5.4's `PATCH /collection-cases/{id}/assign` row (FR-041) marked Retired, consistent with `03_Functional_Requirements.md` v1.8. `GET /me` (FR-006) confirmed implemented (flat path, single-role response — see `08_Security_and_RBAC.md` v1.2). No other endpoint, method, request/response shape, FR, or business rule changed. | Claude |
| 1.4 | 2026-07-31 | **Scope Baseline metadata correction (Documentation Consistency Audit — Scope Baseline synchronization).** Updated the Scope Baseline field to cite the current approved versions of `02`, `03`, `04`, `05`, and `06` (previously stale). No endpoint, method, request/response shape, FR, or business rule changed. | Claude |
| 1.5 | 2026-07-31 | **Scope Baseline metadata correction (Product Vision Amendment ripple).** Updated the Scope Baseline field to cite `01` (v1.4), `03` (v1.10), `04` (v1.6), `05` (Reopened, v1.3), and `06` (v1.6) following those documents' own updates. No endpoint or contract changed. | Claude |

---

## Document Purpose

This document specifies the REST API surface that implements the approved SRS. Every endpoint below either (a) was already named in a Functional Requirement's "Related APIs (reference only)" annotation in `03_Functional_Requirements.md`, or (b) is a standard list/collection endpoint an already-approved screen in `05_UI_UX_Specification.md` cannot function without (flagged individually where this applies, same pattern used when Module 12's Audit Trail viewing gap was closed). No endpoint exists for a capability that isn't already approved.

This document does not generate controller code, Laravel routes, or an OpenAPI/Swagger document — those are implementation artifacts that follow this specification, not part of it.

**Guardian note on Deferred Decisions:** Where `04_Business_Rules.md` leaves a business question open (overpayment handling, DD-016; multi-role assignment, DD-039; etc.), the corresponding endpoint is specified to accept/return the data needed under either resolution, without asserting one — exactly the same posture `05` and `06` already took. Where an endpoint's *existence* depends on a decision not yet made anywhere (none were found), Section 15 would flag it; none exist for this document.

---

## 1. API Design Principles

1. **Every endpoint traces to an approved FR.** No speculative CRUD surface — if a Functional Requirement doesn't describe an action, there's no endpoint for it.
2. **Resource-oriented REST**, not RPC — URLs name resources (`/customers/{id}`), HTTP methods name the action.
3. **Tenant scope is derived from the session, never from client input.** No endpoint accepts a client-supplied `tenant_id`; it is resolved server-side from the authenticated session, exactly as `06_Database_Design.md` Section 2 requires. This is the single most important security rule in this document (Section 3).
4. **No hard delete.** Per BC-002, there is no `DELETE` verb anywhere in this API. "Archive" and "Restore" are `POST` actions against a resource, matching `06_Database_Design.md`'s `archived_at` model.
5. **Business-facing identifiers are for humans; ULIDs are for the API.** URLs use the internal ULID (`06_Database_Design.md` Section 3), never the Auto Numbering display value (`DBT-000001`) — the display value is a response field, not a lookup key, to avoid two parallel identifier schemes in routing.
6. **Consumption-only surfaces stay read-only.** The Notification Center (Module 10) and Reporting (Module 9) expose only `GET` endpoints, matching their Scope Boundaries in `03_Functional_Requirements.md` — this API cannot be used to make either module originate an event or a computation it isn't approved to own.
7. **Soft-limit and duplicate-detection warnings are data, not errors.** Per BC-001 and BRL-005, a Credit Limit warning (FR-018) or a Duplicate Customer match (FR-014) is returned as a response field the client displays, never an HTTP error status that blocks the request — the API must not turn an advisory warning into a hard block by implementation accident.

---

## 2. Authentication & Authorization

**Model:** Laravel Sanctum, in token (Bearer) mode. Not JWT. This is a stateful, server-validated token model: the client sends `Authorization: Bearer <token>` on every request, and the server validates it against a database-persisted, revocable record rather than trusting a self-contained, stateless token — which is what FR-003's sliding-window expiry and FR-005/FR-067's server-side invalidation on password/role change require.

- **Token transport:** an opaque bearer token in the `Authorization: Bearer <token>` header, issued by Sanctum on login (FR-001) and revoked on logout (FR-002), password change (FR-005), and role change (FR-067). Exact token generation/format hardening is `08_Security_and_RBAC.md`'s concern (not yet written).
- **Database mapping:** `06_Database_Design.md` remains the sole source of truth for database architecture, including its approved `sessions` table (Section 6.1). This document does not state or imply that Sanctum replaces, removes, or restructures that table. The mapping between Sanctum's token mechanism and the approved database design is an implementation-layer concern, to be resolved during implementation — not asserted here.
- **Every authenticated request** resolves, server-side: `user_id` → `tenant_id` (NULL for the Deendoon Super Admin, per `06` Section 2) → role(s) via `user_roles` → permitted actions.
- **Tenant isolation enforcement:** every endpoint below that touches a tenant-owned table filters by the session's resolved `tenant_id` automatically. A request cannot read or write another tenant's data by supplying a different ID in the URL — the row is simply not found (`404`, not `403`, so as not to confirm another tenant's record exists — see Section 5).
- **The one approved exception:** endpoints under `/professional-requests` (Section 11) accept requests from the Deendoon Super Admin (`tenant_id IS NULL` session) without a tenant filter, by design (`06` Section 2, BR-042). Every tenant-role session hitting the same endpoints is still tenant-filtered.
- **Permission matrix (which role may call which endpoint):** deferred to `08_Security_and_RBAC.md`, which does not exist yet. Each endpoint below states *that* it's permission-gated and references the FR whose Exceptions define the gate (e.g., "E1 — User lacks permission"), not the exact role list — that belongs in 08.

---

## 3. API Standards

| Aspect | Standard |
|---|---|
| Base path | `/api/v1` — URL-path versioning, so a future breaking change ships as `/api/v2` without disrupting Version 1 clients |
| Payload format | JSON, `Content-Type: application/json` (file uploads: `multipart/form-data`, Section 10) |
| JSON field casing | `camelCase` in requests/responses; the database (`06`) stays `snake_case` — translated at the serialization layer, not a database concern |
| HTTP methods | `GET` (read), `POST` (create / non-idempotent action, e.g., `archive`, `close`), `PUT` (full update), `PATCH` (partial update). **`DELETE` is not used anywhere in this API** (Principle 4) |
| Idempotency | `GET`/`PUT`/`PATCH` are idempotent by definition. `POST` actions that represent a state check (e.g., duplicate detection) are safe to retry; `POST` actions that create a record are not idempotent unless a client-supplied idempotency key is added — not specified as a Version 1 requirement anywhere in 01–06, so not assumed here |
| Timestamps | ISO 8601, UTC, in every request/response (matches `06`'s UTC storage principle) |
| Money | JSON string, not float (e.g., `"1250.00"`), to avoid floating-point precision loss matching `06`'s `DECIMAL(12,2)` columns |
| Identifiers in URLs | Internal ULID (Principle 5) |

---

## 4. Error Response Standards

Every error response uses one envelope:

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "One or more fields are invalid.",
    "fields": [
      { "field": "amount", "message": "Amount must be a positive number." }
    ]
  }
}
```

`fields` is present only for `422` validation errors; omitted otherwise.

| HTTP Status | `error.code` | Used When | Maps To |
|---|---|---|---|
| `400` | `BAD_REQUEST` | Malformed request (unparseable JSON, missing required query param) | — |
| `401` | `UNAUTHENTICATED` | Missing/invalid/expired session token | FR-001 A1, FR-003 |
| `403` | `FORBIDDEN` | Authenticated, but role lacks permission for this action | Every FR's "E — User lacks permission" exception |
| `404` | `NOT_FOUND` | Resource doesn't exist, is Archived where Archive excludes it by default, or belongs to another tenant (never distinguished from "doesn't exist" — Section 2) | FR-008 E1-style "not found" states, SCR-048 |
| `409` | `CONFLICT` | A state-dependent rule blocks the action (e.g., closing an already-Closed Collection Case, FR-045 E2; duplicate active Professional Collection Request, BRL-078) | Each FR's state-based Exceptions |
| `422` | `VALIDATION_FAILED` | Field-level validation failure | Every FR's "required fields invalid" Exception |
| `429` | `RATE_LIMITED` | Exceeds a rate limit | Rate limit thresholds: `09_Non_Functional_Requirements.md` (not yet written) — this document only reserves the status code |
| `500` | `INTERNAL_ERROR` | Unexpected server failure | — |

**Never used:** a `4xx` status for advisory warnings (Principle 7) — Credit Limit and Duplicate Customer warnings are `200`/`201` responses with a warning field, not errors.

---

## 5. REST Endpoint Specifications

Organized by resource group, mirroring `06_Database_Design.md` Section 5's grouping. `🔒` = requires authentication (all endpoints below except `/register`, `/login`, `/forgot-password`, `/reset-password`).

### 5.1 Authentication (Module 1)

**Path convention:** flat, not grouped under an `/auth/` prefix — Product Owner decision (Deendoon Backend Excellence Phase, Sprint 1.1), matching the convention already implemented and approved for production since Module 1. `/change-password` remains approved (FR-005) but unimplemented, same as prior versions of this document. `/me` (FR-006) is now implemented (RBAC Architecture Amendment, v1.3) — resolves the current session's single role only; no permission array is returned (see `08_Security_and_RBAC.md` v1.2).

| Method | Path | Purpose | FR |
|---|---|---|---|
| `POST` | `/register` | Create an account | FR-001 |
| `POST` | `/login` | Authenticate, establish session | FR-001 |
| `POST` | `/logout` 🔒 | Invalidate current session | FR-002 |
| `POST` | `/forgot-password` | Request password reset token | FR-004 |
| `POST` | `/reset-password` | Complete reset with token | FR-004 |
| `POST` | `/change-password` 🔒 | Change own password (authenticated) | FR-005 |
| `GET` | `/me` 🔒 | Resolve current session's user, role(s), permissions | FR-006 |

### 5.2 Customers (Module 2)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/customers` 🔒 | List/search/filter Customers *(list endpoint required by SCR-007; consolidates FR-015's filter query into the standard list path)* | FR-015 |
| `POST` | `/customers` 🔒 | Create Customer (runs Duplicate Detection) | FR-007, FR-014 |
| `GET` | `/customers/{id}` 🔒 | Customer Details | FR-008 |
| `PUT` | `/customers/{id}` 🔒 | Update Customer | FR-009 |
| `POST` | `/customers/{id}/archive` 🔒 | Archive | FR-010 |
| `POST` | `/customers/{id}/restore` 🔒 | Restore | FR-011 |
| `PATCH` | `/customers/{id}/status` 🔒 | Change Customer Status | FR-012 |
| `GET` | `/customers/{id}/credit-profile` 🔒 | Credit Limit, Outstanding, Remaining Credit, Risk Level, Credit Score | FR-013 |
| `PATCH` | `/customers/{id}/credit-limit` 🔒 | Update Credit Limit | FR-013 |
| `PATCH` | `/customers/{id}/risk-level` 🔒 | Assign/update Risk Level | FR-027 |
| `GET` | `/customers/{id}/credit-score` 🔒 | Read current Credit Score + band | FR-026 |
| `POST` | `/customers/check-duplicate` 🔒 | Standalone duplicate check (used by both Create and Import) | FR-014 |
| `POST` | `/customers/import` 🔒 | Upload Excel, return Preview | FR-016 |
| `POST` | `/customers/import/{batchId}/commit` 🔒 | Commit a previewed import batch | FR-016 |
| `GET` | `/customers/{id}/payments` 🔒 | Customer-level Payment History | FR-035 |
| `GET` | `/customers/{id}/documents` 🔒 | Documents generated for this Customer | FR-052 |
| `POST` | `/customers/{id}/statements` 🔒 | Generate Statement of Account | FR-049 |

### 5.3 Debts (Module 3)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/debts` 🔒 | List/search/filter Debts (optional `customerId` filter) *(list endpoint required by SCR-013)* | FR-021 |
| `POST` | `/customers/{id}/debts` 🔒 | Create Debt against a Customer (returns Credit Limit warning if applicable) | FR-017, FR-018 |
| `GET` | `/debts/{id}` 🔒 | Debt Details | FR-019 |
| `PUT` | `/debts/{id}` 🔒 | Update Debt (non-financial fields) | FR-020 |
| `PATCH` | `/debts/{id}/status` 🔒 | Manual Debt Status transition (Cancelled/Written Off only — Paid/Partial Paid are Payment-driven, Section 5.5) | FR-021 |
| `POST` | `/debts/{id}/archive` 🔒 | Archive | FR-022 |
| `POST` | `/debts/{id}/restore` 🔒 | Restore | FR-023 |
| `GET` | `/debts/{id}/timeline` 🔒 | Recovery Timeline (read-only aggregation) | FR-024 |
| `PATCH` | `/debts/{id}/recovery-stage` 🔒 | Manual Recovery Stage override (mandatory `reason`) | FR-025 |
| `GET` | `/debts/{id}/followup-history` 🔒 | Follow-up History | FR-033, FR-046 |
| `POST` | `/debts/{id}/reminders/whatsapp` 🔒 | Manual WhatsApp reminder | FR-030 |
| `POST` | `/debts/{id}/reminders/sms` 🔒 | Manual SMS reminder | FR-030 |
| `POST` | `/debts/{id}/reminders/call` 🔒 | Log a phone call | FR-030 |
| `POST` | `/debts/{id}/promise-to-pay` 🔒 | Record Promise to Pay | FR-031 |
| `POST` | `/debts/{id}/demand-letters` 🔒 | Generate Demand Letter (template selection) | FR-048 |
| `POST` | `/debts/{id}/statements` 🔒 | Generate Statement of Account (Debt-scoped entry point) | FR-049 |
| `GET` | `/debts/{id}/documents` 🔒 | Documents generated for this Debt | FR-052 |
| `POST` | `/debts/{id}/collection-cases` 🔒 | Escalate to Professional Collection | FR-040 |

### 5.4 Collection Cases (Module 7)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/collection-cases` 🔒 | List Collection Cases *(list endpoint required by SCR-024)* | FR-042 |
| `GET` | `/collection-cases/{id}` 🔒 | Collection Case Details | FR-042 |
| ~~`PATCH`~~ | ~~`/collection-cases/{id}/assign`~~ | **Retired v1.3** — no second tenant user exists to assign a case to; see FR-041 | FR-041 |
| `PUT` | `/collection-cases/{id}` 🔒 | Update non-financial Case details | FR-043 |
| `POST` | `/collection-cases/{id}/activities` 🔒 | Record Collection Activity | FR-044 |
| `POST` | `/collection-cases/{id}/close` 🔒 | Close with recorded outcome | FR-045 |
| `GET` | `/collection-cases/{id}/history` 🔒 | Chronological Case history | FR-046 |
| `POST` | `/collection-cases/{id}/professional-requests` 🔒 | Submit to Deendoon (full detail: Section 11) | FR-072 |

### 5.5 Payments (Module 6)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `POST` | `/debts/{id}/payments` 🔒 | Record a payment (full or partial) | FR-034 |
| `GET` | `/debts/{id}/payments` 🔒 | Debt-level Payment History | FR-035 |

No `PATCH`/`PUT`/`DELETE` on an individual `payment` resource — per `06_Database_Design.md` Section 6.4, editing/reversal has no approved write path (DD-018). This is not an omission; adding one would require a Business Rule decision first (see `06` Section 13, carried forward here).

### 5.6 Documents (Module 8)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/receipts/{id}` 🔒 | Read a Receipt (auto-generated, never created via this API directly) | FR-047 |
| `GET` | `/documents/{id}` 🔒 | View a generated document (any of the three types) | FR-050 |
| `GET` | `/documents/{id}/download` 🔒 | Download as PDF | FR-051 |
| `GET` | `/documents/{id}/history` 🔒 | Lifecycle events for one document | FR-052 |

Demand Letter and Statement *creation* endpoints live under `/debts/{id}/...` and `/customers/{id}/...` (Sections 5.2/5.3) since generation is always initiated from a Debt or Customer context, per `05_UI_UX_Specification.md` SCR-031/SCR-032.

### 5.7 Reporting & Dashboard (Module 9)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/dashboard/kpis?period=` 🔒 | Executive KPI Cards | FR-053 |
| `GET` | `/reports/aging-analysis` 🔒 | Aging Analysis (bucket summary + detail) | FR-054 |
| `GET` | `/reports/customers` 🔒 | Standard Customer report | FR-055 |
| `GET` | `/reports/debts` 🔒 | Standard Debt report | FR-055 |
| `GET` | `/reports/collection-cases` 🔒 | Standard Collection report | FR-055 |
| `GET` | `/reports/payments` 🔒 | Standard Payment report | FR-055 |
| `GET` | `/reports/credit-risk` 🔒 | Standard Credit Risk report | FR-055 |
| `GET` | `/reports/{reportType}/export?format=` 🔒 | Export current report/filters as PDF/Excel/CSV | FR-057 |

All `GET`-only, per Module 9's Scope Boundary (read-only, never the source of truth). FR-056 (Report Filtering) has no endpoint of its own — it is the query-parameter set shared across the `/reports/*` endpoints above, per Module 9's Scope Boundary ("this module specifies only the report-scoped application of filtering... the general cross-cutting architecture is owned by Module 11"), the same pattern already applied to FR-064 (Section 5.9).

### 5.8 Notifications & Calendar (Module 10)

Full detail: Section 12.

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/notifications?type=` 🔒 | List, filterable by type | FR-058, FR-060 |
| `PATCH` | `/notifications/{id}/read` 🔒 | Mark one as read | FR-059 |
| `PATCH` | `/notifications/mark-all-read` 🔒 | Mark all as read | FR-059 |
| `GET` | `/notifications/history` 🔒 | Include already-read notifications | FR-061 |
| `GET` | `/calendar?from=&to=` 🔒 | Read-only calendar aggregation | FR-062 |

### 5.9 Search (Module 11)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/search?q=` 🔒 | Global Search across Customers, Debts, Payments, Documents, Collection Cases | FR-063 |

Advanced Filtering (FR-064) is not a separate endpoint — it's the shared set of query parameters (`status`, `riskLevel`, `dateFrom`/`dateTo`, etc.) already listed on `/customers`, `/debts`, and every `/reports/*` endpoint above, per Module 11's Scope Boundary ("owns the filter architecture... referenced, not restated, by Modules 2 and 9").

### 5.10 Administration (Module 12)

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/admin/users` 🔒 | List users *(list endpoint required by SCR-039)* | FR-066 |
| `POST` | `/admin/users` 🔒 | Create user | FR-066 |
| `GET` | `/admin/users/{id}` 🔒 | User details | FR-066 |
| `PUT` | `/admin/users/{id}` 🔒 | Update user | FR-066 |
| `POST` | `/admin/users/{id}/deactivate` 🔒 | Deactivate (archive) | FR-066 |
| `PATCH` | `/admin/users/{id}/role` 🔒 | Assign/change Role | FR-067 |
| `GET` | `/admin/settings/company-profile` 🔒 | Read Company Profile | FR-068 |
| `PUT` | `/admin/settings/company-profile` 🔒 | Update Company Profile & Branding | FR-068 |
| `GET` | `/admin/settings/preferences` 🔒 | Read System Preferences | FR-069 |
| `PUT` | `/admin/settings/preferences` 🔒 | Update System Preferences | FR-069 |
| `GET` | `/admin/reference-data/{category}` 🔒 | Read a Lookup & Reference Data value set | FR-070 |
| `PUT` | `/admin/reference-data/{category}` 🔒 | Update a value set | FR-070 |
| `GET` | `/admin/audit-trail` 🔒 | View the Audit Trail (read-only, no write endpoint exists — Section 13) | FR-071 |

---

## 6. Request/Response Models

Field names/types trace directly to `06_Database_Design.md` Section 6 (camelCase per Section 3). Representative models below; every other resource follows the same translation pattern (DB column → camelCase JSON field, `id`→`id`, FKs →`xCamelId`).

### `Customer`
```json
{
  "id": "01J...ULID",
  "name": "Farah Trading Co.",
  "phone": "+2521234567",
  "customerStatus": "active",
  "creditLimit": "300.00",
  "outstandingBalance": "250.00",
  "remainingCredit": "50.00",
  "riskLevel": "low",
  "creditScore": 82,
  "creditScoreBand": "good",
  "archivedAt": null,
  "createdAt": "2026-06-01T09:00:00Z",
  "updatedAt": "2026-07-20T14:30:00Z"
}
```
`remainingCredit` is a computed, read-only response field (`creditLimit − outstandingBalance`, per BRL-017) — never accepted on write.

### `Debt`
```json
{
  "id": "01J...ULID",
  "customerId": "01J...ULID",
  "referenceNumber": "DBT-000001",
  "amount": "500.00",
  "dueDate": "2026-08-15",
  "debtStatus": "overdue",
  "remainingBalance": "500.00",
  "recoveryStage": 3,
  "notes": null,
  "archivedAt": null,
  "createdAt": "2026-06-01T09:05:00Z",
  "updatedAt": "2026-07-20T14:30:00Z"
}
```

**`POST /customers/{id}/debts` response (Credit Limit warning case, FR-018):**
```json
{
  "data": { "...": "the created Debt object" },
  "warning": {
    "type": "CREDIT_LIMIT_EXCEEDED",
    "message": "This customer has exceeded the approved credit limit.",
    "creditLimit": "300.00",
    "projectedOutstanding": "330.00"
  }
}
```
Status `201 Created` — the warning is informational, never blocking (Principle 7). The same `data` + `warning` envelope shape applies identically to `POST /customers` when Duplicate Customer Detection (FR-014) finds a likely match — `warning.type: "POSSIBLE_DUPLICATE_CUSTOMER"`, with the matched customer's `id` and `name` in place of the credit-limit fields — rather than a distinct response shape per warning type. Response envelope wraps the resource in `data` whenever a `warning` field may accompany it; plain resource responses (no possible warning) are returned unwrapped for brevity.

### `Payment`
```json
{
  "id": "01J...ULID",
  "debtId": "01J...ULID",
  "amount": "150.00",
  "paymentDate": "2026-07-20",
  "paymentMethod": null,
  "referenceNotes": null,
  "recordedByUserId": "01J...ULID",
  "createdAt": "2026-07-20T14:30:00Z"
}
```
No `updatedAt` — matches `06`'s insert-only design (DD-018).

### `CollectionCase`
```json
{
  "id": "01J...ULID",
  "debtId": "01J...ULID",
  "referenceNumber": "COL-000001",
  "assignedOfficerUserId": "01J...ULID",
  "caseStatus": "open",
  "closureOutcome": null,
  "createdAt": "2026-07-10T08:00:00Z",
  "closedAt": null
}
```

### `ProfessionalCollectionRequest` — Section 11.

### `Notification` — Section 12.

---

## 7. Validation Rules

Every field's constraint traces to `06_Database_Design.md`; the API enforces the same rule before it ever reaches the database, returning `422` rather than relying on a DB error.

| Field (Resource) | Rule | Source |
|---|---|---|
| `name`, `phone` (Customer) | Required, non-empty string | `06` §6.2, FR-007 |
| `creditLimit` (Customer) | Numeric, ≥ 0 | `06` §6.2, FR-013 E2 |
| `amount` (Debt) | Numeric, > 0 | `06` §6.3, FR-017 E1 |
| `dueDate` (Debt) | Required, valid ISO 8601 date | FR-017 E1 |
| `amount` (Payment) | Numeric, > 0 | `06` §6.4, FR-034 E1. **No upper-bound check** — overpayment handling is DD-016, unresolved; the API does not silently cap or reject a large amount |
| `reason` (Recovery Stage Override) | Required, non-empty | BR-015, FR-025 |
| `templateType` (Demand Letter) | One of the 4 approved values | BR-020, FR-048 |
| `status` (Collection Case Closure) | Present; value set itself pending DD-024 — validated against tenant's `reference_data` (category `collection_outcome`) if configured, otherwise accepted as free text pending that decision (`06` §6.8) | FR-045 |
| `riskLevel` (Customer) | Validated against tenant's `reference_data` (category `risk_level`) once configured — DD-010 | FR-027 |
| `currentPassword`/`newPassword` (Change Password) | Both required; `currentPassword` must validate before `newPassword` is accepted | FR-005 E1 |

**Field-level vs. request-level validation:** matches `05_UI_UX_Specification.md` §6 exactly — a `422` response's `fields` array corresponds one-to-one with the inline field errors that document specifies; this API does not introduce a validation behavior the UI spec doesn't already describe.

---

## 8. Pagination, Filtering & Sorting

Applies uniformly to every `GET` collection endpoint (`/customers`, `/debts`, `/collection-cases`, `/professional-requests`, `/reports/*`, `/notifications`, `/admin/users`, `/admin/audit-trail`):

| Query Parameter | Meaning | Notes |
|---|---|---|
| `page` | 1-indexed page number | Default page size: not specified in any approved document — `04_Business_Rules.md` DD leaves this open; this API defers to a sensible implementation default rather than asserting one |
| `perPage` | Results per page | Maximum value: same open item as above |
| `sort` | Field name, optionally prefixed `-` for descending (e.g., `-createdAt`) | Default sort order per resource: not specified — implementation default |
| `q` | Free-text search within the resource (distinct from Global Search, `/search`) | FR-015 (Customer Search), FR-064 (Advanced Filtering) |
| Resource-specific filters | e.g., `status=`, `riskLevel=`, `dateFrom=`/`dateTo=`, `outstandingAmountMin=`/`Max=` | Exact set per resource matches the filter fields already named in each FR's Main Flow (FR-015, FR-056, FR-064) |
| `includeArchived` | `true`/`false`, default `false` | Enforces BRL-004 — archived records excluded by default everywhere |

**Response envelope for paginated lists:**
```json
{
  "data": [ "...": "array of resources" ],
  "meta": { "page": 1, "perPage": 25, "total": 118, "totalPages": 5 }
}
```

---

## 9. File Upload APIs

| Method | Path | Purpose | FR |
|---|---|---|---|
| `POST` | `/customers/import` | Upload an Excel file, return parsed Preview rows | FR-016 |
| `PUT` | `/admin/settings/company-profile` | Includes `logo` as a `multipart/form-data` field alongside text fields | FR-068 |

Both use `multipart/form-data`. Accepted file types/size limits are a UI-validation/NFR concern per `05_UI_UX_Specification.md` (BRL-073's redirect) and `04_Business_Rules.md` (BC-conformant note) — this document reserves the endpoints and does not assert specific limits.

**`POST /customers/import` response:**
```json
{
  "batchId": "01J...ULID",
  "status": "preview",
  "rows": [
    {
      "rowNumber": 1,
      "data": { "name": "Iftin Supermarket", "phone": "+252..." },
      "validationStatus": "valid",
      "duplicateMatch": { "customerId": "01J...ULID", "name": "Iftin Supermarket" }
    }
  ]
}
```

**`POST /customers/import/{batchId}/commit` request:**
```json
{
  "resolutions": [
    { "rowNumber": 1, "resolution": "update" }
  ]
}
```
`resolution` is one of `skip` / `update` / `new`, per FR-016 exactly.

**Note & Attachment uploads** (Module 8, Document Scanner reuse) are referenced across Customer/Debt/Collection Case detail screens in `05` but have no dedicated endpoint named in any FR's "Related APIs" annotation — `03_Functional_Requirements.md` treats Notes & Attachments as owned by Module 8 without a standalone FR of its own beyond the reference-only mentions in FR-008, FR-019, FR-042. Rather than invent an endpoint shape not specified anywhere, this is flagged in Section 15 for confirmation before implementation.

---

## 10. Professional Collection APIs

The full, dedicated surface for the reopened Module 7 capability (FR-072–FR-076). This section consolidates what Section 5.4/5.8 already listed, with complete detail, since the Guardian review process on this capability has been the most heavily scrutinized part of the SRS.

| Method | Path | Purpose | FR | Actor |
|---|---|---|---|---|
| `POST` | `/collection-cases/{id}/professional-requests` 🔒 | Submit an open Collection Case to Deendoon | FR-072 | Tenant user with submission permission |
| `GET` | `/professional-requests` 🔒 | List Requests — **tenant-filtered for tenant sessions; unfiltered (cross-tenant) for the Deendoon Super Admin session** (`06` §2) | FR-074 (tenant), FR-073 (Super Admin, SCR-049) | Both |
| `GET` | `/professional-requests/{id}` 🔒 | Request detail: status, linked Case, message thread | FR-074, FR-073 | Both |
| `PATCH` | `/professional-requests/{id}/status` 🔒 | Advance status through the approved sequence | FR-073 | **Deendoon Super Admin only** |
| `GET` | `/professional-requests/{id}/messages` 🔒 | Read the Conversation Thread | FR-075 | Both |
| `POST` | `/professional-requests/{id}/messages` 🔒 | Post a message | FR-075 | Both |
| `POST` | `/professional-requests/{id}/close` 🔒 | Record final outcome (Recovered/Closed) | FR-076 | **Deendoon Super Admin only** |

### `ProfessionalCollectionRequest` model
```json
{
  "id": "01J...ULID",
  "collectionCaseId": "01J...ULID",
  "referenceNumber": null,
  "status": "assigned",
  "submittedByUserId": "01J...ULID",
  "actionedByUserId": "01J...ULID",
  "createdAt": "2026-07-22T10:00:00Z",
  "closedAt": null
}
```
`referenceNumber` is nullable — `PCR-000001` format is proposed but not confirmed (DD-045, carried from `06`). `status = "assigned"` **does not mean assignment to another system user** — it means the Deendoon Super Admin has accepted ownership and started handling the Request, per BRL-079. The API does not expose any field or endpoint suggesting assignment to a different Deendoon staff member — none exists, per the Guardian correction in `01_Project_Overview.md`.

### `PATCH /professional-requests/{id}/status` request
```json
{ "status": "under_review" }
```
Rejected with `409 CONFLICT` if the target status isn't a valid transition from the current one (FR-073 E1; full matrix: BRL-079/DD-043, `04_Business_Rules.md`).

### `POST /professional-requests/{id}/close` request
```json
{ "outcome": "recovered" }
```
`outcome` value set is DD-024-adjacent (pending); accepted as-is pending that resolution, same posture as Collection Case closure (Section 7).

### Authorization detail specific to this resource
- A tenant-scoped session may only `GET` a Request whose linked `collection_cases.tenant_id` matches its own session tenant.
- Only the Deendoon Super Admin session (`tenant_id IS NULL`) may call `PATCH .../status` or `POST .../close` — a tenant session attempting either receives `403 FORBIDDEN`, not `404`, since the resource does exist and is visible to them, just not actionable (distinct from the cross-tenant `404` masking in Section 4, because here the tenant legitimately owns the underlying Case).
- No endpoint exists for assigning a Request to a specific Deendoon staff member, listing "available specialists," or any workload-balancing concept — per the approved correction, there is exactly one Deendoon-side actor.

---

## 11. Notification APIs

| Method | Path | Purpose | FR |
|---|---|---|---|
| `GET` | `/notifications?type=` 🔒 | List, newest first, optional type filter | FR-058, FR-060 |
| `PATCH` | `/notifications/{id}/read` 🔒 | Mark one as read | FR-059 |
| `PATCH` | `/notifications/mark-all-read` 🔒 | Mark all as read | FR-059 |
| `GET` | `/notifications/history` 🔒 | Full history including already-read | FR-061 |
| `GET` | `/calendar?from=&to=` 🔒 | Read-only calendar aggregation (Due Dates, Promises, Calls, Collection Activities) | FR-062 |

**No `POST /notifications` endpoint exists.** This is deliberate, not an omission: per `03_Functional_Requirements.md` Module 10 Scope Boundary and `01_Project_Overview.md`'s Notification Center definition, notifications are consumption-only — they are created internally when Modules 4/5/6/7/8 emit their own approved events, never by a direct API call. Exposing a creation endpoint here would let a client originate an arbitrary notification, contradicting the frozen architecture.

### `Notification` model
```json
{
  "id": "01J...ULID",
  "type": "professional_collection_request_update",
  "relatedEntityType": "professional_collection_request",
  "relatedEntityId": "01J...ULID",
  "readAt": null,
  "createdAt": "2026-07-22T10:05:00Z"
}
```
`type` enum matches `06_Database_Design.md` §6.7 exactly, including the Request-update type added by the reopening.

---

## 12. Audit & Logging Considerations

- **Every mutating endpoint** (`POST`/`PUT`/`PATCH` other than pure reads) writes at least one `audit_log` row (`06` §6.9) as part of the same transaction as the primary write — never as a best-effort side effect that could silently fail while the primary write succeeds.
- **No endpoint exposes writing to `audit_log` directly.** `GET /admin/audit-trail` (FR-071) is the only endpoint touching this table, and it is read-only — matching `06`'s "one operation available: `INSERT`, and only from application code, never from a client request."
- **The `reason` field** is required at the API layer (not just the UI layer) for Recovery Stage Override (`PATCH /debts/{id}/recovery-stage`) — a `422` is returned if omitted, so the mandatory-reason rule (BR-015) can't be bypassed by calling the API directly instead of going through `05`'s Confirmation Dialog.
- **Login/Logout are logged from the authentication endpoints themselves** (FR-001, FR-002), not inferred from session table changes — ensuring the audit event exists even if session cleanup happens asynchronously.
- **Rate limiting, request logging, and APM/observability** are Non-Functional Requirements (`09_Non_Functional_Requirements.md`, not yet written) — this document notes where they'll attach (Section 4's `429`/`RATE_LIMITED` reservation) without specifying thresholds it has no basis to assert.

---

## 13. API Traceability Matrix

| Endpoint Group | Functional Requirements | Database Tables |
|---|---|---|
| Authentication (`/register`, `/login`, `/logout`, `/forgot-password`, `/reset-password`, `/change-password`, `/me`) | FR-001–FR-006 | `users`, `sessions`, `password_reset_tokens` |
| `/customers/*` | FR-007–FR-016, FR-026–FR-028 | `customers`, `import_batches`, `import_rows` |
| `/debts/*` | FR-017–FR-025, FR-029–FR-033, FR-040, FR-048–FR-049 | `debts`, `follow_up_history`, `promises_to_pay` |
| `/debts/{id}/payments` | FR-034–FR-039 | `payments` |
| `/collection-cases/*` | FR-040–FR-046 | `collection_cases` |
| `/professional-requests/*` | FR-072–FR-076 | `professional_collection_requests`, `request_messages` |
| `/receipts/*`, `/documents/*` | FR-047, FR-050–FR-052 | `receipts`, `demand_letters`, `statements`, `document_events` |
| `/dashboard/*`, `/reports/*` | FR-053–FR-057 | Read-only across `debts`, `payments`, `collection_cases`, `customers` |
| `/notifications/*`, `/calendar` | FR-058–FR-062 | `notifications`, `follow_up_history`, `promises_to_pay`, `collection_cases` |
| `/search` | FR-063 | Read-only across `customers`, `debts`, `payments`, `receipts`, `demand_letters`, `statements`, `collection_cases` |
| `/admin/*` | FR-066–FR-071 | `users`, `roles`, `user_roles`, `tenants`, `system_settings`, `document_templates`, `reference_data`, `audit_log` |

Every table in `06_Database_Design.md` Section 6 is reachable through at least one endpoint above, except `roles` (seeded, no CRUD endpoint — Section 5, `06` §6.1) and `user_roles` (mutated only via `PATCH /admin/users/{id}/role`, never listed/queried directly).

---

## 14. Decisions Required

Consistent with `06`'s Section 13, surfaced rather than assumed:

1. **Notes & Attachments has no dedicated endpoint.** `03_Functional_Requirements.md` references it (Module 8, reused across Customer/Debt/Collection Case screens) but never gives it its own FR or a "Related APIs" line the way every other capability in this document has. Before implementation, this needs either a small FR addition (Guardian-style reopening of Module 8) or an explicit confirmation that it's covered by the general-purpose file-upload pattern in Section 9. Flagging rather than inventing an endpoint shape.
2. **Default page size / max page size** (Section 8) has no source anywhere in 01–06 — an implementation default will be chosen at build time, not asserted here as if it were approved.
3. **Rate limit thresholds** (`429`, Section 4) depend on `09_Non_Functional_Requirements.md`, which doesn't exist yet — the status code is reserved, not the numbers.
4. **Overpayment API behavior** (`POST /debts/{id}/payments` with `amount` exceeding the remaining balance) currently succeeds unconditionally, per `06`'s posture on DD-016. If DD-016 resolves toward "reject" or "cap," this endpoint's validation (Section 7) needs a follow-up change — flagged, not pre-decided.

---

**End of 07_API_Design.md — Awaiting review and approval.**
