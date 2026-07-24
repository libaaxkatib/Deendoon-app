# 09. Non-Functional Requirements

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-09 |
| **Document Title** | Non-Functional Requirements |
| **Version** | 1.0 |
| **Status** | Approved |
| **State** | Frozen |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Product Owner |
| **Last Updated** | 2026-07-24 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened v1.3) · `02_Business_Requirements.md` (Reopened v1.3) · `03_Functional_Requirements.md` (v1.7 — **Module 12 still awaiting its original approval**) · `04_Business_Rules.md` (Reopened v1.3) · `05_UI_UX_Specification.md` (Approved & Frozen, v1.1) · `06_Database_Design.md` (Approved & Frozen, v1.3, PostgreSQL) · `07_API_Design.md` (Approved & Frozen, v1.1) · `08_Security_and_RBAC.md` (Approved & Frozen, v1.1) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: full Non-Functional Requirements specification, closing out every "deferred to `09_Non_Functional_Requirements.md`" reference left open across `06`, `07`, and `08` (rate-limit thresholds, encryption-at-rest/retention policy, backup specifics) — each either resolved here as a stated goal/target or explicitly carried into Section 18 where it remains a genuine deployment/operational decision. Localization (English/Somali) documented for the first time per this request; flagged as new ground not present in any prior document, specified at the goal level only. | Claude |

---

## 1. Document Purpose

This document specifies the quality attributes Deendoon Version 1 must meet — performance, scalability, availability, reliability, maintainability, observability, backup/disaster recovery, usability/accessibility, localization, compatibility, capacity, compliance, quality assurance, and operational support. It closes out the "deferred to `09_Non_Functional_Requirements.md`" references left open by `06_Database_Design.md`, `07_API_Design.md`, and `08_Security_and_RBAC.md` — this is the document those references were pointing to.

This document does not redesign any approved architecture (`06`'s schema and RLS recommendation, `07`'s API surface, `08`'s security controls remain exactly as frozen) and does not generate implementation code, configuration files, or infrastructure scripts. Where a requirement genuinely depends on a deployment or operational choice no approved document has made, it is recorded in **Section 18 — Deferred Operational Decisions**, not assumed.

**Guardian boundary:** nothing below introduces a new module, workflow, actor, API endpoint, database table, business rule, or permission. Performance and availability figures are stated as **design targets/goals**, not contractual SLAs — no approved document commits to a formal service-level agreement, and this one doesn't invent one.

---

## 2. Non-Functional Requirements Overview

| Category | Governs | Primary Source Already Approved |
|---|---|---|
| Performance | Response-time and processing-time targets | `06` §10 (indexing), `07` (endpoint surface) |
| Scalability | Growth handling without redesign | `06` §2 (multi-tenant strategy) |
| Availability | Uptime goals, degradation behavior | New — no prior document addressed this |
| Reliability | Transaction integrity, retry/failure handling | `06` §8 (transaction atomicity) |
| Maintainability | Code organization, standards, versioning | `07` §3 (API versioning), `01` (module structure) |
| Observability | Logging, monitoring, alerting, health checks | `08` §13 (audit logging, distinct from this) |
| Backup & DR | Data durability and recovery | BR-033 (Automated Infrastructure Backups) |
| Usability & Accessibility | Mobile/web usability, accessibility | `05` §12, §13 (already approved, reaffirmed) |
| Localization | Language support | New — introduced in this document per instruction |
| Compatibility | Supported platforms | `01` §1.8 (two client applications) |
| Capacity Planning | Architectural growth characteristics | `06` §2, §10 |
| Compliance | Data protection best practice | `08` §12 |
| Quality Assurance | Testing strategy | Cross-cutting |
| Support & Operations | Production support processes | `08` §14 (incident response, reaffirmed) |

---

## 3. Performance Requirements

All figures below are **design targets**, not contractual SLAs, and are explicitly classified as deployment/data-volume dependent where exact numbers can't be fixed without knowing production scale — consistent with the instruction not to invent unrealistic benchmarks.

- **API response expectations:** for simple, single-record operations (`GET /customers/{id}`, `POST /debts/{id}/payments`, etc. — `07` §5), a p95 target under **300ms** under normal load. For list/report endpoints with typical pagination (`07` §8), a p95 target under **1 second**. For heavier aggregation endpoints (Aging Analysis, Dashboard KPIs — FR-053/054), a p95 target under **2–3 seconds**, acknowledging these scale with per-tenant data volume and are the endpoints most likely to need the indexing already specified in `06` §10.
- **Page loading expectations (React + TypeScript, Super Admin Web Dashboard):** initial load target under 3 seconds on a standard broadband connection; subsequent in-app navigation (client-side routing) under 1 second, consistent with `05`'s SPA-style screen transitions.
- **Mobile responsiveness (Flutter, Customer Mobile App):** cold start target under 3 seconds on a mid-range Android device; touch-to-visual-feedback under 100ms, the standard threshold at which an interaction reads as instantaneous to a user (Nielsen's response-time guidelines) — not a number specific to this project, a well-established UX baseline.
- **Database query expectations:** simple indexed lookups (the `tenant_id`-leading indexes already specified in `06` §10) target under 50ms. Aggregation queries (Aging Analysis, KPI computation) are explicitly **deployment/data-volume dependent** — `06` already declined to introduce a materialized-view/summary-table optimization speculatively; if measured performance requires one, that's a future `06` amendment, not assumed here.
- **Background job processing expectations:** queued work (Smart Daily Reminder evaluation, FR-029; asynchronous Customer Import commit, FR-016) should begin processing within seconds of being queued under normal load. The full daily reminder evaluation across a tenant's Debts should complete comfortably within its 24-hour operating cadence — an exact processing-window commitment (e.g., "before business hours") is a deployment/operational decision (Section 18), not fixed here.

---

## 4. Scalability Requirements

Scalability is described in terms of the **already-approved architecture's** capacity to absorb growth — this section does not redesign anything in `06`.

- **Multi-tenant architecture:** `06` §2's shared-database, shared-schema, `tenant_id`-discriminator pattern scales horizontally by adding application-tier instances and, if needed, PostgreSQL read replicas — the pattern itself doesn't require redesign as tenant count grows. If PostgreSQL RLS (`06` §2, still a recommendation pending Product Owner adoption) is adopted, it does not materially change this horizontal-scaling story — RLS policies reuse the same `tenant_id` indexes already required for performance.
- **Increasing Customers/Debts:** per-tenant query performance is protected primarily by tenant isolation itself (one tenant's data growth doesn't degrade another's queries, since every index is `tenant_id`-leading) rather than by the *total* platform-wide row count. If an individual tenant's own data volume eventually warrants it, PostgreSQL table partitioning (e.g., by `tenant_id` or `due_date`) is a available future lever — noted as an option, not committed to as a Version 1 requirement.
- **Increasing Professional Collection Requests:** the Deendoon Platform Administrator's cross-tenant queue view (SCR-049) is served by the `status`-indexed lookup already defined in `06` §6.5. This traffic is inherently bounded by a single actor's review capacity, not by tenant count — consistent with `06`/`07`/`08`'s consistent characterization of this as low-volume relative to ordinary tenant traffic.
- **Background queues:** Redis-backed Laravel queues scale by adding worker processes; queue depth is an Observability concern (Section 8), not a scalability redesign.
- **File storage growth:** S3-compatible object storage scales independently of the application/database tier by design — it is not a capacity constraint this document needs to plan around. Tenant-scoped key prefixing (`08` §11) is already the approved isolation pattern and incidentally supports per-tenant storage accounting if that's ever wanted, without that being a committed feature here.

---

## 5. Availability Requirements

- **High availability goal:** a target of **99.5%+ monthly uptime** for the API and both client applications' backing services — a standard, achievable goal for a Version 1 SaaS product (not "five nines," which would be an unrealistic Version 1 commitment). Stated as a design goal, not a contractual SLA — no approved document commits to a formal SLA, and none is introduced here.
- **Planned maintenance:** brief, advance-notified maintenance windows, scheduled off-peak where the tenant base's peak usage pattern is known. No specific day/time is fixed here — an operational scheduling decision.
- **Graceful degradation:** a distinction worth making explicit, consistent with `08` Principle 3 ("fail closed" for security-critical decisions): a Redis outage should degrade non-critical capabilities gracefully (e.g., rate limiting or caching temporarily unavailable) rather than taking the entire API down, whereas an authentication/authorization failure must still fail closed exactly as `08` requires. These are not in tension — they apply to different failure classes.
- **Service recovery expectations:** automated process health-checking and restart (Section 8) is the first line of recovery; no specific Mean-Time-To-Recovery figure is fixed here — deployment-dependent (Section 18).

---

## 6. Reliability Requirements

- **Transaction integrity:** reaffirms `06` §8's already-approved requirement — multi-table writes (the Payment-recording sequence: `payments` insert → `debts.remaining_balance` update → `customers.outstanding_balance` update → `audit_log` insert, per FR-034/036/037) must be wrapped in a single database transaction. Not redesigned here, only restated as an NFR-level reliability expectation.
- **Queue reliability:** Redis-backed Laravel queues should use Laravel's standard retry-with-backoff and failed-job tracking (a well-established Laravel-native pattern, not new architecture) for jobs that fail transiently — e.g., WhatsApp/SMS reminder delivery failures, an Open Item already acknowledged in `03_Functional_Requirements.md` Module 5 (FR-029/030) as having deferred retry-policy detail.
- **Retry strategy:** exponential backoff for transient external-channel failures (reminder delivery), consistent with standard operational practice — this document does not invent a new business rule about how many retries or what the resulting Debt/Customer state should be; that remains `04_Business_Rules.md`'s domain if and when it's resolved.
- **Failure recovery expectations:** idempotent operations (`GET`/`PUT`/`PATCH`, per `07` §3) are safe to retry automatically. Non-idempotent `POST` actions and queued jobs representing a one-time state transition (e.g., "Reminder Sent") should be implemented so a retry doesn't double-send or double-record — a background-job design consideration flagged here, not a new deduplication mechanism this document specifies in detail.

---

## 7. Maintainability Requirements

- **Modular architecture:** the codebase's organization should mirror the twelve approved Functional Requirements modules (`03`) — a natural, non-inventive mapping from already-approved domain boundaries into code structure, not a new architectural decision.
- **Documentation requirements:** this SRS is the primary specification of record; code-level documentation is expected only where logic is genuinely non-obvious (e.g., the RLS policy predicates from `06` §2, if adopted), consistent with this SRS's own established commenting philosophy.
- **Coding standards:** PSR-12 for the Laravel/PHP codebase, ESLint + Prettier with TypeScript strict mode for the React Admin Dashboard, the effective Dart style guide for the Flutter Customer App — each the standard, community-recognized convention for its respective already-approved stack component, not a new choice this document is inventing.
- **Versioning:** API versioning is unchanged from `07` §3 (`/api/v1`, URL-path versioned). Application releases follow semantic versioning as standard practice.
- **Dependency management:** Composer (PHP/Laravel), npm/yarn (React), and pub (Flutter/Dart) — the standard package manager for each already-approved stack component.
- **Configuration management:** environment-based configuration, never hardcoded, consistent with BC-003 and `08` §7's secret-management principles — reaffirmed, not redesigned.

---

## 8. Observability (Logging, Monitoring & Alerting)

No external monitoring vendor is named anywhere in this section, per instruction — capabilities are described generically; tool selection is Section 18's concern.

- **Structured logging:** application logs should be structured (e.g., JSON) to support machine parsing and correlation. Explicitly **distinct from the Audit Trail** (`06` §6.9, `08` §13) — application/error logs capture operational events for debugging; `audit_log` captures approved business events for accountability. Conflating the two would violate `audit_log`'s immutability and narrow, approved event catalog.
- **Application monitoring / performance monitoring:** the application should expose the metrics needed to evaluate Section 3's targets (response times, error rates, queue depth) to *some* monitoring capability — which capability/vendor is a Deferred Operational Decision (Section 18), not fixed here.
- **Audit monitoring:** reaffirms `08` §13's recommendation — periodic review of `audit_log` for anomalous patterns. Not a new capability; this document adds no new audit event type or table.
- **Error tracking:** unhandled exceptions should be captured and surfaced for triage, without ever leaking stack traces or internal detail into a client-facing response (`08` §8's existing secure-error-response rule, reaffirmed, not loosened).
- **Health checks:** a lightweight, operations-only mechanism confirming API process liveness, database connectivity, Redis connectivity, and queue-worker liveness. This is explicitly **not** part of `07`'s approved business API surface — it's operational tooling, not a new business endpoint, and is called out here to avoid any impression that it expands `07`'s Guardian-reviewed endpoint inventory.
- **Alerting strategy:** alerts should fire on defined failure conditions (elevated error rate, queue backlog beyond a threshold, failed health checks). Exact thresholds and **notification channels** are a Deferred Operational Decision (Section 18), per instruction.

---

## 9. Backup & Disaster Recovery

- **PostgreSQL backups:** automated, regular backups are already approved Version 1 scope (BR-033, "Automated Infrastructure Backups," and `06` §11's least-privilege backup-access note) — this section operationalizes that approval rather than introducing it. PostgreSQL's Write-Ahead Log (WAL) archiving / point-in-time recovery is the standard mechanism for minimizing data-loss exposure between full backups — a well-established PostgreSQL practice, not new architecture.
- **Object storage backups:** S3-compatible providers typically offer built-in durability and replication; this document does not assert a specific numeric durability guarantee (that varies by provider and is not something a generic "S3-compatible" commitment can promise) — versioning/replication is recommended as a practice, with the specific provider's guarantee a Deferred Operational Decision.
- **Recovery objectives (RPO/RTO):** the goal is to **minimize** data-loss window and restore-time window — exact numeric targets (e.g., "RPO ≤ X minutes," "RTO ≤ Y hours") depend on infrastructure choices no approved document has made, and are recorded in Section 18 rather than invented here.
- **Backup verification / restore testing:** periodic test restores to confirm backup integrity are a recommended best practice. No specific test cadence is fixed here — an operational scheduling decision (Section 18).

---

## 10. Usability & Accessibility

This section reaffirms `05_UI_UX_Specification.md`'s already-approved content rather than restating it in full — `05` remains the source of truth.

- **Mobile usability:** `05`'s Mobile-First design principle (§1) is unchanged and reaffirmed as a formal NFR.
- **Responsive web usability:** `05` §13's Responsive Rules (desktop/tablet/mobile/very-small-screen/large-monitor behavior) are unchanged and reaffirmed.
- **Keyboard accessibility:** `05` §12's keyboard navigation, focus order, and focus-trap requirements are unchanged and reaffirmed.
- **Color contrast:** `05` §12's WCAG 2.1 AA contrast requirement is unchanged and reaffirmed.
- **Screen reader considerations:** `05` §12's ARIA and screen-reader compatibility requirements are unchanged and reaffirmed, including the color-independence rule (status never conveyed by color alone).

No new accessibility requirement is introduced here — this section exists so accessibility is formally represented in the NFR catalog, not because `05`'s treatment was incomplete.

---

## 11. Localization & Internationalization

**This is the first mention of language/localization support anywhere in Documents 01–08.** No approved Functional Requirement, screen (`05`), or database column (`06`) describes a language switcher, translated content storage, or multi-language UI. Documented here at the instructed level — a Non-Functional goal — not as a new feature specification.

- **Supported languages: English and Somali only**, per instruction. No additional language is introduced.
- **Scope of this requirement, stated conservatively:** the application's UI text and user-facing generated content should be capable of supporting these two languages. This document does **not** specify: which content is translated (UI chrome only vs. also Document Templates/Notifications), how a language preference is stored or selected, or any database/schema change to support it — because no prior document establishes any of that, and inventing it here would mean designing a feature `05`/`06` never anticipated.
- **If implemented, this needs to flow back into `05_UI_UX_Specification.md` (a language-selection UI surface) and `06_Database_Design.md` (a locale/preference column and, if content itself is translated, a storage strategy for translated strings) as a deliberate scope decision** — not silently assumed by this document. Recorded also in Section 18.
- Both English and Somali are written left-to-right in Latin script, so no right-to-left layout consideration applies.

---

## 12. Compatibility Requirements

- **Browsers (React + TypeScript, Super Admin Web Dashboard):** current versions of Chrome, Firefox, Safari, and Edge — the standard "evergreen browser" support model. No specific version number is fixed, since browser auto-update cadence makes a pinned number obsolete almost immediately; this is the conventional, defensible way to state browser support, not an omission.
- **Android (Flutter, Customer Mobile App):** current and prior major Android OS release, consistent with Flutter's own standard support window. No specific API level is fixed here — an implementation/build-configuration detail.
- **iOS (Flutter, Customer Mobile App):** current and prior major iOS release, on the same basis.
- **Explicitly out of scope:** any platform beyond the two approved client applications (`01` §1.8, `08` §1) — no desktop native application, no legacy/unsupported OS version, no third client. This is a direct consequence of the already-approved "exactly two application interfaces" architecture, not a new restriction introduced here.

---

## 13. Capacity Planning

**No business growth forecast exists in any approved document, and none is invented here.** This section addresses architectural capacity characteristics only, per instruction.

- The multi-tenant architecture (`06` §2) is designed so that adding tenants does not require a schema change — new tenants are new rows, not new tables or new database instances.
- Per-tenant data growth (more Customers, Debts, Payments) is handled by the indexing strategy already specified in `06` §10, which scopes the cost of a tenant's own growth to that tenant's own queries, not the platform's aggregate size.
- The application tier (Laravel/React/Flutter-served API) is stateless per request (session state lives in the `sessions`/token store, not in-process — `06` §6.1, `08` §3), which is what makes horizontal scaling (adding more application instances) a viable lever without architectural change.
- Object storage and the Redis-backed queue/cache layer scale independently of the application and database tiers.
- **What this section does not do:** predict a specific tenant count, transaction volume, or timeline — those are business inputs this document has no basis to assert, consistent with the explicit instruction not to invent business forecasts.

---

## 14. Compliance Requirements

- **General data protection best practice only** — this document reaffirms `08` §12's data protection principles (encryption in transit, recommended encryption at rest, PII access control, auditability) as the compliance baseline.
- **No compliance certification is claimed.** No approved document anywhere in `01`–`08` asserts SOC 2, ISO 27001, PCI-DSS, GDPR, or any other formal certification or regulatory framework applies to Deendoon Version 1, and none is claimed here. If a specific regulatory or certification requirement applies to Deendoon's actual operating market, that is a business input that would need to be supplied and would flow into this document as a deliberate addition — not assumed.
- Financial data handling (Debts, Payments) follows the same access-control, tenant-isolation, and audit-logging baseline as every other tenant-owned data category (`08` §12) — no separate financial-compliance regime is introduced, since none is approved.

---

## 15. Quality Assurance Requirements

| Testing Type | Scope | Tooling (standard for the already-approved stack) |
|---|---|---|
| Unit testing | Individual functions/classes across all three codebases | PHPUnit/Pest (Laravel), Jest + React Testing Library (React), Flutter's built-in `test` package |
| Integration testing | Cross-module flows with real dependencies — especially the multi-table Payment-recording transaction (`06` §8) and Professional Collection Request status transitions (`04` BRL-079) | Framework-native integration test suites |
| API testing | Every endpoint in `07` §5 against its documented request/response shape, status codes, and error envelope (`07` §4) | HTTP-level test suite against the running API |
| End-to-end testing | Critical approved user journeys — e.g., Debt creation → Payment → Receipt generation (FR-017/034/047); Professional Collection Request submission → review → closure (FR-072–076) | Browser/device automation appropriate to each client |
| Regression testing | Full suite re-run on every change, as standard CI practice | CI pipeline (tooling: Deferred Operational Decision, Section 18) |
| Performance testing | Validates Section 3's stated targets, with particular attention to `06`'s explicitly high-insert tables (`audit_log`, `notifications`, `follow_up_history`) under load | Load-testing tool (specific product: Deferred, Section 18) |
| Security testing | Periodic testing against `08`'s OWASP API Security Top 10 and ASVS alignment (`08`, Internal Architecture Review section) | Manual review + automated scanning (tooling: Deferred) |

No new testable behavior is introduced by this table — it maps testing activity onto capability already approved elsewhere.

---

## 16. Support & Operational Requirements

- **Production support expectations:** issues should be triaged and responded to in a timeframe proportional to severity. No specific numeric response-time commitment (e.g., "P1 within N hours") is fixed here — that is a business/contractual decision with no basis in any approved document, recorded in Section 18.
- **Incident management:** reaffirms and extends `08` §14's already-approved incident-response process (suspicious login handling, token compromise response, audit review) to general operational incidents (service outages, data anomalies) at a process level: detect → triage → contain → resolve → review. No new tooling is introduced.
- **Change management:** standard practice — code review before merge, staged deployment, and a rollback capability for releases. General best practice, not new architecture.
- **Release management:** builds on `07` §3's existing API versioning approach (`/api/v1`); a breaking API change ships under a new version path rather than altering `/v1` in place, exactly as `07` already specifies.

---

## 17. Non-Functional Traceability Matrix

| NFR Category | Traces To |
|---|---|
| Performance | `06` §10 (indexing strategy), `07` §5 (endpoint surface) |
| Scalability | `06` §2 (multi-tenant strategy), `06` §10 |
| Availability | New in this document — no prior approved requirement |
| Reliability | `06` §8 (transaction atomicity), `03` Module 5 Open Items (retry policy) |
| Maintainability | `07` §3 (versioning), `01` §1.6 (module structure), BC-003 |
| Observability | `08` §13 (audit logging, distinct), `06` §6.9 |
| Backup & DR | BR-033 (Automated Infrastructure Backups), `06` §11 |
| Usability & Accessibility | `05` §12, §13 (reaffirmed, not redesigned) |
| Localization | New in this document — flagged, not previously approved |
| Compatibility | `01` §1.8 (two approved client applications) |
| Capacity Planning | `06` §2, §10 |
| Compliance | `08` §12 |
| Quality Assurance | `07` §5 (API contracts), `06` §8 (transaction scenarios), `04` BRL-079 |
| Support & Operations | `08` §14 (incident response, reaffirmed) |

---

## 18. Deferred Operational Decisions

Consistent with `06`/`07`/`08`'s own registers, the following are deployment- or business-policy decisions this document does not have a basis to assume:

1. **Backup schedule** (Section 9) — exact frequency/cadence.
2. **Monitoring platform** (Section 8) — no vendor named, per instruction.
3. **Alert notification channels** (Section 8) — e.g., email/SMS/chat-ops integration for ops alerts; not specified.
4. **Infrastructure sizing** (Sections 3–5) — server/instance counts and specifications.
5. **CDN choice** (implicitly relevant to Section 3's page-load targets) — not specified; no approved document requires a CDN, and none is assumed here.
6. **Object storage provider** (Section 9, `08` §11) — "S3-compatible" is the approved constraint (`08` §11); the specific provider is not chosen here.
7. **Exact RPO/RTO figures** (Section 9) — goals stated qualitatively; numeric targets depend on infrastructure choices above.
8. **Production support SLA tiers** (Section 16) — response-time commitments by severity.
9. **CI/CD and load-testing tooling** (Section 15) — testing *strategy* is specified; specific products are not.
10. **Localization implementation mechanism** (Section 11) — translated-content scope, storage, and UI language-selection surface; needs a deliberate `05`/`06` scope decision if pursued, not assumed here.
11. **Regulatory/compliance framework applicability** (Section 14) — no certification or regulatory regime is claimed; if one applies to Deendoon's actual operating market, that's a business input not yet supplied.

None of the above block this document from being complete as a specification of *what* is required; they are *how much*/*with what tool* decisions appropriately left to implementation and operations planning.

---

## Internal Architecture Review — Confirmation

Performed before presenting this document, per instruction:

- **Laravel 13 best practices:** queue retry/failed-job handling (Section 6) and environment-based configuration (Section 7) reflect standard, current Laravel conventions; nothing assumes a deprecated pattern.
- **PostgreSQL best practices:** WAL-based point-in-time recovery (Section 9) and the reaffirmation that indexing (not schema redesign) is the primary performance lever (Section 3, §13) are consistent with `06`'s already-approved PostgreSQL architecture.
- **Redis best practices:** used only for queue backing and rate-limiting/cache state (Sections 3, 6, 8), never described as a system of record — consistent with `08`'s own confirmed framing.
- **Scalability consistency:** every claim in Section 4 was checked against `06` §2/§10 — no restatement asserts a stronger or different scaling mechanism than `06` already specifies.
- **Security consistency:** Section 8's health-check/monitoring content was checked against `07`'s approved endpoint inventory to confirm it introduces no new business API surface; Section 14 reaffirms rather than restates `08` §12.
- **Cross-document consistency:** every "deferred to `09`" reference located across `06`, `07`, and `08` (rate-limit thresholds, encryption-at-rest/retention policy, backup schedule/verification) is addressed somewhere in this document — either resolved at the goal level or explicitly carried into Section 18.
- **Performance consistency:** all numeric targets in Section 3 are framed as goals, explicitly distinguished from contractual SLAs, and classified as deployment-dependent wherever data volume affects them — no figure is presented as a guarantee.
- **Naming consistency:** "Tenant Super Admin" / "Deendoon Platform Administrator" terminology from `08` is not contradicted anywhere this document references roles (Section 5's overview table does not restate RBAC detail, avoiding any risk of drift from `08`'s definitions).
- **Traceability:** every section maps to Section 17's matrix; no requirement lacks a source anchor or an explicit "new in this document" flag.
- **Guardian compliance:** no new module, workflow, actor, API endpoint, database table, business rule, or permission was introduced. Localization (Section 11) is the one genuinely new topic, and it is scoped to a goal statement with implementation explicitly deferred, not specified as a built feature.

---

**End of 09_Non_Functional_Requirements.md — Approved. Frozen (v1.0).** No further modifications are permitted unless required by an approved scope change, a documented architecture issue, a security issue, or a contradiction with another approved document (Project Guardian rule, consistent with 01–08).
