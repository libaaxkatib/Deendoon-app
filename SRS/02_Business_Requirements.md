# 02. Business Requirements

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-02 |
| **Document Title** | Business Requirements |
| **Version** | 1.1 |
| **Status** | Approved |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Product Owner |
| **Last Updated** | 2026-07-24 |
| **Scope Baseline** | `01_Project_Overview.md` (Approved) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: Business Actors, Goals, Processes, Requirements, Constraints, Success Metrics, high-level Business Rules, and Traceability Matrix | Claude |
| 1.1 | 2026-07-24 | Documentation polish pass: clarified BR-011 (configurable reminder timing), BR-018 (full/partial payments), BR-024 (historical KPI periods), BR-030 (immutable audit records), BR-035 (branding elements); added SM-007 and SM-008. No scope or functionality changes. Approved by Product Owner — frozen as the official Business Requirements baseline. | Claude |

---

## 2.1 Purpose of This Document

This document defines **what** Deendoon Version 1 must achieve from a business perspective, and **why** — independent of how the system implements it. It does not describe screens, workflows, data structures, or system behavior; those are specified in `03_Functional_Requirements.md` onward.

Every requirement in this document traces back to the approved scope in `01_Project_Overview.md` (Section 1.6, Scope of Version 1) and, transitively, to the approved Version 1 Feature Freeze. No requirement in this document introduces functionality beyond that baseline.

Each requirement carries a unique identifier for traceability through the remaining SRS documents.

---

## 2.2 Business Actors

| ID | Actor | Description | Baseline Reference |
|---|---|---|---|
| BA-001 | Business Owner / SME Operator | Primary user; owns the Deendoon tenant; manages customers, debts, and recovery activity. | 01 §1.5 |
| BA-002 | Operations Manager | Oversees day-to-day recovery operations across the business's customer base. | 01 §1.5 |
| BA-003 | Collection Officer | Executes follow-up and collection actions on assigned customers/debts. | 01 §1.5 |
| BA-004 | Finance Staff | Manages payments, receipts, statements, and financial reporting. | 01 §1.5 |
| BA-005 | Support Staff | Limited operational access; assists but does not make financial decisions. | 01 §1.5 |
| BA-006 | Viewer | Read-only access, typically for oversight or audit. | 01 §1.5 |
| BA-007 | Customer (Debtor) | External actor; owes money to the business; receives reminders and documents. Does not use the Customer Mobile App. | 01 §1.5 |
| BA-008 | Deendoon Platform Administrator | Operates the Super Admin Web Panel at the platform/tenant-configuration level. | 01 §1.5 |

---

## 2.3 Business Goals

| ID | Goal | Baseline Reference |
|---|---|---|
| BG-001 | Increase the proportion of extended credit that is successfully recovered. | 01 §1.4 |
| BG-002 | Reduce the average time between a debt becoming overdue and being recovered. | 01 §1.4 |
| BG-003 | Reduce the business's exposure to customers who are unlikely to pay. | 01 §1.4 |
| BG-004 | Give the business formal, credible tools to escalate and document collection activity. | 01 §1.4 |
| BG-005 | Give business owners and managers real-time insight into receivables, risk, and recovery performance. | 01 §1.4 |
| BG-006 | Allow multiple staff to participate in recovery operations without compromising data control or accountability. | 01 §1.4 |
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
| BP-007 | Staff Access Governance | Controlling which staff can view or act on which financial data. |
| BP-008 | Accountability & Audit | Attributing every significant system action to a specific user and point in time. |
| BP-009 | Business Configuration | Tuning credit and recovery policy without engineering involvement. |
| BP-010 | Customer Data Onboarding & Maintenance | Bringing existing customer records into the system and keeping them free of duplication. |

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
| BR-022 | The business must be able to attach supporting notes and documents to a customer, debt, or collection case. | Preserves context and evidence relevant to recovery. | BG-004 · BP-004, BP-005 · Notes & Attachments; Document Scanner |

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
| BR-028 | The business must be able to restrict staff access to only the data and actions relevant to their role. | Protects sensitive financial data as the business scales its team. | BG-006, BG-007 · BP-007 · Role-Based Access Control |
| BR-029 | The business must be able to assign staff to a defined set of roles reflecting real operational responsibilities. | Ensures access reflects actual job function. | BG-006 · BP-007 · RBAC (Super Admin, Operations Manager, Collection Officer, Finance, Support, Viewer) |

### 2.5.6 Data Integrity & Auditability

| ID | Requirement | Rationale | Traces To |
|---|---|---|---|
| BR-030 | The business must be able to determine who performed any significant action in the system and when, from an immutable record that normal users cannot alter. | Establishes accountability across a multi-staff operation; accountability is meaningless if the record itself can be edited. | BG-007 · BP-008 · Audit Trail |
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
| BR-022 | BG-004 | BP-004, BP-005 | Notes & Attachments; Document Scanner |
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

---

## References

| Reference | Description |
|---|---|
| `01_Project_Overview.md` (Approved) | Scope baseline for this document — Sections 1.4 through 1.9 in particular. |
| `03_Functional_Requirements.md` | Successor document specifying system behavior (the "HOW") for each Business Requirement above. |
| `04_Business_Rules.md` | Successor document specifying detailed logic for the high-level rules in Section 2.8. |

---

**Next Document:** `03_Functional_Requirements.md` — pending review and approval of this document.
