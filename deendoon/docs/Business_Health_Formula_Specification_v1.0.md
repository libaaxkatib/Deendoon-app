# Business Health Formula Specification v1.0

# Module Information

Module Name: Business Health
Version: v1.0
Status: FROZEN
Owner: Product Owner
Dependencies: Risk Level Engine (Portfolio Customer Risk Levels input), Recovery Rate formula (DD-032)
Related Documents: `docs/00_PROJECT_GOVERNANCE.md`; `SRS/03_Functional_Requirements.md` (FR-053); `SRS/04_Business_Rules.md` (DD-032); `deendoon/docs/Mobile_UI_V1_Frozen.md` §4.1
Last Updated: 2026-07-31
Next Planned Work: Recovery Rate Formula (DD-032), Completed Debt Cycle Count, Critical Floor Calibration, Risk Level Formula Design

---

**Date:** 2026-07-31
**Status:** FROZEN (2026-07-31). Business Health Architecture and this Formula Specification are approved and closed. Remaining work — Recovery Rate Formula (DD-032), Completed Debt Cycle Count, Critical Floor Calibration, and Risk Level Formula Design — is implementation and calibration activity, not architectural work, and does not reopen this document.
**Author:** Business Analyst / Solution Architect (Claude)
**Approved By:** Product Owner (2026-07-31)
**Scope:** Consolidates the remaining Business Health Formula Design items (Guardrail Trigger Conditions, Guardrail Constraint Mechanics, Final Status Band Thresholds) into one specification, per Product Owner direction to stop the one-decision-at-a-time process now that the architecture is sufficiently complete.

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 (draft) | 2026-07-31 | Initial consolidated specification, restating the already-frozen Business Health architecture (§1) and proposing three remaining items for approval: Guardrail Trigger Condition, Final Status Band Thresholds, Guardrail Constraint Mechanic. | Claude |
| 1.0 (final) | 2026-07-31 | **Product Owner approval with three modifications:** (1) Guardrail Trigger mechanism approved, numeric Critical Floor value deferred to a post-implementation Formula Calibration phase rather than fixed here; (2) Status Bands raised to Healthy 80–100 / Needs Attention 50–79 / At Risk 0–49, reflecting Business Health's role as an executive KPI; (3) Guardrail Ceiling redefined as a live reference to the At Risk band's upper bound rather than a hardcoded constant, so it cannot drift out of sync with future Status Band revisions. Document status set to FROZEN. | Claude |
| 1.0 (retroactive) | 2026-07-31 | Added this Revision History table and Module Information header (Documentation Consistency Audit correction) to bring this document into compliance with `docs/00_PROJECT_GOVERNANCE.md` §7. No content, decision, or approved value changed. | Claude |

---

**How to read this document:** this specification is FROZEN — every item below is 🔒 **APPROVED**, including the three modifications recorded above. Nothing here is open for reinterpretation; any future change requires the Change Control Process (`docs/00_PROJECT_GOVERNANCE.md` §6). The 🔒/⚠ markers on individual sections below are preserved as a historical record of what was originally proposed versus already-frozen at the time this document was drafted — they do not indicate anything is still pending.

---

## 1. Frozen Architecture (context only — no changes proposed)

| Element | Decision |
|---|---|
| Composite score | 0–100, three status bands: Healthy / Needs Attention / At Risk (`Mobile_UI_V1_Frozen.md` §4.1) |
| Input 1 — Collection Performance | Recovery Rate (SM-003). Already percentage-shaped; no normalization needed. *(Recovery Rate's own formula is a separate open SRS item, DD-032 — not resolved by this document.)* |
| Input 2 — Outstanding Exposure | Total Outstanding Amount (SM-001), normalized against the tenant's own historical baseline. Gated on **Sufficient Historical Activity** = a minimum number of completed Debt Cycles (Paid or Written Off) — never calendar time, never raw transaction volume. Until met, the tenant remains in the existing approved **Neutral Baseline** state (§4.1) — the whole card, not a partial substitution. |
| Input 3 — Portfolio Customer Risk Levels | Severity-weighted distribution index over the tenant's Customer Risk Level classifications (Low/Medium/High), weighted by **Health Contribution Weights**: Low = 100, Medium = 50, High = 0. Severity-only — no financial weighting permitted. |
| Orientation rule | Once normalized, an input's meaning is immutable: higher value = healthier business, always. No downstream layer may invert or reinterpret it. |
| Combination method | Weighted Average, then Business Health Guardrails as a separate downstream constraint layer — never a second scoring engine. |
| Weights | Collection Performance 45% / Outstanding Exposure 20% / Portfolio Customer Risk Levels 35%. Deterministic, system-defined, non-configurable, tenant-independent, part of the product specification. |
| Guardrail authority | May read only the three normalized inputs — never raw events, workflow states, or customer-level records. Must be deterministic, auditable, explainable, exceptional rather than routine. |
| Pipeline | Normalize Inputs → Weighted Average → Business Health Score → Business Health Guardrails → Final Score and Status |

Also out of scope for this document, by your own prior sequencing: Risk Level's own Formula Design (its point catalog and thresholds) follows *after* Business Health is complete — this document does not touch it.

---

## 2. 🔒 Guardrail Trigger Conditions — APPROVED (mechanism only; value deferred)

**Mechanic:** since Guardrails may only read the three already-normalized, higher-is-healthier inputs, the only kind of condition available to them is *"has one of these three values fallen to a severity level"* — nothing else is visible to this layer by design.

**Approved rule:** each of the three normalized inputs (all on the same 0–100 scale, by the orientation rule) is checked against a single shared **Critical Floor**. If **any one** input's value is at or below the Critical Floor, a Guardrail is triggered — no compounding condition (two inputs failing at once) is required, since a single severe dimension is already the exact danger this layer exists to catch. A single shared floor (rather than three separately-tuned floors) was chosen because all three inputs already share one scale and one meaning by construction.

**Critical Floor value: NOT SET.** Per Product Owner decision, the exact numeric value is explicitly deferred to a future **Formula Calibration** phase, to be determined after implementation and validation against real data — not fixed in advance as part of this specification. Implementation must treat the Critical Floor as a named, centrally-defined constant (not inlined at call sites) so it can be calibrated later without touching the Guardrail logic itself.

---

## 3. 🔒 Final Status Band Thresholds — APPROVED

**Approved bands for the Final Score (0–100):**

| Band | Range |
|---|---|
| Healthy | 80–100 |
| Needs Attention | 50–79 |
| At Risk | 0–49 |

**Business rationale (Product Owner):** Business Health is an executive KPI. Healthy must represent genuinely strong business performance, not a simple passing score — hence the higher bar than originally proposed (70) for entering the Healthy band.

---

## 4. 🔒 Guardrail Constraint Mechanics — APPROVED

**Mechanic:** a Guardrail may only constrain, never calculate — so its effect is a deterministic **ceiling function**, applied after the Weighted Average produces the Business Health Score:

```
IF any normalized input ≤ Critical Floor:
    Final Score  = MIN(Business Health Score, Guardrail Ceiling)
    Final Status = At Risk
ELSE:
    Final Score  = Business Health Score
    Final Status = derived from Final Score via the Status Band Thresholds (§3)
```

**Guardrail Ceiling — defined by reference, not by value:**

> **Guardrail Ceiling = the upper boundary of the At Risk status band.**

Per Product Owner decision, this is deliberately *not* a separately hardcoded number. It is defined as a live reference to §3's At Risk upper bound, so that if the Status Band Thresholds are ever revised in a future product version, the Guardrail Ceiling updates automatically and never needs a separate, coordinated change. Implementation must read this value from the Status Band configuration, never duplicate it as an independent constant.

At the current approved bands (§3), this resolves to **49** — but that number is a *consequence* of §3, not a fact stated or maintained here.

A single-tier mechanic is approved: a triggered Guardrail always forces Final Status straight to At Risk, not a graduated step down to Needs Attention. This keeps the layer's behavior unambiguous — when it acts, it says so plainly, consistent with "exceptional rather than routine."

---

## 5. End-to-End Formula Flow

The full pipeline for a given tenant on Dashboard load, per the approved §2–§4:

1. **Gather raw data:** current Recovery Rate (once DD-032 is resolved), current Total Outstanding Amount, current distribution of the tenant's customers across Customer Risk Level (once Risk Level's own engine is live).
2. **Check Sufficient Historical Activity** for Outstanding Exposure (completed Debt Cycle count). If not met → the entire Business Health card displays the existing approved Neutral Baseline state; stop here.
3. **Normalize each input** to 0–100, higher = healthier:
   - Collection Performance = Recovery Rate, unchanged.
   - Outstanding Exposure = current exposure compared against the tenant's own historical baseline.
   - Portfolio Customer Risk Levels = severity-weighted distribution index using Health Contribution Weights (Low=100/Medium=50/High=0).
4. **Weighted Average:** Business Health Score = (Collection Performance × 45%) + (Outstanding Exposure × 20%) + (Portfolio Customer Risk Levels × 35%).
5. **Guardrails:** if any normalized input ≤ Critical Floor (value pending Formula Calibration) → Final Score = MIN(Business Health Score, Guardrail Ceiling = upper bound of At Risk band = 49), Final Status = At Risk. Otherwise Final Score = Business Health Score.
6. **Status mapping:** if not already forced by a Guardrail, map Final Score to Healthy / Needs Attention / At Risk via the Status Band Thresholds.
7. Return Final Score, Final Status, and status subtext to the Dashboard API for card rendering.

---

## 6. Complete Formula Summary

| Component | Value / Rule | Status |
|---|---|---|
| Inputs | Collection Performance, Outstanding Exposure, Portfolio Customer Risk Levels | 🔒 Approved |
| Weights | 45% / 20% / 35% | 🔒 Approved |
| Health Contribution Weights | Low=100, Medium=50, High=0 | 🔒 Approved |
| Sufficient Historical Activity basis | Completed Debt Cycles (exact minimum count TBD) | 🔒 Basis approved / open item: exact count |
| Orientation rule | Higher normalized value = healthier, immutable | 🔒 Approved |
| Guardrail scope | Three normalized inputs only, no raw data | 🔒 Approved |
| Guardrail trigger mechanic | Any input ≤ shared Critical Floor | 🔒 Mechanism approved / open item: numeric value (Formula Calibration) |
| Guardrail constraint mechanic | Cap Final Score at Guardrail Ceiling (= upper bound of At Risk band), force At Risk | 🔒 Approved |
| Status bands | Healthy 80–100 / Needs Attention 50–79 / At Risk 0–49 | 🔒 Approved |

**Three items remain open, none blocking this approval:**
- **Critical Floor numeric value** (§2) — deferred to a future Formula Calibration phase, by explicit Product Owner decision.
- **DD-032** (Recovery Rate's own formula) — pre-existing open SRS item, out of this document's scope.
- **Exact minimum completed-Debt-Cycle count** for Sufficient Historical Activity — already flagged as deferred in prior decisions, carried forward unchanged.

---

## 7. Approval Record

**Business Health Formula Specification v1.0 — APPROVED (2026-07-31)**, with the following modifications from the original draft:

1. **§2 Guardrail Trigger** — shared Critical Floor mechanism approved; the numeric value is explicitly *not* frozen here and is deferred to a post-implementation Formula Calibration phase.
2. **§3 Status Bands** — raised from the original proposal (70/40/0) to Healthy 80–100 / Needs Attention 50–79 / At Risk 0–49, reflecting Business Health's role as an executive KPI.
3. **§4 Guardrail Constraint** — single-tier ceiling mechanic approved; the ceiling is defined as a live reference to the At Risk band's upper bound (currently 49), not a separately hardcoded constant, so it stays consistent automatically if Status Bands are revised in a future version.

No other architectural changes were made.
