# Deendoon

🚧 **Active Development** — Version 1 SRS in progress, implementation not yet started.

**Deendoon** is a Smart Debt Recovery Assistant for small and medium businesses that extend credit to their customers. It goes beyond simple debt tracking — automating follow-up, surfacing risk, and professionalizing the entire recovery process from first reminder to final collection.

## Vision

Deendoon exists so business owners don't have to remember to follow up. It combines a structured debt register, business-rule-driven recovery automation, risk and credit intelligence, and professional documentation into a single assistant — helping businesses recover receivables faster, reduce bad debt exposure, and operate with the accountability of a production-grade financial system.

## Development Status

**Version 1 — In Development**

Version 1 scope has completed product discovery and is under Feature Freeze. The Software Requirements Specification (SRS) is being written and reviewed section by section; implementation follows SRS approval.

| Phase | Status |
|---|---|
| Product Discovery & Feature Freeze | Complete |
| Software Requirements Specification (SRS) | In Progress |
| Implementation | Not Started |

## Core Capabilities

Approved Version 1 scope, grouped by area (see [01 — Project Overview §1.6](SRS/01_Project_Overview.md)):

- **Core Recovery Workflow** — Debt Register, Smart Daily Reminder, Business Rule Recovery Automation, Manual WhatsApp/SMS/Call reminders, Promise to Pay, Payment Tracking, Follow-up History, Professional Collection, Recovery Timeline, Recovery Stage.
- **Risk & Financial Intelligence** — Risk Levels, Credit Score, Credit Limit Management, Customer Status, Debt Status.
- **Documents & Reporting** — Document Scanner, Demand Letter Generator, Digital Receipt Generator, Customer Statement of Account, Aging Analysis, Export Reports, Notes & Attachments.
- **Productivity & UX** — Customer Mobile App, Notification Center, Calendar View, Global Search, Quick Actions, Advanced Search & Filters, Duplicate Customer Detection, Customer Import.
- **Administration & Governance** — Super Admin Web Panel, Role-Based Access Control, Audit Trail, System Settings, Soft Delete/Archive.
- **Platform Foundations** — Auto Numbering, Automated Infrastructure Backups.

## High-Level Architecture

- **Customer Mobile App** — primary interface for business owners and staff (day-to-day debt recovery operations).
- **Deendoon Super Admin Web Panel** — administration and configuration surface (roles, settings, templates, audit, platform-wide reporting).
- **Recovery Automation Engine** — shared business-rule engine driving Credit Score calculation and Recovery Stage progression.
- **Reminder Engine** — schedules and triggers WhatsApp, SMS, and Call reminders; feeds the Notification Center and Calendar View.
- **Document Generation Service** — produces Demand Letters, Digital Receipts, and Statements of Account as PDFs.
- **Reporting & Analytics Layer** — powers Aging Analysis, business reporting, and report exports.
- **Platform Services** — Auto Numbering, Audit Trail, RBAC, Soft Delete/Archive, Automated Backups.

Full detail in [01 — Project Overview §1.8](SRS/01_Project_Overview.md).

## Repository Structure

```
Deendoon-app/
├── README.md
└── SRS/                              # Software Requirements Specification
    ├── 01_Project_Overview.md
    ├── 02_Business_Requirements.md
    ├── 03_Functional_Requirements.md
    ├── 04_Business_Rules.md          # planned
    ├── 05_UI_UX_Specification.md     # planned
    ├── 06_Database_Design.md         # planned
    ├── 07_API_Design.md              # planned
    ├── 08_Security_and_RBAC.md       # planned
    ├── 09_Non_Functional_Requirements.md  # planned
    ├── 10_Acceptance_Criteria.md     # planned
    └── 11_Development_Roadmap.md     # planned
```

## Documentation

The SRS is the single source of truth for Version 1 scope and behavior. Approved documents:

- [01 — Project Overview](SRS/01_Project_Overview.md)
- [02 — Business Requirements](SRS/02_Business_Requirements.md)
- [03 — Functional Requirements](SRS/03_Functional_Requirements.md) *(in progress, module by module)*

Remaining SRS documents (Business Rules, UI/UX Specification, Database Design, API Design, Security and RBAC, Non-Functional Requirements, Acceptance Criteria, Development Roadmap) will be added as they are produced and approved.

## Planned Technology Stack

| Layer | Technology |
|---|---|
| Mobile Application | Flutter |
| Backend / API | Laravel |
| Database | MySQL |
| Admin Web Panel | Web-based administration portal (technology to be finalized) |

The stack is planned and subject to confirmation during the technical design phase (Database Design and API Design documents). Implementation technologies may evolve as those documents are finalized; such changes affect delivery only and do not alter the approved Version 1 product scope defined in the SRS.

## Version

**v1.0 — In Development**
Last Updated: 2026-07-24

## License

Proprietary – All rights reserved.

## Contributing

This is a private, closed-development project. It is not currently open to external contributions.
