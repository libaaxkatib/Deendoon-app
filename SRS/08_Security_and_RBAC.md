# 08. Security & RBAC

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-08 |
| **Document Title** | Security and Role-Based Access Control |
| **Version** | 1.4 |
| **Status** | Reopened — Section 5 (Roles & Permissions) amended by the RBAC Architecture Amendment |
| **State** | Frozen (pending re-freeze) |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Product Owner |
| **Last Updated** | 2026-07-31 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened v1.5) · `02_Business_Requirements.md` (Reopened v1.6) · `03_Functional_Requirements.md` (v1.10 — **Module 12 still awaiting its original approval**) · `04_Business_Rules.md` (Reopened v1.6) · `05_UI_UX_Specification.md` (Reopened, v1.3) · `06_Database_Design.md` (Reopened v1.6 — §6.1 amended, PostgreSQL) · `07_API_Design.md` (Reopened v1.5 — §5.4 amended) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: full Security & RBAC specification derived from Documents 01–07, resolving every "deferred to `08_Security_and_RBAC.md`" placeholder those documents left open (password hashing, session token format, RBAC permission matrix, brute-force protection). Confirmed the newly-introduced stack items (Redis, React+TypeScript, S3-compatible storage) fill previously-deferred implementation gaps rather than contradicting any frozen document. Explicitly disambiguated the `super_admin` tenant RBAC role from the `deendoon_platform_administrator` platform role throughout, since both were informally called "Super Admin" in prior documents. | Claude |
| 1.1 | 2026-07-24 | Enterprise Architecture Review consistency pass. Two corrections: (1) Password hashing (Section 10) reworded so Argon2id is unambiguously the single documented default and bcrypt is strictly a compatibility fallback, not a co-equal option; (2) Section 14's Token Compromise Response incorrectly implied the Deendoon Platform Administrator could deactivate a tenant's user account via FR-066 — corrected to state that capability belongs to the Tenant Super Admin only, within their own tenant, and that Module 12 grants the Deendoon Platform Administrator no such authority. Verified and confirmed already-compliant on re-check: MFA appears only under Deferred Security Decisions; Redis is documented only as infrastructure (rate limiting, TLS transit) never as a system of record; object storage is described only as "S3-compatible," no AWS-specific language anywhere; PostgreSQL RLS remains framed as a recommendation pending Product Owner adoption throughout; "Tenant Super Admin"/"Deendoon Platform Administrator" terminology is used consistently with no bare "Super Admin" reference anywhere in the document body. No new requirement, business logic, workflow, or permission was introduced. | Claude |
| 1.2 | 2026-07-31 | **RBAC Architecture Amendment (Product Owner Decision).** Section 5's 7-role table (six tenant-scoped roles + one platform role) is replaced: the approved Version 1 product architecture has exactly two user-facing applications (Customer Mobile App, Super Admin Web Dashboard), not the richer multi-role staff structure the original 7-role table assumed. Section 5 now defines exactly two account types — Business Owner (`admin`, Customer Mobile App, one per tenant) and Platform Administrator (`deendoon_platform_administrator`, Super Admin Web Dashboard, unchanged). Operations Manager, Collection Officer (as a login role), Finance, Support, and Viewer are retired as authentication roles; Collection Officer is redefined as an internal Deendoon operational responsibility exercised by Platform Administrator staff after a Professional Collection Request is accepted, not a tenant-side role. Implemented and reflected in `06_Database_Design.md` §6.1, `03_Functional_Requirements.md` FR-041/FR-067, and `04_Business_Rules.md` BRL-035/BRL-071 — see each document's own revision history. | Claude |
| 1.3 | 2026-07-31 | **Scope Baseline metadata correction (Documentation Consistency Audit — Scope Baseline synchronization).** Updated the Scope Baseline field to cite the current approved versions of `02`, `03`, `04`, `05`, `06`, and `07` (previously stale). No security control, role, permission, or approved content changed. | Claude |
| 1.4 | 2026-07-31 | **Scope Baseline metadata correction (Product Vision Amendment ripple).** Updated the Scope Baseline field to cite `01` (v1.4), `03` (v1.10), `04` (v1.6), `05` (Reopened, v1.3), `06` (v1.6), and `07` (v1.5) following those documents' own updates. No security control, role, or permission changed. | Claude |

---

## 1. Purpose

This document specifies the security architecture and Role-Based Access Control model for Deendoon Version 1: authentication, authorization, tenant isolation enforcement, data protection, and audit expectations. It closes out every "deferred to `08_Security_and_RBAC.md`" reference left open across `01`–`07` — those references exist precisely because this document, not an earlier one, is where they belong.

This document does not redesign `06_Database_Design.md` (schema, tables, RLS recommendation) or `07_API_Design.md` (endpoints, request/response shapes) — both remain the source of truth for their respective domains and are referenced, not restated. It does not generate implementation code, middleware, Laravel source, or SQL.

**Guardian boundary:** every control specified below either enforces an already-approved Functional Requirement or Business Rule, or is a standard security-engineering practice with no business-logic content of its own (e.g., TLS, password hashing algorithm choice). Nothing here introduces a new actor, permission, workflow, module, or dashboard. Where a genuine gap exists that no prior document answers and that isn't a routine security-engineering default, it is recorded in **Section 16 — Deferred Security Decisions**, not assumed.

**Terminology disambiguation — read this before Section 5.** `06_Database_Design.md`'s `roles` table defines a tenant-scoped role, originally named `super_admin` (one of six original RBAC roles approved at the start of this SRS) and renamed `admin` under the RBAC Architecture Amendment (v1.2, Section 5) once the other five tenant-side roles were retired. Separately, the Professional Collection Requests reopening introduced `deendoon_platform_administrator` — a *different*, non-tenant-scoped actor informally nicknamed "the Deendoon Super Admin" throughout `06` and `07`. These remain two different roles that happen to share the word "Super Admin" in casual reference. Confusing them in an authorization check would be a real security bug — e.g., granting a tenant's own Business Owner the platform-level power to review *other tenants'* Professional Collection Requests. This document uses **"Business Owner"** (or "Tenant Super Admin" where historical context requires it) for the `admin` role and **"Deendoon Platform Administrator"** for `deendoon_platform_administrator`, without exception, and recommends the same convention going forward in any implementation artifact.

---

## 2. Security Principles

1. **Defense in depth, not single-point trust.** No security property depends on exactly one control. Tenant isolation is application-layer filtering *plus* a recommended PostgreSQL RLS layer (`06` §2); authentication is a validated token *plus* server-side session-record checks; every mutating action is both permission-gated *and* audit-logged.
2. **Server-derived context, never client-supplied.** `tenant_id`, the authenticated `user_id`, and the resolved role are always derived server-side from a validated session token (`07` §2) — never accepted as a request parameter, header, or body field. This is the single rule most of this document's other controls exist to protect.
3. **Fail closed.** An ambiguous authorization state (unresolvable role, expired token, missing tenant context) denies access; it never falls back to a permissive default.
4. **Least privilege, at every layer.** Database roles, API permissions, and file storage access are each scoped to the minimum required — never a shared superuser credential, never a blanket "admin sees everything" grant where a narrower one is possible (`06` §2's relationship-scoped Professional Collection Request policy is the concrete instance of this principle).
5. **Financial and audit records are never destroyed, never silently altered.** Archive replaces delete (BC-002); the Audit Trail is insert-only (BR-030, BRL-076) — this document adds no new write path to either.
6. **Configuration over hardcoding extends to security parameters.** Where no approved document fixes a specific numeric threshold (password minimum length, rate-limit ceiling, session idle timeout), this document states a recommended baseline but does not present it as immovable — consistent with BC-003 and Product Principle 5, and with `06`/`07`'s own treatment of open thresholds.

---

## 3. Authentication

Authentication is **Laravel Sanctum, token (Bearer) mode**, exactly as `07_API_Design.md` §2 specifies. This section adds the security-parameter detail `07` explicitly deferred here; it does not change the mechanism `07` already committed to.

- **Token issuance:** on successful login (FR-001), Sanctum issues an opaque bearer token, persisted server-side and returned to the client once. The client sends it as `Authorization: Bearer <token>` on every subsequent request.
- **Token expiration strategy:** FR-003 requires sliding-window expiry — a session should remain valid while actively used and expire after a period of inactivity. Stock Sanctum tracks `last_used_at` automatically on every authenticated request but does **not** natively slide a token's `expires_at` forward on use — its default behavior is a fixed absolute expiry. Implementing FR-003 as approved therefore requires the token-validation step to compare the current time against `last_used_at + <idle timeout>` (via Sanctum's customizable token-authentication callback) rather than relying solely on a fixed `expires_at`. This is a clarification of how an already-approved requirement maps onto Sanctum's actual behavior, not a new feature.
- **Idle timeout value:** not fixed by this document (Principle 6) — a platform-configured duration, not hardcoded.
- **Token revocation:**
  - Logout (FR-002) revokes **only the current token** — other active sessions on other devices are untouched.
  - Password change (FR-005) and Role change (FR-067) revoke **all** of the user's tokens — every other session must re-authenticate. This matches `07` §2's existing rule; this document adds that "revoke all" means deleting every token row associated with that `user_id`, not merely the current one.
  - Account deactivation (FR-066) should revoke all of that user's tokens as an immediate consequence — a natural extension of the already-approved deactivate action, not a new capability (Section 14).
- **Refresh strategy:** **not applicable.** Sanctum's personal-access-token model has no separate refresh-token/access-token pair (that is an OAuth2/Passport pattern this project explicitly does not use, per `07` §2's rejection of Passport). Continuity of access is provided by the *same* token's sliding-window expiry, not by exchanging it for a new one.
- **Logout behavior:** `POST /auth/logout` (FR-002) invalidates the current session's token and returns `204`. It does not affect other devices' sessions — there is no approved capability for "log out everywhere" as a self-service action distinct from the automatic all-token revocation on password/role change above (no FR describes one; not invented here).
- **Device/multi-session handling:** Sanctum's per-token model inherently permits multiple concurrent sessions (one token per login, potentially across multiple devices). No approved screen in `05_UI_UX_Specification.md` provides a user-facing "view/manage active sessions" capability — so none is specified here. Concurrent sessions are a byproduct of the architecture, not a product feature; if session management UI is wanted later, it is new scope requiring its own FR, not something this document should introduce.
- **Server-derived tenant context, no client-supplied `tenant_id`:** re-affirmed exactly as `07` §2 states it. `06` §2's two structural exceptions (Professional Collection Requests' cross-tenant review; `users.tenant_id IS NULL` for the Deendoon Platform Administrator) are the *only* approved deviations from strict tenant scoping, and both are resolved from the authenticated session's role, never from client input.

---

## 4. Authorization (RBAC)

Authorization is enforced per-request, after authentication resolves the session's `user_id` → `tenant_id` (or `NULL`) → assigned role(s) via `user_roles` (`06` §6.1). Every permission-gated action in `07_API_Design.md` corresponds to an FR whose Exceptions define an "E — user lacks permission" condition; this document is what those conditions have been pointing to.

**RBAC roles are exactly the two already approved** (Section 5, as amended 2026-07-31) — one tenant-scoped (Business Owner), one platform-level (Platform Administrator). No new role, no new permission category, and no new actor is introduced here.

**Enforcement model:** a request is authorized if the resolved role is permitted to perform the requested action on the requested resource, and (for tenant-scoped roles) the resource belongs to the session's own tenant. A denied request returns `403 FORBIDDEN` if the resource exists but isn't permitted, or `404 NOT_FOUND` if the resource doesn't exist or belongs to another tenant (`07` §4's existing masking rule — unchanged here).

**The exact role-to-permission grant is configurable, not hardcoded — by design, not by omission.** Module 12's Role & Permission Management (FR-067) is the approved mechanism for assigning a role to a user; nothing in `01`–`07` states that the set of actions each role may perform is fixed in application code rather than data-driven. Section 5's capability table is this document's *recommended default configuration*, grounded in the actor descriptions already approved in `02_Business_Requirements.md` — it is not a claim that per-role permissions are immutable.

---

## 5. Roles & Permissions

**Amended 2026-07-31 (RBAC Architecture Amendment, Product Owner Decision).** The approved Version 1 product architecture has exactly two user-facing applications — the Customer Mobile App and the Super Admin Web Dashboard — not the richer multi-role staff structure the original six-tenant-role table below assumed. Version 1 therefore has exactly **two account types**:

| Role (`06` `roles.name`) | Tenant-Scoped? | Approved Actor | Capability |
|---|---|---|---|
| `admin` (**Business Owner**) | Yes | BA-001, Business Owner / SME Operator | The single account per tenant on the Customer Mobile App. Full access within the tenant: Customers, Debts, Payments, Collection Cases, Documents, Reports/Dashboard, and Administration (Module 12). May submit a Professional Collection Request (FR-072); **cannot** review or action another tenant's Request — that remains exclusive to the Platform Administrator (BR-042). |
| `deendoon_platform_administrator` (**Platform Administrator**) | **No** | BA-008 | The sole account type on the Super Admin Web Dashboard. Reviews, transitions the status of, and closes Professional Collection Requests (FR-073, FR-076) across every tenant — the one approved cross-tenant capability in Version 1 (BR-042). Has **no** access to any tenant's Customers, Debts, Payments, or Administration outside what `06` §2's relationship-scoped policy exposes through an actual submitted Request. |

**Retired (no longer authentication roles):** `operations_manager`, `finance`, `support`, `viewer` — no second tenant-side account tier exists; every business-side capability above belongs to the one Business Owner account. `collection_officer` is **retired as a login role** and redefined as an internal Deendoon operational responsibility: work performed by Platform Administrator staff *after* a Professional Collection Request has been accepted (FR-073 onward) — it was never a tenant-side actor under the amended model, and FR-041's Collection Case assignment (which previously named this role by name) no longer has a meaningful target under a one-account-per-tenant architecture; see `03_Functional_Requirements.md` FR-041's own revision history.

**Consistency check performed (2026-07-31):** both rows above trace to an already-approved Business Actor (`02_Business_Requirements.md` §2.2, as amended) and an already-approved role name (`06_Database_Design.md` §6.1, as amended). No capability beyond what's textually supported by those two documents, as amended, was added.

---

## 6. Multi-Tenant Security

This section applies `06_Database_Design.md` §2's already-approved architecture to a security frame; it does not redesign it. `06` remains the source of truth for the schema and the RLS design.

- **Primary isolation layer (load-bearing, already approved):** every tenant-owned query is filtered by `tenant_id`, resolved server-side from the authenticated session (Section 3), never from client input. This is the control every other layer below is *in addition to*, not a substitute for.
- **Recommended second layer:** PostgreSQL Row-Level Security, exactly as `06` §2 specifies — **a recommendation, with final adoption an architecture decision for the Product Owner**, not restated here as settled. If adopted, the six-table relationship-scoped design (`professional_collection_requests`, `request_messages` flag-based; `collection_cases`, `debts`, `tenants`, `audit_log` `EXISTS`-scoped through an actual Request) is the approved shape — this document does not alter it.
- **Least privilege:** the application's PostgreSQL role should hold only the privileges its own write paths need (`06` §11) — e.g., `INSERT`-only on `audit_log`, no `UPDATE`/`DELETE` on `receipts`/`demand_letters`/`statements` post-generation. This is a database-account configuration matter, layered on top of, not a replacement for, RLS or application filtering.
- **Defense in depth, stated as a threat model:** a cross-tenant leak requires *simultaneous* failure of (a) the application query-scoping logic, (b) RLS if adopted, and (c) the database role's own privilege boundary. No single bug in any one layer is sufficient on its own to expose another tenant's data.
- **The one approved cross-tenant workflow (Professional Collection Requests) is bounded, not general-purpose.** The Deendoon Platform Administrator's elevated visibility is scoped to exactly the tables and relationship chain `06` §2 defines — it is not a platform-wide superuser grant, and no control in this document extends it further.

---

## 7. PostgreSQL Security

Builds on `06_Database_Design.md` without rewriting it.

- **Database authentication:** the application connects using a dedicated, least-privilege PostgreSQL role — never the database superuser, never a role shared across environments (development/staging/production each get distinct credentials).
- **Encrypted connections:** `sslmode=require` (or stricter, e.g., `verify-full` where a trusted CA chain is available) for every connection between the application and PostgreSQL, matching `06` §11's existing note. Unencrypted connections are not permitted in any environment handling real tenant data.
- **Least-privilege database accounts:** the application role's grants mirror `06` §8's Business Rule Enforcement table exactly — `INSERT`-only on `audit_log`, no post-generation `UPDATE` on the three document tables, standard `SELECT`/`INSERT`/`UPDATE` elsewhere per the approved write paths in `03_Functional_Requirements.md`. No table gets a grant beyond what an approved FR actually needs to write.
- **Backup security:** backups should be encrypted at rest and access-restricted to the same least-privilege standard as the primary database — a security best practice, not itself a business decision. The specific retention period and formal encryption-at-rest policy remain a Deferred Decision (Section 16), carried forward from `06` §13's own unresolved item — this document does not invent a retention window no approved document specifies.
- **Secret management:** database credentials, the Sanctum application key, and S3-compatible storage credentials are never committed to source control or hardcoded — they are supplied via environment configuration or a secrets manager. This document does not mandate a specific secrets-management product; that is an infrastructure/deployment choice outside this document's remit.
- **JSONB considerations:** `06` §6.8's `JSONB` columns (`whatsapp_reminder_days`, `notification_settings`, etc.) and `import_rows.row_data` are not schema-validated by PostgreSQL itself — a `JSONB` column accepts any valid JSON structure. The application must validate and sanitize JSONB content **before** it's trusted or rendered, exactly as it would any other user-influenced input; PostgreSQL's storage flexibility here is not a substitute for application-layer validation (`07` §7).
- **`TIMESTAMPTZ` consistency, security relevance:** `06` §1 Principle 8 already mandates `TIMESTAMPTZ` everywhere for correctness; the security-specific reason to restate it here is that `audit_log.occurred_at` (BR-030) and `sessions`/token `expires_at`/`last_active_at` values are the timestamps an incident investigation would rely on — ambiguous local-time values in exactly those columns would directly undermine Section 14's incident-response procedures. `06`'s existing choice already prevents this; no new column or type decision is introduced here.

---

## 8. API Security

Builds directly on `07_API_Design.md`; endpoints, methods, and response shapes are unchanged.

- **Authentication:** every endpoint marked 🔒 in `07` §5 requires a valid, unexpired Sanctum token (Section 3).
- **Authorization:** every permission-gated action enforces Section 4/5's role model before executing; `403`/`404` semantics unchanged from `07` §4.
- **Validation:** `07` §7's field-level rules are unchanged; this document adds no new validation rule, only confirms that validation happens server-side regardless of any client-side check `05_UI_UX_Specification.md` also performs — client-side validation is a UX convenience, never the security boundary.
- **Rate limiting:** `07` §4 reserved the `429`/`RATE_LIMITED` status without specifying a mechanism or thresholds. With Redis now confirmed as part of the stack, the recommended mechanism is a Redis-backed rate limiter (Laravel's native `RateLimiter`, Redis-backed) applied at minimum to `POST /auth/login` (brute-force protection, Section 10) and `POST /auth/forgot-password` (reset-token exhaustion). **Exact thresholds remain undefined** — that is `09_Non_Functional_Requirements.md`'s concern, not invented here; only the mechanism is specified, consistent with the "how" belonging to this document and the "how much" belonging to an NFR document that doesn't exist yet.
- **Replay protection:** this API's realistic replay exposure is an intercepted bearer token, not a replayed request payload — the mitigation is TLS everywhere (Section 12) preventing interception in the first place, plus short practical token exposure via sliding expiry and immediate revocation on suspicious activity (Section 14). No request-signing, nonce, or timestamp-HMAC scheme is introduced — nothing in `01`–`07` approves that level of protocol complexity, and Sanctum's bearer-token model doesn't natively support it.
- **Idempotency:** unchanged from `07` §3 — `GET`/`PUT`/`PATCH` are idempotent by definition; `POST` actions that create a record are not, and no client-supplied idempotency-key mechanism is approved anywhere, so none is introduced here.
- **File upload validation:** Section 11.
- **Secure error responses:** `07` §4's error envelope is unchanged. Security addition: production error responses never include stack traces, internal file paths, or raw database error text — only the structured `error.code`/`message`/`fields` shape `07` already defines.
- **Audit events:** unchanged from `07` §12 — every mutating endpoint writes to `audit_log` in the same transaction as its primary write.

---

## 9. Session & Token Security

Consolidates Section 3's mechanics into the specific lifecycle/security expectations:

- **Lifecycle:** issued at login (FR-001) → validated and its `last_used_at` refreshed on every authenticated request → expires after the configured idle window (FR-003) or explicit revocation → revoked tokens are never reusable (Sanctum deletes the underlying record; a deleted token fails authentication with `401`, not a soft "expired" state that might be resurrectable).
- **Logout:** single-token revocation only (Section 3) — `204` response, no error state, idempotent if called twice (a second logout on an already-invalidated token is a no-op per FR-002's own Exception handling in `03`).
- **Revoke all tokens:** triggered automatically by password change (FR-005), role change (FR-067), and — as this document's own addition, a natural reading of the existing deactivate action rather than new scope — account deactivation (FR-066). Not available as a standalone self-service "log out everywhere" action, since no FR describes one.
- **Idle timeout:** Section 3 — sliding window, exact duration configurable, not fixed here.
- **Device management:** not specified — no approved screen provides it (Section 3). Flagged, not invented.

---

## 10. Password & Credential Security

This is the document every prior reference to "password policy," "credential storage," and "brute-force protection" has been pointing to — specified here for the first time, not redeferred further.

- **Hashing:** **Argon2id is the single documented default.** bcrypt (Laravel's `Hash` facade default) is a compatibility fallback only, used solely where the deployment environment cannot support Argon2id — it is not a co-equal alternative, and Argon2id is the algorithm this document specifies for new deployments. No custom hashing scheme. `users.credential_hash` (`06` §6.1) stores only the resulting hash, never the plaintext or a reversibly-encrypted form.
- **Password policy:** minimum 12 characters, no mandatory composition rules (no forced mix of symbols/numbers/case) — current OWASP/NIST guidance favors length over arbitrary complexity, which tends to produce predictable substitutions rather than genuinely stronger passwords. No mandatory periodic rotation, for the same reason (forced rotation empirically encourages weaker, incrementally-varied passwords). This baseline is a recommendation consistent with Principle 6 — not hardcoded as an immutable rule, since no approved document fixes these numbers, but stated concretely because no other document was going to.
- **Password reset:** FR-004's approved flow (time-limited, single-use, delivered via the platform-configured recovery channel) is unchanged. Security detail this document adds: the reset token itself is hashed at rest (same standard as a credential, never stored or logged in plaintext), and expires on a short window (recommended: 15–60 minutes, exact value implementation-configurable, not fixed here).
- **Credential storage:** never logged, never included in an API response or error message, never transmitted except at initial submission (login, registration, reset) over TLS.
- **Brute-force protection:** `03_Functional_Requirements.md` Module 1's FR-001 explicitly deferred "detailed lockout/rate-limiting behavior" here. Recommended approach: rate-limit login attempts per identifier and per source (Redis-backed, Section 8), with a progressive backoff after repeated failures from the same identifier. This is presented as a security control, not a new user-facing "account lockout" product feature — no `05_UI_UX_Specification.md` screen describes a lockout notification UI, so none is introduced; the control operates transparently at the API layer, returning the same generic `401`/`429` responses `07` §4 already defines.

---

## 11. File Upload Security

Applies to the two approved upload paths in `07_API_Design.md` §9: Customer Import (FR-016) and Company Logo (FR-068).

- **MIME/content validation:** validated by actual file content (magic bytes), not merely the declared `Content-Type` header or file extension — an attacker-controlled extension is not trusted. Customer Import accepts spreadsheet formats only; Company Logo accepts common image formats only.
- **File size limits:** enforced server-side regardless of any client-side limit `05_UI_UX_Specification.md` also applies (BRL-073's existing redirect to UI/NFR). Exact byte thresholds are not fixed by this document — an implementation/NFR detail, consistent with `06`/`07`'s treatment of the same open item.
- **Malware scanning — recommendation only, not an approved requirement:** scanning uploaded files before they are persisted to object storage is good practice for any user-supplied file, but no FR in `03_Functional_Requirements.md` approves a malware-scanning feature or names a scanning product. This is recorded as a security recommendation for the implementation team to weigh against cost/complexity, not a Version 1 requirement.
- **Storage isolation:** with S3-compatible object storage now confirmed, uploaded files should use tenant-scoped key prefixes (e.g., keyed under the owning `tenant_id`) so one tenant's files are never enumerable or guessable from another's — the object-storage equivalent of the tenant isolation already required at the database layer (Section 6).
- **Signed URLs:** generated documents (Receipts, Demand Letters, Statements — FR-047–052) and Company Logos are not served as permanently public objects. Access is via short-lived, pre-signed URLs generated per authorized request, consistent with these being financial/PII-adjacent artifacts, not public marketing assets.
- **Executable file prevention:** no approved upload path ever needs to accept an executable, script, or archive file type — Customer Import expects spreadsheet data, Company Logo expects an image. Rejecting executable/script MIME types and extensions outright is a safe default with no functional cost to any approved capability.

---

## 12. Data Protection

- **Encryption in transit:** TLS for every network hop this system has — client ↔ API (`07`), API ↔ PostgreSQL (Section 7), API ↔ S3-compatible storage, API ↔ Redis. No plaintext hop anywhere in the architecture.
- **Encryption at rest:** recommended as a baseline security practice for the database volume and S3-compatible storage (most managed PostgreSQL and S3-compatible providers offer this as a configuration option, not a schema change). The **formal policy** — whether it's a hard Version 1 requirement, and any associated data-retention period — remains a Deferred Decision, carried forward unchanged from `06` §13 item 2; this document recommends the technical baseline without asserting the policy decision that document already flagged as unresolved.
- **PII protection:** `customers.name`/`.phone` and `users.name`/`.identifier` (`06` §11) are accessed only through RBAC- and tenant-scoped queries (Sections 4, 6), never included in URLs or query parameters (`07` Principle 3's existing money-and-identifier handling extends naturally to PII), and never written to application logs in plaintext.
- **Auditability:** unchanged from `06`/`07` — the Audit Trail (Section 13) is the system of record for who did what, when.
- **Financial data protection:** Debts and Payments are protected by the same tenant isolation, RBAC, and audit logging as every other tenant-owned table — no separate financial-data-specific control is introduced, since none is approved anywhere; `NUMERIC(12,2)` (`06` §1 Principle 7) already prevents floating-point corruption of monetary values at the storage layer.

---

## 13. Audit & Security Logging

`06_Database_Design.md` §6.9's `audit_log` table is not redesigned here — no column, constraint, or index changes. This section states the **security expectations** that table already structurally satisfies, plus operational guidance:

- **Tamper evidence:** already enforced — `INSERT`-only database grant (`06` §8), no `UPDATE`/`DELETE` path anywhere in `03`/`07`. This document adds no new write path.
- **Coverage:** the approved event catalog (`06` §6.9's `action` values) already includes both authentication events (`login`, `logout`) and every business-mutating action this document's controls gate — no additional event type is introduced.
- **Access to the log itself is permission-gated:** `GET /admin/audit-trail` (FR-071) is restricted per Section 4/5's role model — Audit Trail visibility is itself a controlled capability, not open to every authenticated user.
- **Monitoring recommendation (operational, not a new feature):** periodic review of `audit_log` for anomalous patterns (repeated failed logins, unusual `recovery_stage_override` frequency, off-hours `role_changed` events) is good practice. This document does not specify alerting tooling or thresholds — that is an operations/NFR concern, not a schema or product feature.
- **Retention:** not fixed by this document — carried forward as a Deferred Decision alongside `06`'s existing encryption/retention item (Section 16), since no approved document specifies how long audit history must be kept.

---

## 14. Incident Response & Account Protection

- **Suspicious login handling:** rate limiting and progressive backoff (Section 10) are the primary automated control. This document does not introduce a user-facing "unusual login" notification feature — no FR or `05` screen describes one; flagged as a possible future enhancement (Section 16), not specified as current scope.
- **Account lockout:** achieved via the brute-force rate-limiting described in Section 10, not a separate manually-configured lockout list — consistent with keeping this a transparent API-layer control rather than a new administrative feature.
- **Token compromise response:** self-service — a user who suspects compromise changes their password (FR-005), which revokes all of their tokens (Section 3) automatically. Admin-assisted response — an authorized **Tenant Super Admin deactivates the affected account within their own tenant** (FR-066), which should revoke its tokens as an immediate consequence (Section 3's stated extension of the existing deactivate action). **The Deendoon Platform Administrator has no role here:** FR-066's User Administration capability is Module 12, a tenant-scoped screen — nothing in `01`–`07` grants the Deendoon Platform Administrator authority to deactivate a tenant's user account, and this document does not introduce that permission. If the Deendoon Platform Administrator's own account were compromised, the same self-service path (FR-005) applies to them as to any user.
- **Audit review:** the operational recommendation in Section 13 — reviewing `audit_log` for the specific entity/user involved is the concrete first step in investigating a suspected compromise, since every state change involving that account is already captured there by design.
- **Recovery procedures:** self-service recovery is FR-004's existing Forgot Password flow. Admin-assisted recovery for a fully locked-out user — an administrator resetting *another* user's credential on their behalf — is **not explicitly specified** in FR-066's approved Main Flow (which covers create/view/update/deactivate, not force-resetting another user's password). This is flagged in Section 16 rather than assumed, since it would be a plausible but currently unconfirmed extension of Module 12's User Administration capability.

---

## 15. Security Traceability Matrix

| Security Topic | Functional Requirements | Business Rules | Database Design (`06`) | API Design (`07`) |
|---|---|---|---|---|
| Authentication & session lifecycle | FR-001–FR-006 | BRL-007–BRL-011 | §6.1 `users`, `sessions` | §2, §5.1 |
| Password & credential security | FR-004, FR-005 | BRL-007, BRL-008 | §6.1 `users.credential_hash` | §5.1 |
| RBAC / roles & permissions | FR-006, FR-066, FR-067 | BR-028, BR-029, BRL-002, BRL-071, BRL-072 | §6.1 `roles`, `user_roles` | §5.10 |
| Multi-tenant isolation | Cross-cutting (Section 6) | BC-004, BC-009 | §2 (Multi-Tenant Strategy, RLS recommendation) | §2 |
| API security (validation, errors, rate limiting) | Cross-cutting | — | — | §3, §4, §7 |
| File upload security | FR-016, FR-068 | BRL-073 | §6.2 `import_batches`/`import_rows`, §6.8 `tenants.logo_path` | §9 |
| Data protection / encryption | Cross-cutting | BR-033 (durability, not encryption) | §11 (Security Considerations) | §12 (Audit & Logging Considerations) |
| Audit & security logging | FR-030 (BR-030), FR-071 | BRL-003, BRL-076 | §6.9 `audit_log`, §8 | §11, §13 |
| Incident response | FR-004, FR-005, FR-066 | — | — | — |

---

## 16. Deferred Security Decisions

Consistent with `06`/`07`'s own registers, the following are surfaced rather than assumed:

1. **Formal encryption-at-rest policy and data-retention period** (Section 12) — carried forward unresolved from `06` §13 item 2. This document recommends the technical baseline; the policy decision belongs to `09_Non_Functional_Requirements.md`.
2. **Backup encryption and retention specifics** (Section 7) — same status as item 1, specific to backup artifacts.
3. **Rate-limit thresholds** (Section 8) — mechanism specified (Redis-backed), exact numeric limits deferred to `09_Non_Functional_Requirements.md`, which does not yet exist.
4. **Malware/virus scanning** (Section 11) — recommended, not approved as a Version 1 requirement; tool/vendor selection is a future decision if the recommendation is accepted.
5. **Admin-initiated password reset for another (locked-out) user** (Section 14) — not explicitly covered by FR-066's approved Main Flow. Needs either confirmation that Module 12's Update User capability already covers this, or a small, deliberate FR addition if it doesn't.
6. **Multi-factor authentication** — not approved anywhere in `01`–`07`. Flagged here as a recognized OWASP-recommended control for a financial platform, worth considering for a future version — not specified as Version 1 scope, since no approved document requests it.
7. **Session/device management UI** (Sections 3, 9) — no approved screen provides "view/manage active sessions"; flagged as absent, not invented.
8. **Password minimum length and complexity baseline** (Section 10) — a recommended default (12 characters, no forced composition rules) is stated because no other document was going to state one; treated as configurable, not immovable, per Principle 6.
9. **Secrets management tooling** (Section 7) — this document states the requirement (never hardcoded, environment/secrets-manager-supplied); the specific tool is an infrastructure decision outside this document's remit.

None of the above block this document from being complete as a specification; they are implementation- or policy-level decisions that should be resolved before the corresponding control is built, and are recorded here so they aren't silently forgotten.

---

## Internal Architecture Review — Confirmation

Performed before presenting this document, per your instruction:

- **Laravel 13 / Sanctum best practices:** token mode (not SPA/cookie mode) confirmed consistent with a native mobile client (Flutter) plus a separate web app (React+TypeScript); sliding-expiry-via-`last_used_at` correctly identified as requiring a custom check rather than assuming stock Sanctum provides it natively; `Hash` facade with Argon2id as the single documented default and bcrypt strictly as a compatibility fallback aligns with current Laravel and OWASP guidance.
- **PostgreSQL security best practices:** least-privilege roles, `sslmode=require`, JSONB's lack of native schema validation, and `TIMESTAMPTZ`'s incident-response relevance are all addressed without contradicting `06`.
- **OWASP API Security Top 10 alignment:** Broken Object Level Authorization → Section 4/6 (tenant + role scoping, `403`/`404` masking); Broken Authentication → Sections 3, 9, 10; Excessive Data Exposure → Section 8 (secure error responses), Section 12 (PII handling); Lack of Resources & Rate Limiting → Section 8; Broken Function Level Authorization → Section 4/5; Security Misconfiguration → Section 7; Improper Assets Management → out of this document's scope (API versioning already covered in `07` §3). Injection is structurally mitigated by `07`'s parameterized-query expectation and is not restated as a new control here.
- **OWASP ASVS alignment (where applicable):** V2 (Authentication) → Sections 3, 9, 10; V4 (Access Control) → Sections 4, 5, 6; V8 (Data Protection) → Section 12; V9 (Communications) → Section 7, 12 (TLS everywhere); V7 (Error Handling/Logging) → Sections 8, 13.
- **Multi-tenant consistency:** every claim in Section 6 was checked against `06_Database_Design.md` §2 verbatim — no restatement introduces a stronger or weaker guarantee than `06` already specifies, and the "recommended, not adopted" framing for RLS is preserved exactly.
- **Cross-document consistency:** every "deferred to `08_Security_and_RBAC.md`" reference found across `01`–`07` (password hashing, session token format, RBAC permission matrix, brute-force/lockout policy) is resolved somewhere in this document — none were left unaddressed, and none were resolved by inventing scope beyond what those references anticipated.
- **Naming consistency:** the `super_admin` / `deendoon_platform_administrator` disambiguation is applied throughout — a targeted search of this document confirms "Super Admin" is never used bare without one of the two qualifying terms.
- **Traceability:** every section maps to Section 15's matrix; no control lacks an FR/BR/table/endpoint anchor.
- **Guardian compliance:** no new module, workflow, table, actor, permission, or dashboard was introduced. Every place this document goes beyond restating `01`–`07` is either a routine security-engineering default (hashing algorithm, TLS) or explicitly flagged in Section 16.

---

**End of 08_Security_and_RBAC.md — Approved. Frozen (v1.1).** No further modifications are permitted unless required by an approved scope change, a documented architecture issue, a security issue, or a contradiction with another approved document (Project Guardian rule, consistent with 01–07).
