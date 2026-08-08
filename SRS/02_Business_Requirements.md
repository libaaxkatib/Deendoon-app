# 02. Business Requirements

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-02 |
| **Document Title** | Business Requirements |
| **Version** | 1.7 |
| **Status** | Reopened — Pending Re-Approval |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Pending |
| **Last Updated** | 2026-08-08 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened — Pending Re-Approval, v1.5) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: Business Actors, Goals, Processes, Requirements, Constraints, Success Metrics, high-level Business Rules, and Traceability Matrix | Claude |
| 1.1 | 2026-07-24 | Documentation polish pass: clarified BR-011 (configurable reminder timing), BR-018 (full/partial payments), BR-024 (historical KPI periods), BR-030 (immutable audit records), BR-035 (branding elements); added SM-007 and SM-008. No scope or functionality changes. Approved by Product Owner — frozen as the official Business Requirements baseline. | Claude |
| 1.2 | 2026-07-24 | **Reopened — intentional scope change.** Added Professional Collection Requests (hand-off to Deendoon's own recovery team): new Business Actor (BA-009), new Business Process (BP-011), new Business Requirements (BR-039–BR-042), new Business Constraint (BC-009), new Success Metric (SM-009), new high-level Business Rule (BRL-077), and corresponding Traceability Matrix entries. No previously approved requirement was altered. | Claude |
| 1.3 | 2026-07-24 | **Correction to 1.2.** Removed BA-009 (the invented "Deendoon Recovery Specialist" actor). Version 1 has exactly two application interfaces and no additional internal roles. BA-008 (Deendoon Platform Administrator / Super Admin) is now the sole actor for Professional Collection Requests, clarified as operating at the true platform level. Updated BP-011 and BR-042 wording accordingly (removed "assign," since there is no team to assign among — the Super Admin actions Requests directly). Traceability Matrix references to BA-009 removed. | Claude |
| 1.4 | 2026-07-31 | **RBAC Architecture Amendment (Product Owner Decision), applying the same principle 1.3 already established for BA-009 to BA-002/004/005/006.** Removed BA-002 (Operations Manager), BA-004 (Finance Staff), BA-005 (Support Staff), and BA-006 (Viewer) — Version 1 has exactly two application interfaces and no internal staff-role differentiation beyond the single Business Owner account per tenant; these four actors described distinct staff tiers that were never given a distinct interface to operate. Redefined BA-003 (Collection Officer) as Deendoon's own internal operational function (Platform Administrator staff, exercised after a Professional Collection Request is accepted), not a tenant-side actor. BA-001, BA-007, BA-008 unchanged. BR-029's role list updated to match; see `08_Security_and_RBAC.md` v1.2 for the corresponding RBAC table amendment. | Claude |
| 1.5 | 2026-07-31 | **Scope Baseline metadata correction (Product Vision Amendment ripple).** Updated the Scope Baseline field to cite `01` at its current version (v1.4). No business requirement changed. | Claude |
| 1.6 | 2026-07-31 | **Product Vision Amendment (Product Owner Decision) — obsolete multi-staff assumptions removed, not deferred.** BG-006, BP-007 (renamed from "Staff Access Governance" to "Access Governance"), BR-028, BR-029, and BR-030's rationale rewritten as current Version 1 requirements reflecting the approved two-account architecture (Business Owner, tenant-side; Deendoon Platform Administrator, platform-side) — no internal staff tiers, no role assignment, no multi-user tenant. Each item's original intent (data-access protection, role-appropriate access, accountability) is preserved, only re-grounded in the actual two accounts that exist rather than a retired multi-staff model. IDs, traceability (`Traces To` columns), and structure unchanged. No workflow, API, database design, or business logic changed beyond this. Scope Baseline updated to cite `01` at v1.5. | Claude |
| 1.7 | 2026-08-08 | **SRS Final Alignment (Product Owner Decision): current implemented app + backend are the final product.** BR-022 retitled and narrowed from "attach supporting notes and documents ... Notes & Attachments; Document Scanner" to "attach supporting free-text notes to a debt or collection case ... Notes" — the implemented backend provides a real `notes` field on Debt and Collection Case; "Document Scanner" (camera/OCR capture) and arbitrary document attachment were never implemented and are not part of the final product. Traceability Matrix's BR-022 row updated to match. This corrects a discrepancy where this document still described unimplemented, never-built capabilities as part of an approved requirement whose other half (Notes) is genuinely implemented. | Claude |

---

## 2.1 Purpose of This Document

This document defines **what** Deendoon Version 1 must achieve from a business perspective, and **why** — independent of how the system implements it. It does not describe screens, workflows, data structures, or system behavior; those are specified in `03_Functional_Requirements.md` onward.

Every requirement in this document traces back to the approved scope in `01_Project_Overview.md` (Section 1.6, Scope of Version 1) and, transitively, to the approved Version 1 Feature Freeze. No requirement in this document introduces functionality beyond that baseline.

Each requirement carries a unique identifier for traceability through the remaining SRS documents.

---

## 2.2 Business Actors

| ID | Actor | Description | Baseline Reference |
|---|---|---|---|
| BA-001 | Business Owner / SME Operator | The single account per tenant on the Customer Mobile App; owns the Deendoon tenant; manages customers, debts, and recovery activity. | 01 §1.5 |
| BA-003 | Collection Officer | **Amended v1.4:** an internal Deendoon operational function, not a tenant actor — work performed by Platform Administrator staff (BA-008) on an accepted Professional Collection Request. Not a distinct login account. | 01 §1.5 |
| BA-007 | Customer (Debtor) | External actor; owes money to the business; receives reminders and documents. Does not use the Customer Mobile App. | 01 §1.5 |
| BA-008 | Deendoon Platform Administrator (Super Admin) | Operates the Super Admin Web Panel at the true platform level, across the whole Deendoon platform. Also reviews and actions Professional Collection Requests submitted by any tenant. The only Deendoon-side actor in Version 1 — no additional roles, staff groups, or interfaces exist. | 01 §1.5 |

**Retired v1.4 (RBAC Architecture Amendment):** BA-002 (Operations Manager), BA-004 (Finance Staff), BA-005 (Support Staff), BA-006 (Viewer) — Version 1 has no tenant-side staff-role differentiation beyond the single Business Owner (BA-001) account; these described distinct capability tiers that were never given a distinct interface to operate, and are not modeled as separate login accounts.

---

## 2.3 Business Goals

| ID | Goal | Baseline Reference |
|---|---|---|
| BG-001 | Increase the proportion of extended credit that is successfully recovered. | 01 §1.4 |
| BG-002 | Reduce the average time between a debt becoming overdue and being recovered. | 01 §1.4 |
| BG-003 | Reduce the business's exposure to customers who are unlikely to pay. | 01 §1.4 |
| BG-004 | Give the business formal, credible tools to escalate and document collection activity. | 01 §1.4 |
| BG-005 | Give business owners and managers real-time insight into receivables, risk, and recovery performance. | 01 §1.4 |
| BG-006 | Maintain data control and accountability for all recovery operations through a single, auditable Business Owner account per tenant, kept strictly separate from Deendoon's own platform administration. | 01 §1.4 |
| BG-007 | Ensure financial records remain accurate, traceable, and never irrecoverably lost. | 01 §1.4 |
| BG-008 | Support Deendoon's operation and growth as a scalable, commercial multi-tenant SaaS product. | 01 §1.4 |

---

## 2.4 Business Processes

High-level business processes that Version 1 must support. These describe *what happens* in the business, not system behavior.

| ID | Process | Description |
|---|---|---|
| BP-001 | Credit Extension & Risk Assessment | Assessing a customer's risk and creditworthiness before or at the point of extending further credit. |
| BP-002 | Debt Lifecycle Management | Tracking a debt's financial state and recovery progress as distinct, observable states from creation to resolution. |
| BP-003 | Automated & Manual Follow-Up | Pursuing repayment through a combination of automated and manual communication, escalating as needed. |
| BP-004 | Formal Escalation & Documentation | Moving unresolved debts into a formal, documented collection process when informal follow-up fails. |
| BP-005 | Payment Recording & Proof | Recording every payment received and providing verifiable proof to both business and customer. |
| BP-006 | Business Oversight & Reporting | Monitoring overall receivables health and recovery performance. |
| BP-007 | Access Governance | Controlling access to financial data through the two approved account types — full tenant-side access for the Business Owner, platform-level administration exclusively for the Deendoon Platform Administrator. |
| BP-008 | Accountability & Audit | Attributing every significant system action to a specific user and point in time. |
| BP-009 | Business Configuration | Tuning credit and recovery policy without engineering involvement. |
| BP-010 | Customer Data Onboarding & Maintenance | Bringing existing customer records into the system and keeping them free of duplication. |
| BP-011 | External Recovery Hand-off | Submitting a case beyond internal recovery capability to the Deendoon Super Admin for direct handling, while retaining visibility into its progress. |

---

## 2.5 Business Requirements

Each requirement is Mandatory for Version 1 unless stated otherwise, per the Feature Freeze. Format: **ID — Requirement.** *Rationale.* Traces to Goal(s), Process, and the corresponding Version 1 scope item in `01_Project_Overview.md` §1.6.

### 2.5.1 Credit & Risk Management

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-001 | The business must be able to define an approved credit limit for each customer. | Prevents uncontrolled credit exposure. | BG-003 · BP-001 · Credit Limit Management |
| BR-002 | The business must be warned when a customer's total exposure would exceed their approved credit limit, while retaining discretion to proceed. | Surfaces risk without removing business judgment. | BG-003 · BP-001 · Credit Limit Management |
| BR-003 | The business must be able to view a customer's approved limit, current outstanding balance, and remaining available credit at any time. | Enables informed credit decisions. | BG-005 · BP-001 · Credit Limit Management |
| BR-004 | The business must be able to assess each customer's payment reliability using an objective, consistent scoring method. | Provides a quantitative risk signal independent of subjective judgment. | BG-003 · BP-001 · Credit Score |
| BR-005 | The business must be able to classify each customer's qualitative risk exposure, independent of their credit score. | Complements quantitative scoring with contextual judgment. | BG-003 · BP-001 · Risk Levels |
| BR-006 | The business must be able to track a customer's overall relationship/lifecycle standing, distinct from any single debt's status. | Gives a whole-customer view beyond individual transactions. | BG-005 · BP-002 · Customer Status |
| BR-007 | The business must be notified when a customer reaches their approved credit limit. | Enables timely action without manual monitoring. | BG-005 · BP-003 · Credit Limit Management; Notification Center |

### 2.5.2 Recovery & Collections Workflow

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-008 | The business must be able to track the financial state of each debt (e.g., pending, overdue, paid, written off) separately from its recovery progress. | Financial state and recovery workflow answer different questions and must not be conflated. | BG-002 · BP-002 · Debt Status |
| BR-009 | The business must be able to track how far a debt has progressed through the recovery process. | Enables process visibility and consistent escalation. | BG-002 · BP-002 · Recovery Stage |
| BR-010 | The business must be able to view the full chronological history of recovery actions taken on a debt in one place. | Supports informed decision-making and dispute resolution. | BG-005 · BP-002 · Recovery Timeline; Follow-up History |
| BR-011 | The business must be able to reach customers automatically through reminders without manual effort per case, with reminder timing configurable by the business through System Settings. | Reduces reliance on the owner remembering to follow up, while letting each business tune cadence to its own recovery policy. | BG-001, BG-002 · BP-003 · Smart Daily Reminder; Business Rule Recovery Automation; System Settings |
| BR-012 | The business must be able to reach customers manually through WhatsApp, SMS, or phone call when automation is insufficient. | Preserves human judgment for exceptional cases. | BG-001 · BP-003 · Manual WhatsApp; Manual SMS; Call Reminder |
| BR-013 | The business must be able to record a customer's commitment to pay by a specific date and be reminded of it. | Converts verbal commitments into trackable, actionable data. | BG-001 · BP-003 · Promise to Pay |
| BR-014 | The business must be able to escalate unresolved debts to a formal, trackable collection case. | Provides a structured path when standard follow-up fails. | BG-004 · BP-004 · Professional Collection |
| BR-015 | The business must be able to override the automatically determined recovery stage when a valid business justification exists, with that justification recorded. | Preserves flexibility for legitimate exceptions while maintaining accountability. | BG-004, BG-007 · BP-004, BP-008 · Recovery Stage Override |
| BR-016 | The business must be able to view all upcoming recovery-related activity in a single consolidated view. | Supports proactive planning of collection effort. | BG-005 · BP-006 · Calendar View |
| BR-017 | The business must be notified in one place of significant recovery-related events. | Reduces the need to monitor multiple areas of the system. | BG-005 · BP-006 · Notification Center |

### 2.5.3 Payments & Financial Documentation

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-018 | The business must be able to record payments received against a specific debt, whether paid in full or in part. | Establishes the factual basis for debt resolution and reporting, reflecting real-world payment behavior. | BG-001 · BP-005 · Payment Tracking |
| BR-019 | The business must be able to provide the customer with formal proof of payment automatically. | Builds trust and prevents payment disputes. | BG-004 · BP-005 · Digital Receipt Generator |
| BR-020 | The business must be able to formally demand payment using a professionally worded, escalating set of documents. | Increases the credibility and effectiveness of escalation. | BG-004 · BP-004 · Demand Letter Generator |
| BR-021 | The business must be able to produce a consolidated statement of a customer's debt and payment history on demand. | Supports transparency and dispute resolution. | BG-004, BG-005 · BP-005 · Customer Statement of Account |
| BR-022 | The business must be able to attach supporting free-text notes to a debt or collection case. | Preserves context and evidence relevant to recovery. | BG-004 · BP-004, BP-005 · Notes |

> **Correction (SRS Final Alignment, Product Owner Decision, 2026-08-08).** BR-022 previously read "attach supporting notes and documents ... Notes & Attachments; Document Scanner." The implemented, final product provides a free-text `notes` field on Debt and Collection Case (backend-complete: `PUT /debts/{id}`, `PUT /collection-cases/{id}` both accept `notes`, returned by their Resources) — this requirement is retitled accordingly. **"Document Scanner"** (camera-based document capture/OCR) and arbitrary file **attachment** to a Customer/Debt/Collection Case were never implemented in either the backend or the Customer Mobile App and are not part of the final product — OCR is independently confirmed out of scope elsewhere in this SRS set (`03_Functional_Requirements.md`, Module 11 Out of Scope). Supporting evidence, where needed, is provided instead by the four system-generated Document types (Receipt, Demand Letter, Statement, Invoice — Module 8) and the Timeline/Activity Feed. This requirement is not retired — the Notes portion is a real, implemented capability — only narrowed to match what was actually built.

### 2.5.4 Reporting & Business Intelligence

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-023 | The business must be able to see its receivables categorized by how overdue they are. | Standard, essential visibility for any receivables operation. | BG-003, BG-005 · BP-006 · Aging Analysis |
| BR-024 | The business must be able to view key recovery and receivables performance indicators at a glance, including over historical periods (day/week/month/year) where applicable. | Supports fast, informed executive decision-making and trend awareness over time. | BG-005 · BP-006 · Executive KPI Cards |
| BR-025 | The business must be able to export its reports for external use. | Supports accounting, compliance, and stakeholder needs outside the system. | BG-005 · BP-006 · Export Reports |
| BR-026 | The business must be able to locate any customer, debt, or related document quickly, regardless of originating module. | Reduces time spent navigating between areas of the system. | BG-005 · BP-006 · Global Search |
| BR-027 | The business must be able to filter and search operational data by criteria relevant to recovery work. | Enables targeted, efficient collection effort. | BG-005 · BP-006 · Advanced Search & Filters |

### 2.5.5 Access Control & Governance

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-028 | The system must ensure the Deendoon Platform Administrator cannot view or act on a tenant's financial data except where the Professional Collection Request workflow explicitly grants it; the Business Owner has full access within their own tenant. | Protects sensitive financial data by keeping tenant-side and platform-side access strictly separate. | BG-006, BG-007 · BP-007 · Role-Based Access Control |
| BR-029 | The system must enforce exactly two fixed account types — Business Owner (tenant-side) and Deendoon Platform Administrator (platform-side) — each reflecting a distinct, real operational responsibility, with no role assignment or additional tiers within a tenant. | Ensures access reflects the two real operational responsibilities that exist in Version 1. | BG-006 · BP-007 · RBAC (Business Owner; Platform Administrator — amended v1.4, see Revision History) |

### 2.5.6 Data Integrity & Auditability

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-030 | The business must be able to determine who performed any significant action in the system and when, from an immutable record that normal users cannot alter. | Establishes accountability for every action taken by the Business Owner account and by the Deendoon Platform Administrator; accountability is meaningless if the record itself can be edited. | BG-007 · BP-008 · Audit Trail |
| BR-031 | The business must never permanently lose a financial record through user action. | Financial records are the business's core asset; irreversible loss is unacceptable. | BG-007 · BP-008 · Soft Delete / Archive |
| BR-032 | The business must be able to recover an archived record if removed in error or needed again. | Complements BR-031 with a practical reversal path. | BG-007 · BP-008 · Soft Delete / Archive (Restore) |
| BR-033 | The platform must protect the business's data against system-level loss through regular backups, independent of user action. | Provides continuity assurance beyond user-level safeguards. | BG-007 · BP-008 · Automated Infrastructure Backups (NFR) |

### 2.5.7 Platform Configurability & Operations

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-034 | The business must be able to configure its own credit and recovery policy values without engineering changes. | Enables the business to adapt policy to its own operating context. | BG-008 · BP-009 · System Settings |
| BR-035 | The business must be able to configure its company profile, branding — including logo, business name, address, and contact details — and document templates. | Keeps customer-facing documents (Demand Letters, Receipts, Statements) consistent and professional in representing the business identity. | BG-004, BG-008 · BP-009 · System Settings |
| BR-036 | Every debt, receipt, demand letter, statement, and collection case must be uniquely and consistently identifiable. | Supports traceability, referencing, and professional record-keeping. | BG-007, BG-008 · BP-002 · Auto Numbering |

### 2.5.8 Customer Data Management

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-037 | The business must be able to bring in existing customer records in bulk. | Reduces onboarding friction for businesses migrating to Deendoon. | BG-008 · BP-010 · Customer Import |
| BR-038 | The business must be warned when it may be creating a duplicate customer record, while retaining the ability to proceed if the records are genuinely distinct. | Preserves data quality without blocking legitimate business activity. | BG-007, BG-008 · BP-010 · Duplicate Customer Detection |

### 2.5.9 Professional Collection Requests *(added — reopened scope)*

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-039 | The business must be able to submit an open Collection Case to Deendoon's own recovery team when internal recovery efforts are insufficient. | Gives businesses a path forward on cases beyond their own operational capacity, without abandoning the debt. | BG-001, BG-004 · BP-011 · Professional Collection Requests |
| BR-040 | The business must be able to track the status of a submitted Request from submission through to a final outcome. | Preserves visibility and trust once a case leaves the business's direct control. | BG-005 · BP-011 · Professional Collection Requests |
| BR-041 | The business must be able to communicate directly with Deendoon's recovery team about a submitted Request. | Supports clarification and information exchange without the business losing context on its own case. | BG-004, BG-005 · BP-011 · Professional Collection Requests |
| BR-042 | The Deendoon Super Admin must be able to review, accept or request more information on, and progress submitted Requests to a final outcome. | Enables Deendoon to act on hand-off cases in a structured, accountable way, using the same Super Admin Web Panel already approved for platform administration. | BG-001, BG-004 · BP-011 · Professional Collection Requests |

---

## 2.6 Business Constraints

| ID | Constraint | Traces To |
|---|---|---|
| BC-001 | Credit limit enforcement must remain advisory (soft warning) only; the system must never block a transaction from being recorded solely due to a credit limit breach in Version 1. | 01 §1.9 Principle 2 · Credit Limit Management |
| BC-002 | Financial records must never be permanently deleted by user action in Version 1. | 01 §1.9 Principle 4 |
| BC-003 | Business-tunable policy values must not be hardcoded into the system. | 01 §1.9 Principle 5 · System Settings |
| BC-004 | Version 1 operates as a single-location model per tenant; branch/multi-location structures are out of scope. | 01 §1.7 |
| BC-005 | Version 1 operates in a single currency per tenant; multi-currency is out of scope. | 01 §1.7 |
| BC-006 | Version 1 assumes generally available network connectivity; full offline operation is out of scope. | 01 §1.7 |
| BC-007 | Credit Score in Version 1 must be derived from deterministic business rules only; AI/ML-based scoring is out of scope. | 01 §1.7 |
| BC-008 | Backup recovery in Version 1 is an operational/infrastructure responsibility, not a self-service user capability. | 01 §1.7 |
| BC-009 | Submitting a Collection Case as a Professional Collection Request never removes the business's own visibility into that case; the business retains its Collection Case record and history regardless of Request status. | 01 §1.8, Professional Collection Request Channel |

---

## 2.7 Success Metrics

Business-level indicators used to judge whether Version 1 is achieving its goals. These are business measures, not system dashboard specifications (see `03_Functional_Requirements.md` for the Executive KPI Cards feature behavior).

| ID | Metric | Purpose | Traces To |
|---|---|---|---|
| SM-001 | Total Outstanding Amount | Measures overall receivables exposure. | BG-003, BG-005 · Executive KPI Cards |
| SM-002 | Total Collected (Period) | Measures recovery effectiveness over time. | BG-001 · Executive KPI Cards |
| SM-003 | Recovery Rate | Measures overall program effectiveness (collected vs. raised). | BG-001, BG-002 · Executive KPI Cards |
| SM-004 | Total Overdue Debts | Measures the scale of collection effort required. | BG-002, BG-003 · Executive KPI Cards |
| SM-005 | Customers Over Credit Limit | Measures current credit risk exposure. | BG-003 · Executive KPI Cards |
| SM-006 | Active Collection Cases | Measures formal escalation workload. | BG-004 · Executive KPI Cards |
| SM-007 | Average Days to Recover Debt | Measures how quickly debts move from overdue to recovered, directly evidencing progress on time-to-recovery. | BG-002 · Debt Status; Recovery Stage |
| SM-008 | Promise Fulfillment Rate | Measures the proportion of Promise to Pay commitments that are honored, evidencing the reliability of that recovery channel. | BG-001, BG-002 · Promise to Pay |
| SM-009 | Professional Collection Requests Resolved | Measures how many hand-off cases reach a final outcome (Recovered/Closed), evidencing the value of the escalation channel itself. | BG-001, BG-004 · Professional Collection Requests |

---

## 2.8 Business Rules (High-Level)

Stated here at business-policy level only. Detailed logic, thresholds, formulas, and state-transition specifications are defined in `04_Business_Rules.md`.

| ID | Rule | Detail Deferred To |
|---|---|---|
| BRL-001 | Credit limit checks are advisory; the system must never prevent a transaction from being recorded solely due to a credit limit breach. | 04 |
| BRL-002 | Recovery Stage is normally system-determined; manual override requires a recorded reason and is restricted to authorized roles. | 04, 08 |
| BRL-003 | Every override, archive action, and status change must be attributable to a specific user, timestamp, and reason where applicable. | 04 |
| BRL-004 | Archived records are excluded from default operational views but are never permanently removed, and remain subject to role-based visibility in search and reporting. | 04, 08 |
| BRL-005 | Duplicate customer detection is advisory; it must never prevent a new customer record from being created once the user confirms it is not a duplicate. | 04 |
| BRL-006 | Risk Level, Credit Score, Customer Status, and Debt Status are independently maintained; a change to one must not automatically overwrite another. | 04 |
| BRL-077 | A Professional Collection Request follows a fixed status sequence from Submitted through a terminal outcome (Recovered or Closed); the submitting business retains full visibility and a conversation thread throughout, regardless of status. | 04 |

---

## 2.9 Traceability Matrix

| Business Requirement | Business Goal(s) | Business Process | Version 1 Scope Item (01 §1.6) |
|---|---|---|---|
| BR-001 – BR-003 | BG-003, BG-005 | BP-001 | Credit Limit Management |
| BR-004 | BG-003 | BP-001 | Credit Score |
| BR-005 | BG-003 | BP-001 | Risk Levels |
| BR-006 | BG-005 | BP-002 | Customer Status |
| BR-007 | BG-005 | BP-003 | Credit Limit Management; Notification Center |
| BR-008 | BG-002 | BP-002 | Debt Status |
| BR-009 | BG-002 | BP-002 | Recovery Stage |
| BR-010 | BG-005 | BP-002 | Recovery Timeline; Follow-up History |
| BR-011 | BG-001, BG-002 | BP-003 | Smart Daily Reminder; Business Rule Recovery Automation |
| BR-012 | BG-001 | BP-003 | Manual WhatsApp; Manual SMS; Call Reminder |
| BR-013 | BG-001 | BP-003 | Promise to Pay |
| BR-014 | BG-004 | BP-004 | Professional Collection |
| BR-015 | BG-004, BG-007 | BP-004, BP-008 | Recovery Stage Override |
| BR-016 | BG-005 | BP-006 | Calendar View |
| BR-017 | BG-005 | BP-006 | Notification Center |
| BR-018 | BG-001 | BP-005 | Payment Tracking |
| BR-019 | BG-004 | BP-005 | Digital Receipt Generator |
| BR-020 | BG-004 | BP-004 | Demand Letter Generator |
| BR-021 | BG-004, BG-005 | BP-005 | Customer Statement of Account |
| BR-022 | BG-004 | BP-004, BP-005 | Notes |
| BR-023 | BG-003, BG-005 | BP-006 | Aging Analysis |
| BR-024 | BG-005 | BP-006 | Executive KPI Cards |
| BR-025 | BG-005 | BP-006 | Export Reports |
| BR-026 | BG-005 | BP-006 | Global Search |
| BR-027 | BG-005 | BP-006 | Advanced Search & Filters |
| BR-028 – BR-029 | BG-006, BG-007 | BP-007 | Role-Based Access Control |
| BR-030 | BG-007 | BP-008 | Audit Trail |
| BR-031 – BR-032 | BG-007 | BP-008 | Soft Delete / Archive |
| BR-033 | BG-007 | BP-008 | Automated Infrastructure Backups |
| BR-034 – BR-035 | BG-008, BG-004 | BP-009 | System Settings |
| BR-036 | BG-007, BG-008 | BP-002 | Auto Numbering |
| BR-037 | BG-008 | BP-010 | Customer Import |
| BR-038 | BG-007, BG-008 | BP-010 | Duplicate Customer Detection |
| BR-039 – BR-041 | BG-001, BG-004, BG-005 | BP-011 | Professional Collection Requests |
| BR-042 | BG-001, BG-004 | BP-011 | Professional Collection Requests |

---

## References

| Reference | Description |
|---|---|
| `01_Project_Overview.md` (Approved) | Scope baseline for this document — Sections 1.4 through 1.9 in particular. |
| `03_Functional_Requirements.md` | Successor document specifying system behavior (the "HOW") for each Business Requirement above. |
| `04_Business_Rules.md` | Successor document specifying detailed logic for the high-level rules in Section 2.8. |

---

**Next Document:** `03_Functional_Requirements.md` — pending review and approval of this document.
