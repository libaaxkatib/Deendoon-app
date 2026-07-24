# 01. Project Overview

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-01 |
| **Document Title** | Project Overview |
| **Version** | 1.3 |
| **Status** | Reopened — Pending Re-Approval |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Product Owner |
| **Last Updated** | 2026-07-24 |
| **Scope Baseline** | Version 1 Feature Freeze (approved) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: Purpose through Definitions and Glossary | Claude |
| 1.1 | 2026-07-24 | Documentation polish pass: naming clarification for Customer Mobile App, Reminder Engine/Promise-to-Pay clarification, Notification Center consumption-only clarification, Global Search RBAC-awareness, Archive/search-visibility clarification, added glossary entries (Collection Case, Tenant, Company/Business), added document metadata and Revision History/References sections. No business logic or scope changes. Approved by Product Owner. | Claude |
| 1.2 | 2026-07-24 | **Reopened — intentional scope change.** Added Professional Collection Requests (hand-off of a Collection Case to Deendoon's own recovery team) as an approved Version 1 capability: new Target User (Deendoon Recovery Specialist), Scope of Version 1 addition, High-Level System Overview addition, and glossary entry. This is the first Version 1 capability that crosses tenant boundaries (Deendoon acting as a service provider to its own customers), distinct from every other approved capability, which is single-tenant-scoped. No other approved content changed. | Claude |
| 1.3 | 2026-07-24 | **Correction to 1.2.** Removed the invented "Deendoon Recovery Specialist" actor — Version 1 has exactly two application interfaces (Customer Mobile App, Deendoon Super Admin Web Panel) and no additional internal roles, portals, or dashboards. Professional Collection Requests are instead handled entirely by the already-approved Deendoon Platform Administrator (Super Admin), via the already-approved Super Admin Web Panel. Also reverted an earlier mischaracterization of that actor as "tenant-scoped" — it operates at the true platform level, which is what makes reviewing requests from any tenant possible without inventing a new actor. Any further coordination among Deendoon's own staff happens manually, outside the system, and is not modeled. | Claude |

---

## 1.1 Purpose

This document defines the project-level context for Deendoon Version 1: the problem it solves, the business objectives it serves, the users it is built for, and the boundaries of what is — and is not — being built in this release.

It is the first of eleven documents comprising the Software Requirements Specification (SRS):

| # | Document |
|---|---|
| 01 | Project Overview *(this document)* |
| 02 | Business Requirements |
| 03 | Functional Requirements |
| 04 | Business Rules |
| 05 | UI/UX Specification |
| 06 | Database Design |
| 07 | API Design |
| 08 | Security and RBAC |
| 09 | Non-Functional Requirements |
| 10 | Acceptance Criteria |
| 11 | Development Roadmap |

Documents 02–11 assume this document as their scope baseline. Any requirement in a later document that would expand, contradict, or redesign the scope defined here is out of bounds unless it corrects a contradiction found during specification — per the Version 1 Feature Freeze.

---

## 1.2 Product Vision

Deendoon is a **Smart Debt Recovery Assistant** for small and medium businesses that extend informal or semi-formal credit to their customers.

It is not a passive ledger or a generic bookkeeping tool. Deendoon actively assists the business owner through the full lifecycle of a debt — from the moment credit is extended, through automated and manual follow-up, through professional escalation, to final recovery — using business-rule-driven automation, risk intelligence, and a professional documentation trail at every step.

The product's differentiation is captured in one principle: **Deendoon does the following-up, so the business owner doesn't have to remember to.**

---

## 1.3 Problem Statement

Small and medium businesses that sell on credit — retailers, wholesalers, service providers — routinely face:

- **No systematic record of who owes what.** Debts are tracked in notebooks, spreadsheets, or memory, with no single source of truth.
- **Inconsistent follow-up.** Reminders happen when the owner remembers, not on a schedule — late or missed follow-up directly causes uncollected debt.
- **No risk visibility.** Business owners cannot tell, at a glance, which customers are becoming high-risk before it's too late, and continue extending credit to customers who are already overextended.
- **Unprofessional or absent escalation.** When gentle reminders fail, most small businesses have no structured way to escalate — no formal demand letters, no defined collection process — which weakens recovery and damages customer relationships.
- **No proof or paper trail.** Payments, reminders, and promises are not documented, creating disputes and no accountability when staff are involved.
- **No accountability when multiple staff are involved.** As a business grows past a single owner-operator, there is no way to control who can see or edit financial data, or to know who changed what.

Deendoon addresses each of these directly through its Version 1 feature set (Section 1.6).

---

## 1.4 Business Objectives

| Objective | How Version 1 Serves It |
|---|---|
| Increase recovered receivables | Automated multi-channel reminders, escalation workflow, Professional Collection |
| Reduce time-to-recovery | Recovery Stage automation, Recovery Timeline visibility, Calendar View |
| Reduce bad debt exposure | Credit Limit Management, Credit Score, Risk Levels, Aging Analysis |
| Professionalize collections | Demand Letter templates, Digital Receipts, Statements of Account |
| Provide operational visibility | Executive KPI Cards, Aging Analysis, Notification Center |
| Support multi-staff operation safely | Role-Based Access Control, Audit Trail |
| Protect financial data integrity | Soft Delete/Archive, Audit Trail, Automated Backups |
| Enable a scalable, commercial SaaS product | Auto Numbering, System Settings, Global Search, Import tooling |

---

## 1.5 Target Users

| User | Role in the System |
|---|---|
| **Business Owner / SME Operator** | Primary user. Manages customers and debts, monitors risk, initiates and reviews recovery activity. Uses the Customer Mobile App. |
| **Operations Manager** | Oversees day-to-day recovery operations across the business's customer base. Web Panel user. |
| **Collection Officer** | Executes follow-up actions (calls, reminders, professional collection cases) on assigned customers/debts. |
| **Finance Staff** | Manages payments, receipts, statements, and financial reporting. |
| **Support Staff** | Limited operational access to assist customers/business owners; not a financial decision-maker. |
| **Viewer** | Read-only access, typically for oversight or audit purposes. |
| **Customer (Debtor)** | Receives reminders and communications (WhatsApp/SMS/Call) and may interact with receipts/statements shared with them. Not a system login role in Version 1 beyond what is explicitly defined in later documents. |
| **Deendoon Platform Administrator (Super Admin)** | Operates the Deendoon Super Admin Web Panel at the true platform level — across the whole Deendoon platform, not scoped to one tenant. Distinct from the six tenant-scoped RBAC roles (`08_Security_and_RBAC.md`). Handles system configuration, template management, user/role administration, and — as of this reopening — reviews and actions Professional Collection Requests submitted by any tenant business. This is the only actor involved on Deendoon's side; no separate role or staff group is modeled in Version 1. If the Super Admin needs another Deendoon colleague's input, that coordination happens manually, outside the system. |

> **Naming clarification:** "Customer Mobile App" is the application used by Deendoon's own paying customers — i.e., the business owners and their staff listed above. It is **not** used by the business owner's own customers (debtors), who are referred to elsewhere in this document simply as "Customers" within the Debt Register context. This naming collision is inherited from the approved Feature Freeze terminology and is not being renamed here; this note exists solely to prevent misreading in subsequent SRS documents.

Exact permissions per role are defined in **08_Security_and_RBAC.md**.

---

## 1.6 Scope of Version 1

The following feature set is **frozen** per the Version 1 Feature Freeze and forms the mandatory scope of this SRS. Detailed behavior for each is specified in **03_Functional_Requirements.md** and **04_Business_Rules.md**.

**Core Recovery Workflow**
Debt Register · Smart Daily Reminder · Business Rule Recovery Automation · Manual WhatsApp · Manual SMS · Call Reminder · Promise to Pay · Payment Tracking · Follow-up History · Professional Collection · Professional Collection Requests (hand-off to the Deendoon Super Admin) *(new)* · Recovery Timeline · Recovery Stage (with audited Override)

**Risk & Financial Intelligence**
Risk Levels (qualitative) · Credit Score (quantitative, rule-based) · Credit Limit Management · Customer Status · Debt Status

**Documents & Reporting**
Document Scanner · Demand Letter Generator (First Reminder, Second Reminder, Final Demand, Legal Notice templates) · Digital Receipt Generator · Customer Statement of Account · Aging Analysis (dashboard widget, full report, pie chart, bar chart) · Export Reports (PDF/Excel/CSV) · Notes & Attachments

**Productivity & UX**
Premium Mobile UI · Customer Mobile App · Notification Center · Calendar View · Global Search · Quick Actions · Advanced Search & Filters · Duplicate Customer Detection · Customer Import (Excel)

**Administration & Governance**
Deendoon Super Admin Web Panel · Role-Based Access Control (Super Admin, Operations Manager, Collection Officer, Finance, Support, Viewer) · Audit Trail · System Settings · Soft Delete / Archive

**Platform Foundations**
Auto Numbering (Debt, Receipt, Demand Letter, Statement, Collection Case) · Automated Infrastructure Backups (non-functional requirement)

---

## 1.7 Out of Scope (Version 2+)

The following are explicitly deferred and must not be designed, implemented, or partially implemented as part of Version 1:

| Feature | Deferred Because |
|---|---|
| AI/ML-based Credit Scoring | V1 Credit Score is business-rule-based by design; an AI-driven model requires production data not yet available |
| Self-service Backup & Restore (user-facing UI) | Restore is high-risk without dedicated design; V1 covers this via automated infrastructure backups only (NFR) |
| Branch Management | Would require data-model, RBAC, and reporting changes across nearly every module |
| Multi-Currency | No confirmed need at V1 launch; adds exchange-rate and reporting complexity |
| Offline Mode | Most V1 features are inherently online (WhatsApp/SMS/Call delivery, cloud-synced Admin Panel); a scoped offline data-entry mode is a candidate V2 fast-follow |

Any additional ideas raised after this point are to be logged in **11_Development_Roadmap.md** under Version 2+ and are not to alter Version 1 scope.

---

## 1.8 High-Level System Overview

Deendoon is a multi-client SaaS system consisting of:

- **Customer Mobile App** — the primary interface for business owners and their staff (Operations Manager, Collection Officer, Finance, Support, Viewer, subject to role permissions). Provides the debt register, reminders, recovery workflow, dashboards, notifications, and document generation.
- **Deendoon Super Admin Web Panel** — the administrative and configuration surface: role/user management, System Settings, template management, audit trail, platform-wide dashboards, and customer import.
- **Recovery Automation Engine** — a shared business-rule engine driving Credit Score calculation and Recovery Stage progression, consumed by both clients.
- **Reminder Engine** — schedules and triggers WhatsApp, SMS, and Call reminders — including Promise-to-Pay due-date reminders — and feeds the Notification Center and Calendar View.
- **Notification Center & Calendar View** — presentation-only surfaces. The Notification Center displays events already generated by the Reminder Engine and other modules (Payment Tracking, Professional Collection, Recovery Automation); it does not generate, schedule, or originate any event itself. The Calendar View aggregates existing due dates, Promise-to-Pay dates, and reminder schedules for read-only visualization.
- **Document Generation Service** — produces Demand Letters, Digital Receipts, and Statements of Account as PDFs from configurable templates.
- **Reporting & Analytics Layer** — powers Aging Analysis, Executive KPI Cards, and report exports.
- **Platform Services** — Auto Numbering, Audit Trail, Role-Based Access Control, Soft Delete/Archive, and Automated Backups, consumed across all modules.
- **Professional Collection Request Channel** *(new)* — the one cross-tenant workflow in Version 1. A tenant submits a Collection Case (Module 7) to the Deendoon Super Admin, via the already-approved Deendoon Super Admin Web Panel, for direct handling; the tenant retains full visibility and a conversation thread throughout. No new actor, role, portal, or dashboard is introduced — Version 1 has exactly two application interfaces (Customer Mobile App and Deendoon Super Admin Web Panel), and this capability is handled entirely within the second one by the Deendoon Platform Administrator already described above. If the Super Admin chooses to involve other Deendoon staff, that coordination happens manually, outside the system, and is not tracked here.

Detailed architecture, data flow, and entity relationships are specified in **06_Database_Design.md** and **07_API_Design.md**.

---

## 1.9 Product Principles

These principles govern how every subsequent SRS document should resolve ambiguity or design decisions:

1. **Assistant, not archive.** The system should proactively drive recovery action (reminders, automation, escalation), not just store records.
2. **Soft guidance over hard blocking.** Where V1 introduces warnings (Credit Limit, Duplicate Customer Detection), the system informs and lets the authorized user decide — it never blocks the workflow.
3. **Every meaningful action is auditable.** Creation, modification, deletion (archive), status changes, overrides, and document generation are all recorded with user, timestamp, and reason where applicable.
4. **Financial records are never destroyed.** Deletion is always Archive/Restore, never permanent removal, in Version 1. Archived records are excluded from default operational lists and dashboards but remain retrievable via search and reporting, subject to the viewing user's role permissions.
5. **Configuration over hardcoding.** Business-tunable values (credit limit defaults, reminder timing, escalation thresholds, templates, branding) live in System Settings, not in code.
6. **Qualitative and quantitative risk signals coexist.** Risk Level, Credit Score, Customer Status, and Debt Status are distinct, complementary fields — never merged or redesigned into one another.
7. **Professional-grade output.** Every customer-facing document (Demand Letter, Receipt, Statement) is a formal, branded PDF artifact, not a plain message.
8. **Focused scope.** Deendoon is a debt recovery assistant, not a general-purpose accounting, invoicing, or ERP system — features that would pull it in that direction belong in Version 2+ discussions, not silent scope creep.

---

## 1.10 Definitions and Glossary

| Term | Definition |
|---|---|
| **Business Owner** | The primary account holder of a Deendoon business tenant. |
| **Customer** | An individual or entity that owes money to the business owner (the debtor). |
| **Debt** | A single credit/receivable record owed by a Customer, tracked in the Debt Register. |
| **Debt Register** | The core module recording all debts, their terms, and their current state. |
| **Debt Status** | The financial state of a specific debt: Draft, Pending, Overdue, Partial Paid, Paid, Cancelled, Written Off. |
| **Recovery Stage** | The workflow position of a specific debt within the recovery process: Stage 1 (Friendly Reminder) through Stage 6 (Recovered). System-managed by default; manually overridable with a mandatory reason, audited. |
| **Recovery Timeline** | The chronological, visual rendering of a debt's recovery journey (reminders, calls, promises, payments, escalation) on the Debt Details screen. |
| **Risk Level** | A qualitative risk classification assigned to a customer. |
| **Credit Score** | A quantitative, business-rule-derived score (0–100, banded Excellent/Good/Fair/Poor) reflecting a customer's payment behavior. |
| **Credit Limit** | The maximum approved outstanding balance for a customer, used to trigger soft warnings, never a hard block in V1. |
| **Customer Status** | The lifecycle/relationship status of a customer: Active, Good Standing, Late Payer, High Risk, In Collection, Recovered, Blocked. |
| **Promise to Pay** | A logged commitment by a customer to pay by a specific date. |
| **Professional Collection** | The formal escalation workflow and case management for debts requiring structured recovery action, including Demand Letter generation. |
| **Professional Collection Request** *(new)* | A tenant's submission of an open Collection Case to the Deendoon Super Admin, via the Deendoon Super Admin Web Panel, for direct, hands-on handling. Distinct from Professional Collection itself (which is the business's internal case management) — this is a hand-off *out* of the tenant's own operation and into Deendoon's. Handled entirely by the existing Deendoon Platform Administrator actor; no new role, staff group, or interface is introduced. The tenant retains visibility and a conversation thread throughout; submitting a Request does not remove the underlying Collection Case from the tenant's own view. |
| **Follow-up History** | The chronological log of all recovery-related actions taken on a debt or customer. |
| **Business Rule Recovery Automation** | The rule engine that drives Smart Daily Reminder scheduling, Credit Score calculation, and Recovery Stage progression. |
| **Smart Daily Reminder** | The automated reminder engine that schedules and triggers WhatsApp/SMS/Call reminders — including Promise to Pay due-date reminders — based on configured recovery policy. |
| **Notification Center** | In-app surface presenting all system-generated business events (overdue customers, promises due, credit limit reached, etc.), sourced from the Reminder Engine and other modules. It is consumption-only: it never generates, schedules, or originates events itself. |
| **Calendar View** | A read-only calendar visualization of due dates, promise-to-pay dates, and scheduled follow-up activity, aggregated from existing reminder and follow-up data. |
| **Aging Analysis** | The report and dashboard classification of outstanding receivables into Current, 1–30, 31–60, 61–90, and Over 90 day buckets. |
| **Demand Letter** | A formally generated PDF escalation document, produced from one of four templates (First Reminder, Second Reminder, Final Demand, Legal Notice). |
| **Digital Receipt** | An auto-generated PDF proof of payment. |
| **Statement of Account** | A generated PDF summarizing a customer's debt and payment history. |
| **Audit Trail** | The immutable log of system events (creation, edits, deletions/archives, status changes, overrides, document generation, authentication events), each recording User, Timestamp, Action, Entity, and Reason where applicable. |
| **Soft Delete / Archive** | The mechanism by which records are removed from active views without permanent deletion. Archived records are excluded from default operational lists and dashboards but remain retrievable via search and reporting, subject to the viewing user's role permissions; reversible via Restore. |
| **Auto Numbering** | The system-generated, sequential, unique identifier scheme applied to Debts, Receipts, Demand Letters, Statements, and Collection Cases. |
| **System Settings** | The centralized, admin-managed configuration module governing credit policy, recovery policy, notifications, company profile, branding, and document templates. |
| **Global Search** | The unified search capability spanning Customers, Debts, Receipts, Statements, Demand Letters, and Collection Cases. Search is RBAC-aware: results are filtered to only what the requesting user's role and permissions allow them to access, including correct handling of archived records per the Soft Delete / Archive policy. |
| **Role-Based Access Control (RBAC)** | The permission system restricting module and action access by assigned role. |
| **Deendoon Super Admin Web Panel** | The administrative web application used for platform configuration, user/role management, and system-wide reporting. |
| **Customer Mobile App** | The primary mobile application used by Deendoon's business-owner customers and their staff (Operations Manager, Collection Officer, Finance, Support, Viewer) for day-to-day debt recovery operations. Distinct from the "Customer" entity used elsewhere in this document, which refers to the business's own debtors — debtors do not use this application in Version 1. |
| **Collection Case** | A formal case record created under Professional Collection when a debt is escalated to structured recovery action. Receives its own Auto Numbering identifier (`COL-000001`) and may carry Notes & Attachments. |
| **Tenant** | A single business account within the Deendoon platform. In Version 1, all Customers, Debts, and configuration belong to exactly one Tenant; multi-location structures within a single Tenant (Branch Management) are out of scope — see Section 1.7. |
| **Company / Business** | The business entity operating a Deendoon Tenant — the owner of the Customers, Debts, and recovery activity managed within the system. Its identifying details (name, contact information, branding) are configured under System Settings → Company Profile. |

---

---

## References

| Reference | Description |
|---|---|
| Version 1 Feature Freeze (Product Discovery) | The approved product discovery record establishing the frozen Version 1 feature set, business rules, and module relationships. Treated as the authoritative source of truth for this document and all subsequent SRS documents. |
| `02_Business_Requirements.md` – `11_Development_Roadmap.md` | Companion SRS documents, to be produced sequentially following approval of this document. |

---

**Next Document:** `02_Business_Requirements.md` — pending review and approval of this document.
