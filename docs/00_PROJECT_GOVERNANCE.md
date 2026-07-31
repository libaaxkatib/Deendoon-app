# 00. Project Governance

| Field | Value |
|---|---|
| **Document ID** | DEENDOON-GOV-00 |
| **Document Title** | Project Governance |
| **Version** | 1.1 |
| **Status** | Approved & Frozen |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Product Owner (2026-07-31) |
| **Last Updated** | 2026-07-31 |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-31 | Initial governance document, established at Product Owner direction after the Business Health Formula Specification v1.0 closure, to formalize the document-management practices already in use throughout the project (SRS Guardian reopening process, Approved/Frozen terminology, decision-by-decision facilitation) rather than introduce new ones. | Claude |
| 1.1 | 2026-07-31 | **Documentation Freeze Rule added (§17), Product Owner direction, on completion of Documentation Baseline v1.0.** Distinguishes routine documentation maintenance (versioning, revision history, cross-references, README sync, metadata/header corrections — always permitted) from structural SRS synchronization work (permitted only when triggered by an approved Product, Architecture, Formula, or Database change). No other section altered. | Claude |

---

## 1. Purpose

This document defines the governance rules for the **entire Deendoon project** — how documents are created, versioned, approved, frozen, reopened, and retired.

It does **not** define what Deendoon is, how any module behaves, what any business rule states, or what any formula calculates. It contains no product requirements, no business rules, no API contracts, no database design, and no module architecture. Every one of those things has exactly one existing authoritative home (the SRS, an engineering module specification, or `deendoon/CLAUDE.md`), and this document does not duplicate any of them.

This document governs the *process* by which those other documents are written, changed, and trusted. If any statement here appears to describe product behavior rather than document process, that is an error in this document, not a second source of truth for that behavior.

---

## 2. Product Owner Authority

The Product Owner is the sole authority for this project. Specifically, only the Product Owner may:

- Approve a document or move it to Frozen status.
- Approve any architectural decision (data model, formula, scoring logic, RBAC model, or workflow).
- Resolve a conflict between two approved documents.
- Approve scope changes, including anything that would expand, narrow, or redefine previously approved scope.
- Authorize reopening a Frozen document.

Engineering roles (including AI assistants) may **research, propose, present trade-offs, and recommend** — they may never make any of the decisions above unilaterally. Where this document says a decision is "required," it means Product Owner approval is required, recorded in that document's Revision History.

---

## 3. Document Hierarchy

Deendoon's documentation is organized in four tiers. Each tier has a distinct job; none substitutes for another.

| Tier | Contents | Governs |
|---|---|---|
| **1 — Governance** | This document (`docs/00_PROJECT_GOVERNANCE.md`) | How documents are managed |
| **2 — Product Specification (SRS)** | `SRS/01`–`11` | What Deendoon is: requirements, rules, data model, API, security, acceptance criteria |
| **3 — Engineering Constitution** | `deendoon/CLAUDE.md` | How AI and engineers must work in the backend codebase |
| **4 — Engineering Module Specifications** | `deendoon/docs/*.md` (e.g., `Business_Health_Formula_Specification_v1.0.md`) | Detailed architecture/formula design for a specific engineering module, produced through the process this document defines |

**Precedence for a document-management question** (e.g., "which version is current," "was this ever approved," "can this be reopened"): this document is authoritative.

**Precedence for an engineering or code decision:** unchanged from `deendoon/CLAUDE.md`'s existing Rule Precedence — Approved SRS > explicit Product Owner decisions > previously approved engineering decisions > Engineering Principles > the remainder of `CLAUDE.md`. This document does not alter that order; it sits alongside it, governing the documents that order refers to.

---

## 4. Single Source of Truth

Every topic has exactly one authoritative document. No fact is intentionally duplicated across tiers.

- Product behavior, business rules, data model, API contracts, security/RBAC → SRS (Tier 2) only.
- Engineering conduct, coding standards, AI working rules → `CLAUDE.md` (Tier 3) only.
- A specific module's detailed formula/architecture (e.g., Business Health's weighting) → that module's own Tier 4 specification only.

When a document needs to reference a fact owned elsewhere, it **cross-references** ("see `X`, §Y") rather than restating the fact. A cross-reference that goes stale is a Document Update violation (§13), not a reason to duplicate the content instead.

If the same fact is ever found stated in two places with two different values, that is a governance defect: stop, do not silently pick one, and raise it for Product Owner resolution (§15).

---

## 5. Approved / Frozen Definition

- **Draft** — not yet reviewed by the Product Owner. Carries no authority; nothing may be implemented from it.
- **Approved** — the Product Owner has explicitly signed off on the document's current content. It is authoritative and may be implemented against.
- **Approved & Frozen** (or simply **Frozen**) — Approved, and additionally closed to further change except through the Change Control Process (§6). A Frozen document is the strongest state a document can hold.
- **Reopened** — a previously Approved or Frozen document that has an active, in-progress amendment. A Reopened document remains authoritative for every part *not* under active amendment; the amended part is not authoritative until re-approved.

A document is never silently upgraded between these states. Every transition requires an explicit Product Owner action, recorded in that document's own Revision History (§7).

---

## 6. Change Control Process

Changing any Approved or Frozen document — SRS or engineering module — follows the same process, regardless of tier:

1. **Identify the exact change** — which section, which statement, and why.
2. **Classify it** — is this a correction (the document was wrong relative to what was actually decided), an amendment (the decision itself is changing), or a calibration (a pre-authorized numeric adjustment within an already-approved mechanism — see §10)?
3. **Present it to the Product Owner** before editing — what changes, why, and what it affects downstream (§11).
4. **Obtain explicit approval.**
5. **Apply the change**, following the Document Update Rules (§13): version bump, Status update, Revision History row, Last Updated date.

No document moves from Frozen back to Draft. A Frozen document under amendment becomes **Reopened** (§5) for the duration of the change, then returns to Approved or Frozen once the amendment itself is approved.

This is the same process already used throughout the SRS (the "Guardian reopening process") and the Business Health Formula Specification — this section names and generalizes it; it does not introduce a new one.

---

## 7. Versioning Policy

- Every governed document (Tier 1, 2, or 4) carries a **Version** field and a **Revision History** table with one row per change: Version, Date, Description, Author.
- Versioning is `MAJOR.MINOR` (e.g., `1.3`, `1.4`). A MINOR increment is any approved amendment or correction within an existing scope. A MAJOR increment is reserved for a full re-architecture or scope replacement — expected to be rare, and itself a Product Owner decision.
- The Revision History is permanent. Superseded content is marked superseded/retired in place (with reasoning), never deleted — consistent with `CLAUDE.md`'s "Preserve History" documentation rule.
- Every document also carries a **Last Updated** date, kept in sync with the latest Revision History row — a mismatch between the two is a Document Update violation (§13).

---

## 8. AI Governance Rules

These apply to any AI assistant working on Deendoon documentation or code, in addition to (not replacing) `deendoon/CLAUDE.md`'s existing "AI Working Rules" and "Things AI Must Never Do."

- Present options and trade-offs for any decision reserved to the Product Owner (§2); never decide it unilaterally.
- Treat every Approved or Frozen document as binding until the Change Control Process (§6) produces a new approval.
- Never introduce a new metric, business concept, role, or architectural element while executing a documentation or governance task, even one framed as "just formatting" or "just an index" — governance and formatting work must not smuggle in design decisions.
- When a genuine gap or inconsistency is found (a stale cross-reference, a missing document, an un-versioned change), surface it explicitly rather than silently resolving or silently ignoring it.
- Classify before acting: for any existing item under discussion (a known issue, an open decision, a proposed change), state what kind of thing it is before touching it.

---

## 9. Architecture Protection Rules

- Approved architecture (a data model, a module's structural design, an RBAC model) may not be redesigned, replaced, or reinterpreted outside the Change Control Process (§6).
- A downstream layer may never invert, reinterpret, or override the meaning of an upstream approved decision (the precedent for this rule: Business Health's normalized-input orientation, which no downstream layer may flip).
- Architecture decisions are recorded where they are made (the owning module's Tier 4 specification, or the relevant SRS document) — never restated as a parallel, second copy elsewhere.
- A module's architecture is not considered Frozen piecemeal — either the whole architectural decision set for that module is approved, or it remains Reopened/Draft.

---

## 10. Formula Protection Rules

- An approved formula, weight, or threshold is a frozen constant once its document reaches Approved/Frozen status. It may not be edited informally, "tuned," or adjusted outside the Change Control Process (§6).
- **Calibration is distinct from redesign.** Where a document explicitly pre-authorizes a future calibration activity (e.g., Business Health's Critical Floor, deferred to a Formula Calibration phase), adjusting that specific, named value after implementation and validation does *not* require reopening the whole document — but the calibrated value must still be recorded (which value, what it was calibrated to, when, based on what validation) in that document's Revision History. An uncalibrated, undocumented change to a formula value is a governance violation regardless of how small the change looks.
- A formula must never be defined twice. Where one component's value is derived from another's (e.g., a Guardrail Ceiling defined as "the upper bound of the At Risk band" rather than a hardcoded number), the derivation is stated once, at the defining location, and referenced everywhere else — never restated as an independent constant that could drift out of sync.

---

## 11. Dependency Rules

- Every module specification must explicitly declare what it depends on (other modules, other formulas, other open SRS items such as DD-032) in its own header (§ "Module Information," see Appendix) and in the project navigation index (`README.md`).
- A module may be marked Approved or Frozen for its own architecture even while a genuine dependency remains open elsewhere (e.g., Business Health v1.0 is Frozen while Recovery Rate's own formula, DD-032, remains open) — but the dependency must be visibly recorded, never silently assumed resolved.
- No module's implementation may proceed past the point where it needs an unresolved dependency's value. The dependency, not the dependent module's document status, is what blocks implementation.
- Circular dependencies between two module specifications are not permitted; if one is found, it is raised to the Product Owner rather than resolved by picking a direction unilaterally.

---

## 12. Implementation Rules

- Code may only be implemented against a document in **Approved** or **Approved & Frozen** status. Draft and Reopened sections are not implementation-ready.
- If a document's status permits implementation but a specific declared dependency (§11) is still open, the dependent piece of implementation waits — it is not stubbed, guessed, or implemented against an assumed value.
- If implementation reveals that an Approved/Frozen document is wrong, ambiguous, or incomplete, the document is corrected and re-approved via the Change Control Process (§6) **before** the code changes — never the reverse, per `CLAUDE.md`'s existing "Documentation-first changes" principle.

---

## 13. Document Update Rules

Any edit to a governed document (Tier 1, 2, or 4) must, in the same change:

1. Increment the **Version** field per the Versioning Policy (§7).
2. Update the **Status** field if the change affects it (e.g., Approved → Reopened).
3. Add a **Revision History** row describing what changed, why, and citing the Product Owner approval it rests on.
4. Update **Last Updated** to the date of the change.
5. Update any other document whose cross-reference to this one is now stale (§4) — or, if that update is out of scope for the current task, explicitly flag it as a follow-up rather than leaving it silently inconsistent.

A change that updates content but skips any of the above is incomplete, regardless of how correct the content itself is.

---

## 14. Scope Control (Prevent Feature Creep)

- No document-management, formatting, indexing, or governance task may introduce a new business feature, metric, role, or architectural element. If a task's execution seems to require inventing something new, stop and raise it rather than proceeding.
- A module's approved scope is exactly what its Frozen specification states — no more. Ideas surfaced during implementation ("this would also be useful," "we should also track X") are logged as future considerations, not added to the current scope, per `CLAUDE.md`'s existing "No Scope Creep" sprint rule.
- Reorganizing or re-indexing documents (e.g., a navigation README) must never change what any document says — only how it is found.

---

## 15. Decision-Making Process

Two modes are available, and the Product Owner selects which applies:

- **Decision-by-decision mode** — for genuinely open architectural or business questions, each decision is presented individually: business purpose, 2–3 options with trade-offs, a recommendation, and explicit approval before moving to the next. This is the default mode for new design work.
- **Consolidated specification mode** — once a Product Owner judges the architecture sufficiently mature, remaining items may be consolidated into a single specification document for one holistic review, with every item clearly marked as either already-approved (restated for context) or newly-proposed (requiring a decision). This mode does not skip approval — it batches the presentation of it.

In both modes, nothing is treated as decided until the Product Owner has explicitly approved it in that document's Revision History.

---

## 16. Governance Principles

- **Product Owner authority is absolute** within this project; documentation and engineering exist to inform and execute that authority, not to substitute for it.
- **Documentation is a first-class deliverable** — a decision that isn't recorded didn't happen, for the purposes of this project.
- **One fact, one home.** Every piece of product, engineering, or architectural truth has exactly one authoritative document; everything else cross-references it.
- **Transparency over silence.** Open items, dependencies, and gaps are always stated explicitly — never smoothed over to make a document look more complete than it is.
- **No silent change.** Every change to an Approved or Frozen document is visible in that document's own Revision History, with no exceptions for small or "obvious" edits.
- **Consistency compounds.** A governance rule followed once and skipped the next time is not a governance rule — every rule in this document applies uniformly, including to this document itself.

---

## 17. Documentation Freeze Rule

Once the Documentation Baseline is declared **COMPLETE**, the following applies:

**Routine documentation maintenance may continue**, including:
- Version updates
- Revision History updates
- Cross-reference corrections
- README synchronization
- Metadata corrections
- Header corrections

**However, no further structural SRS synchronization work shall be performed** unless triggered by one of the following:
- An approved Product Change
- An approved Architecture Change
- An approved Formula Change
- An approved Database Change

This prevents unnecessary documentation churn while ensuring documentation always follows approved product decisions.

---

## Appendix — Standard Module Information Header

Every Tier 4 engineering module specification carries this header immediately after its title, ahead of its existing content:

```
# Module Information

Module Name:
Version:
Status:
Owner:
Dependencies:
Related Documents:
Last Updated:
Next Planned Work:
```

This header is metadata only — it summarizes facts already established in the document's own Version/Status/Revision History fields (or, for documents predating this convention, the facts as currently true). It does not add new content, and it does not change any previously approved decision.
