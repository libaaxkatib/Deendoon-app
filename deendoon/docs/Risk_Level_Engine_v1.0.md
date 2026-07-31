# Risk Level Engine Specification v1.0

# Module Information

Module Name: Risk Level Engine
Version: v1.0 (Conceptual Architecture)
Status: Approved (Conceptual Architecture) — Formula Design proposed, pending Product Owner approval (see `Risk_Level_Formula_Specification_v1.0.md`)
Owner: Product Owner
Dependencies: Recovery Stage (SRS Module 5), Collection Case lifecycle (SRS Module 7, FR-040/FR-045), Professional Collection Request lifecycle (SRS Module 7, FR-072/FR-076) — data sources for Secondary Events only
Related Documents: `docs/00_PROJECT_GOVERNANCE.md`; `SRS/03_Functional_Requirements.md` (FR-027, reopened); `SRS/04_Business_Rules.md` (BRL-006, BRL-028/DD-010, BRL-031, BRL-032/034); `deendoon/docs/Business_Health_Formula_Specification_v1.0.md` (consumes this engine's output as the Portfolio Customer Risk Levels input); `deendoon/docs/Risk_Level_Formula_Specification_v1.0.md` (Formula Design, Sprint 2A)
Last Updated: 2026-07-31
Next Planned Work: Product Owner approval of `Risk_Level_Formula_Specification_v1.0.md`, then backend implementation (technical design already produced, Sprint 2)

---

**Date:** 2026-07-31
**Status:** Conceptual architecture APPROVED and FROZEN. This document records exactly what was decided; it introduces no new decision and changes nothing previously approved. Formula Design (point values, weights, thresholds) is explicitly out of scope for this document and remains open.
**Author:** Business Analyst / Solution Architect (Claude)
**Approved By:** Product Owner (2026-07-31, across the decision sequence recorded in §1–§6)
**Scope:** Transcribes the Risk Level Engine's conceptual design — determination mechanism, architecture, event structure, event catalogs, and value set — as a standalone specification, per Product Owner direction following the Business Health Formula Specification v1.0 closure.

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-31 | Initial retroactive documentation of the conceptual architecture already approved across a prior decision sequence (determination mechanism, engine architecture, Primary/Secondary event structure, both event catalogs, and the Low/Medium/High value set with semantics) — written here as a standalone specification since it had previously existed only in conversation history. No new decision made; nothing previously approved changed. | Claude |
| 1.0 (retroactive) | 2026-07-31 | Added this Revision History table (Documentation Consistency Audit correction) to bring this document into compliance with `docs/00_PROJECT_GOVERNANCE.md` §7. No content, decision, or approved value changed. | Claude |
| 1.0 (Formula Design status update) | 2026-07-31 | §7 updated: Formula Design has been produced as a complete proposal in `Risk_Level_Formula_Specification_v1.0.md` (Sprint 2A), pending Product Owner approval. This document's own conceptual architecture (§1–§6) is unchanged. | Claude |

---

**How to read this document:** every item below is 🔒 **APPROVED** — already decided in prior session discussion, restated here only so the design has a persisted home instead of living solely in conversation history. Nothing here is open for reinterpretation; any future change requires the Change Control Process (`docs/00_PROJECT_GOVERNANCE.md` §6).

---

## 1. 🔒 Determination Mechanism

Customer Risk Level is **fully system-calculated**. It is deterministic and backend-owned, with **no manual override**.

This reopens `SRS/03_Functional_Requirements.md` FR-027, which previously defined Risk Level as manually assigned by an authorized user. That manual-assignment behavior is retired.

**Business rationale (Product Owner):** Business Health requires a deterministic and auditable risk signal. A subjective, manually-assigned value cannot reliably serve as an input to a product-wide health score.

**Manual assessment carve-out:** a business owner's own qualitative assessment of a customer may be captured separately in the future as internal notes, if required — but any such note must never change the system-calculated Risk Level. Notes, if built, are a distinct feature from this engine, not an override path into it.

---

## 2. 🔒 Architecture

Risk Level is a **dedicated, independent, event-driven engine** — not derived from, and not a re-weighting of, any other signal.

It must remain independent from:
- **Credit Score** (a separate, already-approved deterministic engine — FR-026)
- **Customers Over Credit Limit** (a credit-policy metric, not a business-risk metric — explicitly rejected as a basis for risk concentration)
- **Business Health** (which *consumes* Risk Level's output; Risk Level must not be shaped by Business Health's needs)

**Design principles (all mandatory):**
- Backend-owned
- Event-driven
- Deterministic
- Fully auditable
- No machine learning
- No manual overrides

Risk Level is **dynamic**: it must improve when customer behavior improves and worsen when customer behavior deteriorates. The engine's event model supports both directions explicitly — Risk Increase Events and Risk Reduction Events — not a one-directional decay or a one-directional accumulation.

Risk Level represents **current collection risk** — a live read of collection danger, not a historical creditworthiness trend (that remains Credit Score's domain).

---

## 3. 🔒 Event Structure — Primary and Secondary

The event catalog is structured into two categories, not a single flat list:

| Category | Represents | Role |
|---|---|---|
| **Primary Events** | Customer behavior | Define the customer's actual collection risk — the core driver |
| **Secondary Events** | Collection workflow and escalation | Reinforce the Primary assessment — a confirmation signal only |

**Governing business rule:** Secondary Events must never become the primary driver of Customer Risk Level. Customer behavior (Primary Events) always has precedence over workflow activity (Secondary Events). This precedence is a required property of the eventual formula, not optional tuning.

---

## 4. 🔒 Primary Event Catalog (customer behavior)

Scoped to **current, active collection risk** — not general payment-timeliness history. On-Time Payment and Late Payment are explicitly **excluded** as direct Risk Level events (that territory belongs to Credit Score).

| Direction | Event |
|---|---|
| Risk Increase | Broken Promise to Pay |
| Risk Increase | Long Outstanding Debt |
| Risk Increase | Repeated Missed Commitments *(a pattern/frequency signal, not a single discrete event — exact frequency/window definition is Formula Design work)* |
| Risk Reduction | Fulfilled Promise to Pay |
| Risk Reduction | Debt Recovered / Paid in Full |
| Risk Reduction | Sustained Positive Repayment Behavior *(a pattern signal — details explicitly deferred by the Product Owner to a later definition)* |

This catalog defines **what types of behavior matter**. No point values, thresholds, or timing rules are defined here — that is Formula Design scope.

---

## 5. 🔒 Secondary Event Catalog (collection workflow and escalation)

Uses the complete, already-existing escalation model already approved elsewhere in the SRS — no new workflow mechanism introduced.

| Direction | Event | SRS Source |
|---|---|---|
| Risk Increase | Recovery Stage advancement | BRL-031, Module 5 |
| Risk Increase | Collection Case creation | FR-040 |
| Risk Increase | Professional Collection Request submission | FR-072 |
| Risk Reduction | Collection Case closed successfully | FR-045 |
| Risk Reduction | Professional Collection Request completed successfully | FR-076 |

No capping, deduplication, accumulation rules, or weighting are defined here — those belong to Formula Design, along with the numeric mechanism that enforces §3's Primary-over-Secondary precedence rule.

---

## 6. 🔒 Value Set and Semantics

Risk Level uses **three qualitative levels** — labels only, no numeric thresholds:

| Level | Semantic Definition |
|---|---|
| **Low Risk** | Customer currently exhibits healthy repayment behavior with no significant collection concerns. |
| **Medium Risk** | Customer shows warning signs that require monitoring and follow-up. |
| **High Risk** | Customer exhibits significant collection risk requiring priority attention. |

These are semantic definitions only. The numeric thresholds and algorithmic mapping from accumulated events to a Low/Medium/High label remain part of Formula Design.

---

## 7. What Remains — Formula Design

**Status update (2026-07-31, Sprint 2A):** Formula Design has now been produced as a complete, ready-to-approve proposal — `deendoon/docs/Risk_Level_Formula_Specification_v1.0.md`. It defines exact point values for every Primary and Secondary event, the numeric mechanism enforcing Primary precedence over Secondary (a capped Secondary contribution), the pattern-event frequency/window definitions, the Low/Medium/High score thresholds, and the combination/clamping rules. This document's own conceptual architecture (§1–§6 above) is unchanged by that proposal — it defines *what* matters; the new document defines *how much*.

Pending: Product Owner approval of that specification. Once approved, backend implementation proceeds per the technical design already produced separately (Sprint 2).

---

## 8. Decision Trail (for traceability only)

| Topic | Decision | Section |
|---|---|---|
| Determination mechanism | Fully system-calculated, deterministic, no manual override | §1 |
| Architecture | Dedicated event-driven engine, independent from Credit Score, Customers Over Credit Limit, Business Health | §2 |
| Event structure | Primary (customer behavior) + Secondary (workflow/escalation, confirmation-only) | §3 |
| Primary catalog | Broken Promise to Pay, Long Outstanding Debt, Repeated Missed Commitments / Fulfilled Promise to Pay, Debt Recovered, Sustained Positive Repayment Behavior | §4 |
| Secondary catalog | Recovery Stage advancement, Collection Case creation, PCR submission / Case closed successfully, PCR completed successfully | §5 |
| Value set | Low / Medium / High Risk, with semantics | §6 |

No item above is open for reinterpretation. Any change requires the Change Control Process (`docs/00_PROJECT_GOVERNANCE.md` §6).
