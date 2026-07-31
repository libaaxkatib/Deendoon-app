# Deendoon

**Deendoon** is a Smart Debt Recovery Assistant for small and medium businesses. Full product vision, scope, and architecture: [SRS/01 — Project Overview](SRS/01_Project_Overview.md).

This README is a **navigation index only**. It does not restate product requirements, business rules, or architecture — see the linked documents for that.

---

## Governance

All documents in this repository — SRS and engineering module specifications alike — are managed under [docs/00_PROJECT_GOVERNANCE.md](docs/00_PROJECT_GOVERNANCE.md): versioning, approval states, change control, and scope discipline.

---

## Software Requirements Specification (SRS)

The SRS is the single source of truth for Version 1 product scope and behavior.

| Document | Version | Status |
|---|---|---|
| [01 — Project Overview](SRS/01_Project_Overview.md) | 1.5 | Reopened — Pending Re-Approval |
| [02 — Business Requirements](SRS/02_Business_Requirements.md) | 1.6 | Reopened — Pending Re-Approval |
| [03 — Functional Requirements](SRS/03_Functional_Requirements.md) | 1.10 | Reopened — RBAC Amendment and Risk Level Engine Amendment applied; Module 12 still awaiting original approval |
| [04 — Business Rules](SRS/04_Business_Rules.md) | 1.6 | Reopened — Pending Re-Approval |
| [05 — UI/UX Specification](SRS/05_UI_UX_Specification.md) | 1.5 | Reopened — RBAC Architecture Amendment (retroactive) applied |
| [06 — Database Design](SRS/06_Database_Design.md) | 1.6 | Reopened — §6.1 (`roles`) amended |
| [07 — API Design](SRS/07_API_Design.md) | 1.5 | Reopened — §5.4 (Collection Cases) amended |
| [08 — Security and RBAC](SRS/08_Security_and_RBAC.md) | 1.4 | Reopened — §5 (Roles & Permissions) amended |
| [09 — Non-Functional Requirements](SRS/09_Non_Functional_Requirements.md) | 1.2 | Approved |
| [10 — Acceptance Criteria](SRS/10_Acceptance_Criteria.md) | 1.4 | Approved & Frozen |
| [11 — Development Roadmap](SRS/11_Development_Roadmap.md) | 1.3 | Draft — Pending Review |

---

## Engineering Modules

Detailed engineering/architecture specifications produced under the governance process (`docs/00_PROJECT_GOVERNANCE.md` §6, §15), for pieces of the system whose design goes beyond what the SRS itself specifies.

| Module | Version | Status | Dependencies | Document |
|---|---|---|---|---|
| Business Health | v1.0 | FROZEN | Risk Level Engine, Recovery Rate (DD-032) | [deendoon/docs/Business_Health_Formula_Specification_v1.0.md](deendoon/docs/Business_Health_Formula_Specification_v1.0.md) |
| Risk Level Engine | v1.0 (Conceptual) | Approved (Conceptual Architecture) — Formula Design proposed, pending approval | Recovery Stage, Collection Case, Professional Collection Request (data sources for Secondary Events only) | [deendoon/docs/Risk_Level_Engine_v1.0.md](deendoon/docs/Risk_Level_Engine_v1.0.md) |
| Risk Level Engine — Formula Design | v1.0 | DRAFT — Pending Product Owner Approval | Risk Level Engine (architecture) | [deendoon/docs/Risk_Level_Formula_Specification_v1.0.md](deendoon/docs/Risk_Level_Formula_Specification_v1.0.md) |
| RBAC / Authentication Model | v1.0 | Approved & Implemented | None | [deendoon/docs/RBAC_Architecture_Amendment_Proposal.md](deendoon/docs/RBAC_Architecture_Amendment_Proposal.md) (historical decision record) — current authoritative model in [SRS/08 §5](SRS/08_Security_and_RBAC.md) |

---

## Repository Structure

```
Deendoon-app/
├── README.md
├── docs/                              # Project governance
│   └── 00_PROJECT_GOVERNANCE.md
├── SRS/                                # Product specification (single source of truth)
│   ├── 01_Project_Overview.md
│   ├── 02_Business_Requirements.md
│   ├── 03_Functional_Requirements.md
│   ├── 04_Business_Rules.md
│   ├── 05_UI_UX_Specification.md
│   ├── 06_Database_Design.md
│   ├── 07_API_Design.md
│   ├── 08_Security_and_RBAC.md
│   ├── 09_Non_Functional_Requirements.md
│   ├── 10_Acceptance_Criteria.md
│   └── 11_Development_Roadmap.md
├── deendoon/                           # Laravel backend
│   ├── CLAUDE.md                       # Engineering constitution (how, not what)
│   └── docs/                           # Engineering module specifications & decision records
└── mobile/                             # Flutter application
```

## Version

**v1.0 — In Development**
Last Updated: 2026-07-31

## License

Proprietary – All rights reserved.

## Contributing

This is a private, closed-development project. It is not currently open to external contributions.

---

==================================================

## PROJECT MILESTONE

**Documentation Baseline v1.0**

**Status:**
COMPLETE

**Approved By:**
Product Owner

**Foundation Phase:**
COMPLETE

**Next Phase:**
Risk Level Formula Design v1.0

==================================================
