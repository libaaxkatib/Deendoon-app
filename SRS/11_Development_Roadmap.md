# 11. Development Roadmap

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-11 |
| **Document Title** | Development Roadmap |
| **Version** | 1.0 |
| **Status** | Draft — Pending Review |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Pending |
| **Last Updated** | 2026-07-24 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened v1.3) · `02_Business_Requirements.md` (Reopened v1.3) · `03_Functional_Requirements.md` (v1.7 — **Module 12 still awaiting its original approval, carried forward as an open item below**) · `04_Business_Rules.md` (Reopened v1.3) · `05_UI_UX_Specification.md` (Approved & Frozen, v1.1) · `06_Database_Design.md` (Approved & Frozen, v1.3, PostgreSQL) · `07_API_Design.md` (Approved & Frozen, v1.1) · `08_Security_and_RBAC.md` (Approved & Frozen, v1.1) · `09_Non_Functional_Requirements.md` (Approved & Frozen, v1.0) · `10_Acceptance_Criteria.md` (Approved & Frozen, v1.0) |
| **Technology Stack** | Laravel 13 · PostgreSQL · Redis · REST API · Laravel Sanctum (Bearer Token mode) · React + TypeScript (Super Admin Web Dashboard) · Flutter (Customer Mobile App) · S3-compatible Object Storage |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft. Sequences implementation of the 12 approved Functional Modules (`03`) into 14 phases, grounded exclusively in `01`–`10`. Introduces no new modules, APIs, workflows, permissions, tables, or business rules. | Claude |

---

## 1. Document Purpose

This document defines the **recommended implementation sequence** for building Deendoon Version 1, based exclusively on the ten already-approved SRS documents (`01`–`10`).

It is a **sequencing and readiness document, not a requirements document.** It does not redefine, reinterpret, or extend any Business Requirement, Functional Requirement, Business Rule, UI/UX specification, data model, API contract, security control, non-functional target, or acceptance criterion. Every phase below exists to organize *when* already-approved work happens — never *what* that work is.

**Boundary note:** this document's Deployment Readiness and Production Readiness checklists (Sections 7–8) describe completion **gates** — states that must be true before deploying or launching. They do not describe infrastructure architecture (environments, network topology, scaling topology, secrets management design). Per the Guardian decision already recorded when "Deployment Architecture" was last discussed, infrastructure architecture — if produced — remains a separate document outside the approved 11-document SRS numbering, not a section of this roadmap.

---

## 2. Roadmap Objectives

- Provide a **recommended, dependency-aware implementation order** for the 12 Functional Modules approved in `03_Functional_Requirements.md`, plus the cross-cutting non-functional, security, and readiness work approved in `06`–`09`.
- Give every phase clear, checkable **exit criteria** tied directly to `10_Acceptance_Criteria.md`, so "done" is never a subjective judgment.
- Surface genuine **implementation-sequencing dependencies** between modules (for example, where one module's business logic is triggered by events emitted from a module built in a later phase) so they are handled deliberately rather than discovered mid-build.
- **This roadmap does not redefine business requirements.** It assumes `02`'s Business Requirements, `03`'s Functional Requirements, and `04`'s Business Rules are correct and complete as approved, and organizes only the order in which approved work is built, tested, and shipped.

---

## 3. Development Principles

| Principle | Meaning |
|---|---|
| **Build from approved SRS only** | No feature, field, endpoint, table, role, or workflow is implemented unless it is traceable to an approved statement in `01`–`10`. If a developer believes something is missing, the correct action is to raise it for a documented SRS change — not to build it ad hoc. |
| **Maintain traceability** | Every implemented unit of work maps to a specific FR (`03`), BRL (`04`), SCR (`05`), table (`06`), endpoint (`07`), role/permission (`08`), or NFR target (`09`) — and to its corresponding AC (`10`). |
| **Small incremental milestones** | Each phase is built and merged in small, independently testable increments rather than large batched changes — consistent with the phase Exit Criteria in Section 5, which are written at a granularity small enough to verify continuously, not only at phase end. |
| **Test before merge** | No code merges without its corresponding Acceptance Criteria (`10`) passing. A phase is never marked complete based on code being written — only on its ACs passing. |
| **Documentation-first changes** | If implementation reveals that an approved document is wrong, ambiguous, or incomplete, the document is corrected and re-approved (via the same Guardian reopening process used throughout `01`–`10`) **before** the code is written — never the reverse. |
| **No undocumented features** | Anything not specified in `01`–`10` (a convenience field, an extra button, an internal admin toggle, a "just in case" API parameter) is out of scope, regardless of how small it seems. |

---

## 4. Recommended Development Phases

| Phase | Name | Primary Modules / Scope |
|---|---|---|
| 1 | Project Setup | Environment, tooling, base architecture (no business modules) |
| 2 | Authentication & RBAC | Module 1 (FR-001–006) + `08` roles/permissions |
| 3 | Customer Management | Module 2 (FR-007–016) |
| 4 | Debt Register | Module 3 (FR-017–025) |
| 5 | Credit & Risk | Module 4 (FR-026–028) |
| 6 | Recovery Workflow | Module 5 (FR-029–033) |
| 7 | Payments | Module 6 (FR-034–039) |
| 8 | Professional Collection | Module 7 (FR-040–046, FR-072–076) |
| 9 | Documents | Module 8 (FR-047–052) |
| 10 | Reporting | Module 9 (FR-053–057) |
| 11 | Notifications & Calendar | Module 10 (FR-058–062) |
| 12 | Administration | Module 12 (FR-066–071) **+ Module 11 consolidation (see note below)** |
| 13 | Performance Optimization | Cross-cutting, tied to `09` targets |
| 14 | Production Readiness | Cross-cutting, Sections 7–8 of this document |

No module beyond the 12 approved in `03` appears anywhere in this table. No phase introduces a workflow, actor, or capability absent from `01`–`10`.

**Guardian note — Module 11 placement:** the phase list above follows the order given, which does not include a standalone phase for Module 11 (Search & Productivity, FR-063–065). This was not silently dropped. FR-063 (Global Search) inherently spans Customers, Debts, Payments, Documents, and Collection Cases; FR-064 (Advanced Filtering) is the same filter architecture applied independently within each module's own list view; FR-065 (Quick Actions) are navigation shortcuts into workflows that must already exist. All three are therefore **cross-cutting by nature** — each module implements its own contribution as it is built (e.g., Phase 3 ships Customer filtering, Phase 4 ships Debt filtering), and Phase 12 is where they are consolidated and verified end-to-end (global cross-entity search, consistent filter behavior, and Quick Action coverage across all completed modules). This is noted explicitly here, in Phase 12's deliverables (Section 5), and in the Final Traceability Summary (Section 12), so FR-063–065 remain fully traceable without adding an unrequested fifteenth phase.

**Guardian note — cross-module event wiring:** several modules define logic that is *triggered by* events emitted from a module built in a later phase — most notably Credit Score recalculation (FR-026, Phase 5) is triggered in part by Payment events (Phase 7) and Broken Promise events (Phase 6), and Recovery Stage automation (FR-032, Phase 6) is triggered in part by Payment events (Phase 7) and Collection escalation (Phase 8). This is normal incremental build sequencing, not a contradiction: each phase builds its own module's data model, business logic, and self-contained triggers; wiring in a later-built module's producer events is called out explicitly as a dependency in the consuming phase's Exit Criteria (Section 5) and confirmed only once the producing phase exists.

---

## 5. Phase Deliverables

### Phase 1 — Project Setup
- **Goals:** Laravel 13 application scaffold; PostgreSQL and Redis provisioned for development; Sanctum installed (Bearer Token mode, per `07` §2); base multi-tenant `tenant_id` scoping scaffolding (per `06`); base React + TypeScript project (Super Admin Web Dashboard); base Flutter project (Customer Mobile App); S3-compatible object storage configuration scaffold (per `06`/`09`, vendor-neutral); CI pipeline skeleton (build + test on push).
- **Dependencies:** None — first phase.
- **Exit Criteria:** Both client applications build and run against a local backend; a single authenticated round-trip (health-check style) succeeds through Sanctum end-to-end; no business endpoint, table, or screen beyond scaffolding exists yet.

### Phase 2 — Authentication & RBAC
- **Goals:** Implement FR-001–006 (Login, Logout, Session Expiry, Password Reset, Change Password, Role/Permission Resolution); implement the 7 approved roles and their capability matrix (`08` §5); Argon2id password hashing as sole default (`08` §10); tenant isolation enforcement (`06`/`07`/`08`) from this phase forward.
- **Dependencies:** Phase 1. Resolves the Sanctum-token-to-`sessions`-table mapping left as an implementation mapping in `07` §2 — this must be finalized here, not deferred further, since every later phase depends on it.
- **Exit Criteria:** AC-001-1 through AC-006-3 (`10` §2) pass; AC-GLOBAL-AUTH, AC-GLOBAL-RBAC, and AC-GLOBAL-TENANT (`10` §1) pass against this module and remain part of the regression suite for every subsequent phase.

### Phase 3 — Customer Management
- **Goals:** Implement FR-007–016 (Creation, Details, Update, Archive, Restore, Status Management, Credit Profile, Duplicate Detection, Search, Import); ship this module's contribution to FR-064 (Advanced Filtering) and FR-063 (Global Search — Customer entity type).
- **Dependencies:** Phase 2 (every Customer endpoint is role-gated and tenant-scoped).
- **Exit Criteria:** AC-007-1 through AC-016-4 (`10` §3) pass.

### Phase 4 — Debt Register
- **Goals:** Implement FR-017–025 (Creation, Credit Limit Soft Warning, Details, Update, Status Tracking, Archive, Restore, Recovery Timeline display, Recovery Stage display/override); ship this module's contribution to FR-064/FR-063.
- **Dependencies:** Phase 3 (Debts reference Customers).
- **Exit Criteria:** AC-017-1 through AC-025-4 (`10` §4) pass.

### Phase 5 — Credit & Risk
- **Goals:** Implement FR-026–028 (Credit Score calculation engine, Risk Level assignment, Credit Limit Reached notification trigger). The scoring engine and its aging-based trigger (from Debt data, already available) are built and testable in this phase; its Payment-behavior and Broken-Promise triggers are wired in once Phases 6 and 7 exist (see cross-module event wiring note, Section 4).
- **Dependencies:** Phase 4 (aging-based scoring trigger requires Debt data). **Forward dependency:** full trigger coverage is not complete until Phases 6–7 land; this is tracked explicitly, not silently assumed done.
- **Exit Criteria (Phase 5 scope only):** AC-026-1 (constrained to the invariant already defined pending DD-009 — see `10` §15), AC-026-2, AC-027-1, AC-027-2, AC-028-1 pass using the triggers available at this point. A follow-up verification is required after Phase 6 and Phase 7 to confirm the remaining triggers are wired (tracked in those phases' Exit Criteria).

### Phase 6 — Recovery Workflow
- **Goals:** Implement FR-029–033 (Automated Reminder Scheduling, Manual Reminder, Promise to Pay, Recovery Stage automation engine, Follow-up History); wire the Broken-Promise trigger into the Phase 5 Credit Score engine.
- **Dependencies:** Phase 4 (Debts must exist to remind against); Phase 5 (Credit Score engine must exist to receive the Broken-Promise trigger).
- **Exit Criteria:** AC-029-1 through AC-033-1 (`10` §6) pass; the Broken-Promise → Credit Score wiring is confirmed (extends AC-026-1's coverage).

### Phase 7 — Payments
- **Goals:** Implement FR-034–039 (Payment Recording, History, Balance Recalculation, Debt Status Update via Payment, Receipt Generation Trigger, Downstream Event Emission); wire the Payment-behavior trigger into the Phase 5 Credit Score engine and the Payment/Promise-fulfillment trigger into the Phase 6 Recovery Stage engine.
- **Dependencies:** Phase 4 (Payments apply against Debts); Phase 5 and Phase 6 (both receive Payment-originated events).
- **Exit Criteria:** AC-034-1 through AC-039-3 (`10` §7) pass; the Payment → Credit Score and Payment → Recovery Stage / Promise Fulfillment wiring is confirmed, completing Phase 5's and Phase 6's deferred trigger coverage.

### Phase 8 — Professional Collection
- **Goals:** Implement FR-040–046 (Collection Case creation, assignment, details, update, activity, closure, history) and FR-072–076 (Professional Collection Request submission, status tracking, list/history, conversation, outcome/closure); enforce that only the Deendoon Platform Administrator role can perform Request status transitions (`08` least-privilege boundary, AC-073-3).
- **Dependencies:** Phase 6 (escalation triggers at Recovery Stage 5); Phase 7 (Collection Activity may reflect Payment events); Phase 2 (Deendoon Platform Administrator role and cross-tenant access model).
- **Exit Criteria:** AC-040-1 through AC-046-1 and AC-072-1 through AC-076-2 (`10` §8) pass.

### Phase 9 — Documents
- **Goals:** Implement FR-047–052 (Digital Receipt generation, Demand Letter generation, Customer Statement of Account, Document Viewing, Downloading, History).
- **Dependencies:** Phase 7 (Receipts are generated only as a consequence of Payment, FR-038); Phase 4 and Phase 6 (Demand Letters reference Debt and Recovery Stage data); Phase 3 (Statements reference Customer data). Document branding fields (Company Profile) are not finalized until Phase 12 — documents are functionally complete in this phase using placeholder/default branding, with final branding wired in during Phase 12 (see that phase's dependencies).
- **Exit Criteria:** AC-047-1 through AC-052-1 (`10` §9) pass.

### Phase 10 — Reporting
- **Goals:** Implement FR-053–057 (Dashboard Summary, Aging Analysis, Standard Operational Reports, Report Filtering, Report Export).
- **Dependencies:** Phases 3–9 (reports aggregate Customer, Debt, Credit, Recovery, Payment, Collection, and Document data — this phase is necessarily late-stage).
- **Exit Criteria:** AC-053-1 through AC-057-2 (`10` §10) pass.

### Phase 11 — Notifications & Calendar
- **Goals:** Implement FR-058–062 (in-app Notification delivery, Read/Unread and Mark All as Read, Filter by Type, History, Calendar View). The underlying notification data model and delivery mechanism (`06`) should already exist from Phase 2 onward so that Phases 4–10's qualifying events (Credit Limit Reached, Payment Received, Document Available, Collection Assignment, Reminder Sent, Promise Due, Professional Collection Request Update) have somewhere to emit into; this phase delivers the consumer-facing Notification Center and Calendar itself, plus verification that every qualifying event from every prior phase is correctly emitting.
- **Dependencies:** Phases 4–10 (every notification-emitting event source).
- **Exit Criteria:** AC-058-1 through AC-062-2 (`10` §11) pass; AC-058-2 (no client-initiated creation endpoint exists) is verified against the full, completed API surface.

### Phase 12 — Administration
- **Goals:** Implement FR-066–071 (User Administration, Role & Permission Management, Company Profile & Branding, System Preferences, Lookup & Reference Data, Audit Trail Viewing); wire finalized Company Profile branding into the Phase 9 Document templates; consolidate and verify Module 11 (Search & Productivity, FR-063–065) end-to-end across every module completed in Phases 3–11, per the Guardian note in Section 4.
- **Dependencies:** All prior functional phases (Administration configures values consumed throughout; Search consolidates across all entity types; Audit Trail reviews events logged since Phase 2).
- **Guardian flag — carried forward from `03`/`06`/`07`/`08`/`09`/`10`:** Module 12 (FR-066–071) was drafted in `03_Functional_Requirements.md` but has not yet received the same explicit standalone approval message given to Modules 1–11. **Phase 12 development must not begin against FR-066–071 until that approval is explicitly given.** This is a process gate, not a rewrite of the requirements themselves — the drafted FRs are used as-is once approved.
- **Exit Criteria:** Module 12 explicit approval obtained; AC-066-1 through AC-071-3 (`10` §13) pass; AC-063-1 through AC-065-1 (`10` §12) pass against the fully assembled system; Phase 9's Documents render with final Company Profile branding.

### Phase 13 — Performance Optimization
- **Goals:** Validate and tune the system against the design targets set in `09` §Performance/§Scalability/§Capacity Planning (e.g., p95 <300ms for simple operations, <1s for list operations, 2–3s for aggregation/reporting operations); verify the indexing strategy defined in `06` §Performance & Index Strategy is actually applied; verify pagination/filtering/sorting behavior (`07`) performs correctly at representative data volumes; Redis caching tuned where `09`/`06` call for it; eliminate N+1 query patterns.
- **Dependencies:** Phases 1–12 (a feature-complete system is required to measure realistic performance).
- **Exit Criteria:** The design targets stated in `09` are met against representative data volumes; no new performance target is introduced beyond what `09` already states — a target not in `09` is out of scope for this phase.

### Phase 14 — Production Readiness
- **Goals:** Execute the Deployment Readiness Checklist (Section 7) and Production Readiness Checklist (Section 8) in full.
- **Dependencies:** All prior phases complete.
- **Exit Criteria:** Every item in Sections 7 and 8 is satisfied.

---

## 6. Testing Strategy by Phase

Every phase in Section 5 is subject to the same testing discipline; only the surface under test changes.

| Test Type | What it validates | When it runs |
|---|---|---|
| **Unit tests** | Individual business-logic units (e.g., Credit Score calculation, Recovery Stage transition rules, validation rules from `04`) behave correctly in isolation. | Continuously, within each phase, before any merge. |
| **Integration tests** | Cross-module wiring — especially the event-producer/consumer relationships called out in Section 4/5 (Payment → Credit Score, Broken Promise → Credit Score, Payment → Recovery Stage, escalation → Collection Case, every module → Notification Center). | At the end of each phase that completes a wiring dependency (explicitly Phases 5–8 and 11, per their Exit Criteria above). |
| **API tests** | Every endpoint in `07_API_Design.md` matches its documented request/response contract, validation rules (`07` §7), and authorization behavior (AC-GLOBAL-AUTH, AC-GLOBAL-RBAC, AC-GLOBAL-TENANT). | Per phase, against that phase's endpoint set; full regression run in Phase 13–14. |
| **End-to-end tests** | A complete user journey through the Customer Mobile App or Super Admin Web Panel (per the flows in `05_UI_UX_Specification.md`) behaves correctly from UI action through to persisted state and generated documents/notifications. | Per phase for that phase's own journeys; full cross-phase journeys (e.g., Debt creation → Payment → Receipt → Notification) once the relevant phases are complete. |
| **Acceptance Criteria verification** | The canonical pass/fail gate. Every phase's Exit Criteria in Section 5 is expressed as a set of Acceptance Criteria IDs from `10_Acceptance_Criteria.md`. A phase is not complete until 100% of its listed AC IDs pass. | Required before any phase is marked complete (Development Principle: "Test before merge"). |

---

## 7. Deployment Readiness Checklist

What must be true before a build can be deployed to any shared environment beyond a developer's own machine:

- [ ] All 14 phases' Exit Criteria (Section 5) are satisfied, **or** the deployment is an explicitly scoped partial release with the un-met phases documented as known gaps.
- [ ] Database migrations apply cleanly against a PostgreSQL instance matching `06`'s approved schema, with no manual post-migration data-fixing steps required.
- [ ] The full Acceptance Criteria suite (`10`, all sections) passes in an automated CI run — not only spot-checked manually.
- [ ] Both client applications (React + TypeScript Super Admin Web Panel, Flutter Customer Mobile App) build successfully from a clean checkout.
- [ ] Environment configuration (Sanctum settings, Redis connection, S3-compatible storage credentials, database connection) is externalized — no hard-coded environment-specific values in source.
- [ ] No endpoint, table, screen, role, or business rule exists in the build that is not traceable to `01`–`10` (Development Principle: "Build from approved SRS only").

---

## 8. Production Readiness Checklist

What must be true before the system is opened to real tenant users, beyond deployment readiness (Section 7):

- [ ] **Security review** — the system is verified against `08_Security_and_RBAC.md` in full: the 7-role capability matrix, Argon2id password hashing, tenant isolation (AC-GLOBAL-TENANT) under adversarial testing (attempted cross-tenant access), and the OWASP Top 10 / ASVS mapping recorded in `08`'s Internal Architecture Review. The Row-Level Security recommendation from `06` has an explicit Product Owner decision on record (adopted or consciously not adopted) — it is not left silently unresolved into production.
- [ ] **Performance review** — Phase 13's results confirm the design targets in `09` §Performance/§Scalability are met; no unresolved performance regression is open.
- [ ] **Backup verification** — a backup is not only configured but has been **restored at least once** in a non-production environment, confirming recoverability per `09` §Backup & DR and BR-033, before being relied upon.
- [ ] **Monitoring verification** — the observability approach from `09` §Observability is live and confirmed to surface a real failure (a deliberate test failure/alert), not merely configured and unverified.
- [ ] **Acceptance Criteria completion** — 100% of `10_Acceptance_Criteria.md`'s criteria pass, including every criterion previously marked "Pending DD" in `10` §15 (Section 15) that blocks a specific FR from being demonstrably correct — each is either resolved and passing, or the affected FR is explicitly excluded from this release with the gap documented.
- [ ] Every item in Section 7 (Deployment Readiness) remains true at the moment of production launch, not only at an earlier deployment.

---

## 9. Risks & Mitigation

Implementation risks only — no business, market, or product risk is introduced here; those remain the domain of `02_Business_Requirements.md`.

| Risk | Impact | Mitigation |
|---|---|---|
| Module 12 (FR-066–071) has not received its own explicit approval message, unlike Modules 1–11. | Building Phase 12 against unapproved requirements risks rework if the module is later amended. | Treat Module 12 approval as a hard gate before Phase 12 begins (stated explicitly in that phase's Exit Criteria, Section 5). |
| Several Business Rule Deferred Decisions remain open (`04` DD register; `10` §15 lists DD-009, DD-011, DD-023 specifically as blocking full AC resolution). | Logic built against an assumed answer to an unresolved DD may need rework once the Product Owner decides it. | Resolve DD-009 before Phase 5 needs concrete score thresholds; resolve DD-011 before Phase 5's notification-repeat behavior is finalized; resolve DD-023 before Phase 8's duplicate-escalation handling is finalized. Do not guess an answer in code where `10` §15 already flags the criterion as pending. |
| PostgreSQL Row-Level Security remains a recommendation in `06`, not an adopted architecture. | If application-layer tenant scoping (`tenant_id` filtering in every query) has even one missed instance, cross-tenant data exposure is possible without RLS as a second enforcement layer. | Obtain an explicit Product Owner decision on RLS adoption before Phase 3 (the first tenant-scoped functional module) begins; if RLS is not adopted, document the compensating control (mandatory code-review checklist item for tenant scoping on every query). |
| The MySQL → PostgreSQL migration in `06` was a full rewrite of every table's types; an implementer unfamiliar with that history could reintroduce a MySQL-specific assumption (unsigned integers, `ENUM`, `TIMESTAMP` without time zone) by habit. | Reintroducing a corrected type mismatch reopens a defect that was already fixed on paper. | Add "PostgreSQL-native types only" as an explicit code-review checklist item from Phase 1 onward. |
| Cross-module event wiring (Section 4/5: Credit Score, Recovery Stage, Notifications) is built incrementally across multiple phases. | A consumer engine could be marked "done" in an earlier phase while a later phase's producer event is never actually wired in, silently leaving a gap. | Each affected phase's Exit Criteria (Section 5) explicitly requires confirming the specific wiring, not just that the consumer engine exists in isolation. |
| The exact mapping between Laravel Sanctum's token storage and `06`'s `sessions` table was left as an implementation mapping in `07` §2. | An ambiguous or undocumented resolution could create an inconsistency between the approved data model and actual token-storage behavior. | Resolve and document this mapping explicitly during Phase 2, before Authentication is considered complete. |
| Document branding (Company Profile, Module 12/Phase 12) lands after Document generation (Module 8/Phase 9). | Documents generated between Phase 9 and Phase 12 use placeholder branding, which could be mistaken for final output if not clearly flagged. | Phase 9's Exit Criteria explicitly notes documents are functionally, not visually, final until Phase 12 rewires branding. |

---

## 10. Documentation Maintenance

- If implementation reveals that an approved document (`01`–`10`) is incomplete, ambiguous, or incorrect, the fix is made to the **document first**, using the same Guardian reopening process applied throughout this project (explicit scope description, review, correction, re-approval, re-freeze) — never patched silently in code while the document falls out of date.
- `10_Acceptance_Criteria.md` is updated only as a direct consequence of a change to the FR it traces to — never edited independently to match whatever was actually built.
- Resolution of an open Deferred Decision (`04`'s DD register, or the "Decisions Required"/"Deferred ... Decisions" items in `06`/`07`/`08`/`09`) is recorded by reopening the specific document that carries it, exactly as has been done for every prior reopening in this project (e.g., `06`'s RLS refinement). An informal engineering note or code comment is not a substitute for updating the governing document.
- This document (`11`) is re-approved the same way if the recommended phase order itself needs to change — for example, if a future Product Owner decision changes a dependency described in Section 5.

---

## 11. Future Enhancements (Out of Scope)

This roadmap sequences Version 1 only. It does not define a Version 2 feature set — any such definition would require a new product-scoping exercise outside this SRS, following the same process used to scope Version 1. The items below are not new ideas; each is already recorded as deferred in an approved document, restated here only for visibility:

| Item | Source | Status |
|---|---|---|
| Multi-Factor Authentication (MFA) | `08_Security_and_RBAC.md` §16 | Flagged as a future consideration only — not V1 scope. |
| Admin-initiated password reset for locked-out users | `08_Security_and_RBAC.md` §16 | Flagged as an unconfirmed extension to FR-066 — not approved V1 scope; would require explicit approval before being added to any phase. |
| PostgreSQL Row-Level Security as adopted (not merely recommended) architecture | `06_Database_Design.md` §Decisions Required | Pending explicit Product Owner decision (also tracked as a Section 9 risk above). |
| Backup schedule, monitoring platform, alert channels, infrastructure sizing, CDN, storage provider, RPO/RTO figures, support SLA tiers, CI/CD tooling | `09_Non_Functional_Requirements.md` §18 (Deferred Operational Decisions) | Operational/infrastructure configuration choices deferred until deployment planning — not functional features. |
| Localization mechanism (English/Somali) | `09_Non_Functional_Requirements.md` §Localization / §18 | Goal-level only; no database or UI mechanism has been specified or approved. |
| Compliance certification framework (e.g., formal SOC 2 / ISO 27001-style certification) | `09_Non_Functional_Requirements.md` §Compliance | No certification is claimed for V1; framework choice deferred. |
| Deployment/Infrastructure Architecture as a standalone document | Prior Guardian decision (this conversation) | Deferred indefinitely; if produced, it will be a separate document outside the approved 11-document SRS numbering — not a replacement or renumbering of any document in `01`–`11`. |

---

## 12. Final Traceability Summary

| Document | Role | Relationship to this Roadmap |
|---|---|---|
| `01_Project_Overview.md` | Defines scope, actors, and the 11-document SRS structure itself. | This roadmap's 12-module phase mapping (Section 4) is scoped exactly to `01`'s approved Target Users and Scope of Version 1 — no actor or capability beyond it appears in any phase. |
| `02_Business_Requirements.md` | Business Actors, Goals, Processes, Requirements, Constraints, Success Metrics. | This roadmap sequences delivery of `02`'s approved requirements; it does not restate or reinterpret them. |
| `03_Functional_Requirements.md` | FR-001–FR-076 across 12 modules. | Directly maps 1:1 to the 12 modules distributed across Phases 2–12 (Section 4/5). |
| `04_Business_Rules.md` | BRL, DD, State Transition, Calculation, and Validation rules. | Referenced wherever a phase's business logic depends on a specific rule (e.g., Recovery Stage transitions, Credit Score triggers); open DDs are carried into Section 9 (Risks) rather than assumed. |
| `05_UI_UX_Specification.md` | 49 approved screens (SCR-001–SCR-049). | Each phase's functional delivery implies delivery of that module's corresponding screens; no phase implies a screen not already in `05`. |
| `06_Database_Design.md` | 22 approved PostgreSQL tables. | Phase 1 scaffolds the schema; each phase's Exit Criteria assumes only tables already defined here — no phase introduces a new table. |
| `07_API_Design.md` | ~65 approved endpoints. | Each phase's Exit Criteria assumes only endpoints already defined here — no phase introduces a new endpoint. |
| `08_Security_and_RBAC.md` | 7 roles, permission matrix, security controls. | Phase 2 implements this document's foundation; Phase 14's Production Readiness checklist verifies it holds under the completed system. |
| `09_Non_Functional_Requirements.md` | Quality attribute targets (performance, scalability, availability, etc.). | Phase 13 exists specifically to verify the completed system against these targets — no new target is introduced beyond what `09` states. |
| `10_Acceptance_Criteria.md` | Testable pass/fail criteria for all 76 FRs. | Supplies every phase's Exit Criteria (Section 5) and the Production Readiness gate (Section 8) — this roadmap does not define its own separate notion of "done." |
| `11_Development_Roadmap.md` (this document) | Implementation sequencing only. | Introduces no new module, API, workflow, permission, table, or business rule. |

### Guardian Compliance & Internal Review Confirmation

Before presenting this document, the following consistency checks were performed and corrected where needed:

- **Cross-document consistency:** every phase's scope statement was checked against its corresponding FR range in `03`; no phase references a module, actor, or capability absent from `01`–`10`.
- **Phase ordering:** the requested 14-phase order (Section 4) is preserved exactly as given. Three genuine forward-dependencies were identified — Credit Score (Phase 5) on Payment/Broken-Promise events (Phases 6–7), Recovery Stage (Phase 6) on Payment/Collection events (Phases 7–8), and Notifications (Phase 11) on nearly every prior phase's events — and were resolved by documenting incremental build-then-wire sequencing in each affected phase's Dependencies and Exit Criteria (Section 5), rather than by reordering the requested phase list.
- **Module 11 coverage:** the requested phase list has no standalone slot for Module 11 (Search & Productivity). Rather than silently omit FR-063–065 from the roadmap or unilaterally add an unrequested fifteenth phase, they are explicitly assigned as incremental per-module deliverables consolidated in Phase 12, documented in Section 4's Guardian note and Phase 12's deliverables.
- **Module 12 approval gap:** carried forward, as in `06`–`10`, as an explicit gate on Phase 12 (Section 5) and as a named risk (Section 9) — not silently resolved in either direction.
- **Technology consistency:** every phase references only the approved stack (Laravel 13, PostgreSQL, Redis, REST API, Laravel Sanctum Bearer Token mode, React + TypeScript, Flutter, S3-compatible storage); no phase assumes MySQL, Passport, JWT, or any tool not named in `06`–`09`.
- **Traceability:** every one of the 76 FRs in `03` appears in exactly one phase's Exit Criteria via its `10` Acceptance Criteria IDs; none are duplicated across phases, none are missing.
- **Deployment Architecture boundary:** confirmed Sections 7–8 describe readiness gates only, consistent with the standing decision that infrastructure architecture, if ever produced, remains a separate, non-SRS-numbered document.

---

**End of 11_Development_Roadmap.md — Awaiting Enterprise Architecture Review.**
