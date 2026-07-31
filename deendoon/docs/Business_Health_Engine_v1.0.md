# Business Health Engine Specification v1.0

# Module Information

Module Name: Business Health Engine
Version: v1.0 (Conceptual Architecture)
Status: Approved (Conceptual Architecture) — restates the already-**FROZEN** `Business_Health_Formula_Specification_v1.0.md` as a standalone architecture document, the same retroactive-documentation pattern used for `Risk_Level_Engine_v1.0.md`. Two genuinely new questions raised while writing this document (§7, §8) are flagged **Pending Product Owner Decision** and do not reopen anything already frozen.
Owner: Product Owner
Dependencies: Risk Level Engine (`Risk_Level_Engine_v1.0.md`, `Risk_Level_Formula_Specification_v1.0.md` — supplies the Portfolio Customer Risk Levels input); Recovery Rate formula (DD-032, open); Outstanding Exposure aggregation (existing Customer/Debt balance data, `CustomerBalanceService`)
Related Documents: `docs/00_PROJECT_GOVERNANCE.md`; `deendoon/docs/Business_Health_Formula_Specification_v1.0.md` (**FROZEN** — the authoritative formula/math source this document restates and does not reopen); `SRS/03_Functional_Requirements.md` FR-053; `SRS/04_Business_Rules.md` DD-032; `deendoon/docs/Mobile_UI_V1_Frozen.md` §4.1, §2.9
Last Updated: 2026-07-31
Next Planned Work: Sprint 17B implementation (pending this document's approval); Recovery Rate Formula (DD-032); Critical Floor Formula Calibration; completed-Debt-Cycle minimum count; Product Owner decision on the two open items in §7/§8

---

**Date:** 2026-07-31
**Status:** Conceptual architecture APPROVED — this document introduces no new architectural decision and changes nothing previously approved in `Business_Health_Formula_Specification_v1.0.md`. It exists because that document's own §1 ("Frozen Architecture — context only") was only ever a summary table; this is the missing standalone specification, in the same style and depth as `Risk_Level_Engine_v1.0.md`.
**Author:** Business Analyst / Solution Architect (Claude)
**Approved By:** Product Owner (2026-07-31) — for the restated frozen content; the two open items in §7/§8 remain Pending.
**Scope:** Documentation only. Sprint 17A. No PHP, Laravel, Flutter, migrations, services, tests, controllers, models, API endpoints, or database changes are introduced or implied.

---

## Conflict Check (recorded for traceability)

Before writing this document, a direct conflict was found and resolved with the Product Owner:

| Sprint 17A brief proposed | Already frozen (2026-07-31) | Resolution |
|---|---|---|
| 5 Health Bands: Excellent / Good / Fair / Poor / Critical | 3 status bands: Healthy (80–100) / Needs Attention (50–79) / At Risk (0–49), also written into `Mobile_UI_V1_Frozen.md` §4.1 | **Keep the frozen 3-band system.** Product Owner confirmed this document must build on the frozen v1.0, not redesign it. |
| A broad Positive/Negative Factor list, implying a many-input scoring model | 3 weighted inputs (Collection Performance 45%, Outstanding Exposure 20%, Portfolio Customer Risk Levels 35%) | **Keep the frozen 3-input model.** The Sprint 17A factor list (§7, §8 below) is reframed as illustrative sub-signals that already feed into these 3 inputs, not a fourth scoring dimension. |

Everything below reflects that resolution. No band, weight, or input introduced in the Sprint 17A brief that contradicts the frozen model has been adopted.

---

## 1. Purpose

Business Health exists to answer one question for a business owner, in one glance, without requiring them to read a report: **"Is my business's receivables portfolio in good shape right now?"**

It is the single most important number on the Home Dashboard (`Mobile_UI_V1_Frozen.md` §4.1) — shown before any other metric, KPI card, or list.

## 2. Business Goal

Deendoon's users are small and medium business owners, not accountants or credit analysts. Most cannot (and should not need to) interpret a collection-performance percentage, an outstanding-balance trend, and a customer risk distribution as three separate signals and mentally combine them. The Business Health Engine exists to do that combination *for* them — deterministically, not through judgment or AI — and hand back one number and one plain-language status a non-technical owner can act on immediately (per `Mobile_UI_V1_Frozen.md` §4.1: a status label, an encouraging or cautionary subtext, and a percentage gauge).

## 3. Definition of Business Health

**Business Health is a composite, portfolio-wide measure of the health of the tenant's entire receivables position — not any single customer's risk.**

This is the core distinction from the Risk Level Engine, restated exactly as scoped in Sprint 17A's brief:

| | Risk Level Engine | Business Health Engine |
|---|---|---|
| **Scope** | One customer | The entire tenant portfolio |
| **Question answered** | "How risky is *this* customer?" | "How healthy is *the business*, overall?" |
| **Output** | Low / Medium / High, per customer | One score (0–100) + one status band, per tenant |
| **Relationship** | An *input* to Business Health (severity-weighted, aggregated across all customers) | A *consumer* of Risk Level's output — never the reverse |

Business Health never re-derives customer-level risk itself. It reads the *already-computed* outputs of other modules (Risk Level per customer, Recovery Rate, Outstanding Amount) and combines them — it owns the combination, not the underlying signals.

## 4. Formula 🔒 (already frozen — restated, not re-derived)

```
CollectionPerformance   = Recovery Rate (0–100, already percentage-shaped)
OutstandingExposure     = current exposure normalized against the tenant's own historical baseline (0–100, higher = healthier)
PortfolioRiskLevels     = severity-weighted index over the tenant's Customer Risk Level distribution (0–100, higher = healthier)

BusinessHealthScore     = (CollectionPerformance × 0.45)
                        + (OutstandingExposure   × 0.20)
                        + (PortfolioRiskLevels    × 0.35)

FinalScore, FinalStatus = Guardrails(BusinessHealthScore)   — see §4's ceiling function below
```

**Guardrail ceiling function** (the only downstream adjustment permitted — a constraint, never a second scoring pass):

```
IF any of the 3 normalized inputs ≤ Critical Floor:
    FinalScore  = MIN(BusinessHealthScore, GuardrailCeiling)
    FinalStatus = At Risk
ELSE:
    FinalScore  = BusinessHealthScore
    FinalStatus = band lookup on FinalScore (§11)
```

`GuardrailCeiling` is a live reference to the upper bound of the At Risk band (§11), not an independently hardcoded number. `Critical Floor`'s exact value is deferred to Formula Calibration (unchanged from the frozen decision — see §17).

The full derivation, worked rationale, and Product Owner approval record for every value above live in `Business_Health_Formula_Specification_v1.0.md` — this section restates the destination, not the journey.

## 5. Scoring Method

**Weighted Average, then a single constraint layer — never a second scoring engine.** Two clean stages, in this fixed order:

1. **Normalize.** Convert each of the 3 raw signals to the same 0–100 scale, oriented so higher is always healthier (§9).
2. **Combine.** A pure linear weighted average of the 3 normalized inputs (§4) — no multiplicative terms, no conditional branching between inputs. This mirrors the same design choice already made for Risk Level's own combination rule (`Risk_Level_Formula_Specification_v1.0.md` §4): linear combination is the simplest model that is still auditable and explainable to a non-technical business owner.
3. **Constrain.** Guardrails may only cap the result downward toward At Risk when a single input has collapsed to a severe level — they can never raise a score, invent a new value, or read anything the two stages above didn't already produce.

## 6. Weighting Philosophy

The three weights (45% / 20% / 35%) are fixed, system-defined, and **not tenant-configurable** — every tenant's Business Health is computed the same way, so the number means the same thing across the whole product. The relative ordering reflects each input's evidentiary strength as a *current* health signal:

- **Collection Performance (45%, the largest weight).** Recovery Rate is the most direct, hardest-to-game evidence that money is actually being collected — it is what "health" most concretely means to a business owner, so it dominates the score.
- **Portfolio Customer Risk Levels (35%).** A forward-looking signal: it reflects the *composition* of the customer base (how much of the portfolio is trending toward trouble), complementing Collection Performance's backward-looking "how much came in."
- **Outstanding Exposure (20%, the smallest weight).** Deliberately the lightest weight because it is normalized against the tenant's *own* historical baseline rather than an absolute figure — it is the most relative, least directly comparable of the three, so it should nudge the score rather than dominate it.

This is a philosophy explanation of already-frozen values, not a re-opening of them — the exact percentages remain exactly as approved in `Business_Health_Formula_Specification_v1.0.md` §1.

## 7. Positive Factors

Sprint 17A's brief listed seven illustrative positive factors. Each maps onto one of the 3 already-approved inputs — **none of these introduces a fourth scoring dimension**:

| Sprint 17A factor | Feeds into | How |
|---|---|---|
| Collection Success Rate | Collection Performance | Directly — this *is* Recovery Rate (DD-032, pending its own exact formula) |
| Healthy Cash Recovery | Collection Performance | Same input; "healthy" describes a high Recovery Rate value, not a separate metric |
| Low Outstanding Debt | Outstanding Exposure | A lower current exposure relative to the tenant's own baseline normalizes to a higher (healthier) value |
| Low Overdue Balance | Outstanding Exposure | Overdue balances are a subset of outstanding exposure; the same normalized input already reflects this |
| Low High-Risk Customer Ratio | Portfolio Customer Risk Levels | Fewer High-classified customers raises the severity-weighted distribution index directly |
| Stable Customer Portfolio | **⚠ No home in the 3 frozen inputs — see Pending Decision below** | — |
| On-Time Payments | **⚠ No home in the 3 frozen inputs — see Pending Decision below** | — |

### ⚠ Pending Product Owner Decision — "On-Time Payments"

**The unresolved question:** On-Time Payment behavior is explicitly *excluded* from Risk Level Engine's own event catalog (`Risk_Level_Formula_Specification_v1.0.md` §4's catalog note: "On-Time Payment and Late Payment are explicitly excluded... that territory belongs to Credit Score's domain"). Credit Score is not one of Business Health's 3 approved inputs. As a result, On-Time Payments currently has no home anywhere in Business Health, even though Sprint 17A's brief names it as a positive factor.

**Trade-offs:**
- **Option A (recommended): Leave it out of Business Health entirely.** It remains Credit Score's exclusive domain, unchanged. Adding it as a 4th weighted input would require reopening the frozen 45/20/35% weighting (a real number must shrink to make room for a new one) — exactly the kind of architecture change this document was told not to decide silently.
- **Option B:** Fold an on-time-payment-rate component into Collection Performance's own composition, i.e., broaden Recovery Rate's still-open DD-032 formula to include timeliness. Risk: conflates two separately-open decisions (DD-032 and this one) into a single harder one.

**Recommendation:** Option A. Leave Pending Product Owner Decision.

### ⚠ Pending Product Owner Decision — "Stable Customer Portfolio"

**The unresolved question:** Sprint 17A's brief does not define what "stability" means numerically (customer count growth? retention rate? volatility of the Risk Level distribution over time?), and none of the 3 frozen inputs currently measure change-over-time — each is a current-state snapshot.

**Trade-offs:**
- **Option A (recommended): Do not add it as a scoring input.** If a stability-style metric is wanted, it belongs as a separate, purely descriptive Dashboard/Analytics indicator (parallel to the existing KPI cards) — not folded into the Business Health composite score, which should stay a snapshot measure per the frozen architecture.
- **Option B:** Define a precise stability metric and treat it as a genuinely new 4th input, with the same weighting-reallocation consequence flagged above for On-Time Payments.

**Recommendation:** Option A. Leave Pending Product Owner Decision.

## 8. Negative Factors

| Sprint 17A factor | Feeds into | How |
|---|---|---|
| Growing Outstanding Debt | Outstanding Exposure | Directly — a rising exposure relative to baseline normalizes to a lower value |
| Long Outstanding Debts | Outstanding Exposure | Same input; aged debt is a component of total exposure |
| Low Recovery Rate | Collection Performance | The same input, at its unhealthy end |
| Increasing High Risk Customers | Portfolio Customer Risk Levels | More High-classified customers lowers the severity-weighted index directly |
| Broken Promises | Portfolio Customer Risk Levels (indirectly) | Already scored per-customer by Risk Level Engine's Primary Events (`Risk_Level_Formula_Specification_v1.0.md` §2.1); a customer with broken promises has an elevated Risk Level, which the Portfolio index already reflects |
| Increasing Collection Cases | Portfolio Customer Risk Levels (indirectly) | Already scored per-customer as a Risk Level Secondary Event (Collection Case Created); Business Health does not re-count cases independently |

Every negative factor from the brief has a home in the 3 frozen inputs — no open item here, unlike §7.

## 9. Normalization 🔒 (already frozen — restated)

All 3 inputs share one rule: **normalized to 0–100, oriented so a higher value always means healthier.** This orientation is immutable once set — no downstream layer (Guardrails, Status Bands, the Dashboard) may invert or reinterpret it.

- **Collection Performance** — already percentage-shaped (Recovery Rate); no transformation needed.
- **Outstanding Exposure** — normalized against the *tenant's own* historical baseline, never an absolute cross-tenant figure (a $500 exposure means something different to a small trader than a large wholesaler). Gated on **Sufficient Historical Activity** — a minimum count of completed Debt Cycles (Paid or Written Off), never calendar time, never raw transaction volume. Until that minimum is met, the entire Business Health card shows the approved **Neutral Baseline** state (`Mobile_UI_V1_Frozen.md` §4.1's empty state) — never a partial or artificially computed percentage.
- **Portfolio Customer Risk Levels** — a severity-weighted distribution index using the **Health Contribution Weights**: Low = 100, Medium = 50, High = 0, averaged across the tenant's customers. Severity-only; no financial (debt amount) weighting is permitted here — a single High-Risk customer with a small balance counts exactly the same as one with a large balance, because this input measures portfolio *composition*, not portfolio *value* (value is already Outstanding Exposure's job).

## 10. Final Score

**An integer from 0 to 100.** Produced by the Weighted Average (§4), optionally capped downward by a triggered Guardrail (§4). Never negative, never above 100 — the weighted average of three already-0–100 inputs is mathematically bounded to the same range by construction, so no separate clamp step is needed (unlike Risk Level's additive point system, which requires an explicit `clamp(0,100)` because its raw sum can exceed either bound).

This score is the number shown in the Home Dashboard's circular percentage gauge (`Mobile_UI_V1_Frozen.md` §4.1).

## 11. Health Bands 🔒 (already frozen — 3 bands, not 5)

| Band | Range | Color (`Mobile_UI_V1_Frozen.md` §2.9) |
|---|---|---|
| **Healthy** | 80–100 | Success (green) |
| **Needs Attention** | 50–79 | Warning (amber/orange) |
| **At Risk** | 0–49 | Danger (red) |

This is the approved, frozen band system — see the Conflict Check above for why Sprint 17A's suggested 5-band Excellent/Good/Fair/Poor/Critical scale was not adopted. A future version could revisit band granularity, but that is a Change Control decision, not something this document (or Sprint 17A) opens.

## 12. Calculation Rules

1. **Recompute-from-source, always.** Business Health is never incremented or decremented — every calculation reads the *current* value of its 3 inputs fresh and recombines them. This is the same guarantee already established for `CustomerBalanceService::recalculate()` and the Risk Level Engine: recompute-from-source eliminates order-dependency and drift by construction.
2. **No independent event catalog.** Unlike Risk Level (which owns a Primary/Secondary Event catalog because it computes customer-level state itself), Business Health computes *nothing* from raw data directly — it only reads the already-current outputs of the modules that own each input (Recovery Rate's owning calculation, Outstanding Exposure's balance aggregation, Risk Level's per-customer classification). There is no separate "Business Health event" to define, because every event that could matter already updates one of the 3 inputs through its own owning module.
3. **Deterministic composition only.** No randomness, no machine learning, no probability model, no statistical forecasting — a plain weighted average and a plain ceiling function, matching the "no AI/ML" principle (BC-007) already applied identically to Credit Score and Risk Level.
4. **Guardrails constrain, never calculate.** They may only read the 3 already-normalized inputs — never raw events, workflow states, or individual customer records — and their only possible effect is capping the score toward At Risk (§4). They cannot raise a score, and they cannot act on anything Weighted Average did not already produce.

## 13. Recalculation Triggers

Business Health has exactly **one** trigger, deliberately simpler than Risk Level's multi-event catalog: **Dashboard load.**

Because Business Health reads the *already-current* state of its 3 inputs rather than maintaining any state of its own (§12, rule 2), it does not need its own event listeners, hooks, or recalculation call sites scattered across Payment/Debt/Promise services the way Risk Level does. Whichever module owns each input is responsible for keeping *that input* current (Risk Level already recalculates itself lazily on Customer/Debt access; Outstanding Exposure is already recalculated by `CustomerBalanceService` on every Debt/Payment write). Business Health simply re-reads all 3 at the moment the Dashboard is viewed and recombines them — matching the already-approved end-to-end flow in `Business_Health_Formula_Specification_v1.0.md` §5 ("The full pipeline for a given tenant on Dashboard load").

This is consistent with the standing architectural decision (`docs/Performance_Architecture.md`): no queue, no scheduler, no background worker, no cache to invalidate. The only accepted cost is that a Business Health view always does a small amount of live aggregation work at read time — an accepted trade-off identical in spirit to Risk Level's own lazy-evaluation trade-off for Long Outstanding Debt.

## 14. Future Extensibility

- **New inputs.** If a future version adds a 4th (or replaces a 3rd) input — e.g., resolving §7's On-Time Payments question — the weighting formula (§4) must be revisited as a single Change Control decision (all weights must still sum to 100%), not layered on ad hoc.
- **Formula Calibration.** The Critical Floor's numeric value (§4), the exact minimum completed-Debt-Cycle count for Sufficient Historical Activity (§9), and DD-032's Recovery Rate formula are all explicitly deferred to post-implementation calibration against real tenant data — this is calibration, not architecture, and does not reopen this document (matching the precedent already set for Risk Level's own point-value calibration).
- **Band granularity.** A future version could revisit the 3-band system (§11) if real usage data shows business owners want finer-grained feedback — this would be a Change Control decision affecting both this document and `Mobile_UI_V1_Frozen.md` §4.1 together, never one without the other.
- **Guardrail expansion.** If a second severe-condition signal is later identified, it must still satisfy §12 rule 4 (constrain, never calculate) — Guardrails are deliberately not a place to add new scoring logic.

## 15. Examples

All examples assume Sufficient Historical Activity has already been met (§9) and no Guardrail is triggered unless stated.

**Example A — a healthy tenant.**
Collection Performance = 90, Outstanding Exposure = 85, Portfolio Customer Risk Levels = 88.
`BusinessHealthScore = (90×0.45) + (85×0.20) + (88×0.35) = 40.5 + 17 + 30.8 = 88.3 → 88`
Final Score = 88 → **Healthy**.

**Example B — a tenant with one severely underperforming dimension, otherwise decent.**
Collection Performance = 30, Outstanding Exposure = 75, Portfolio Customer Risk Levels = 70.
`BusinessHealthScore = (30×0.45) + (75×0.20) + (70×0.35) = 13.5 + 15 + 24.5 = 53 → Needs Attention by the raw weighted average.`
But Collection Performance (30) has fallen to or below the Critical Floor (exact value pending Formula Calibration — assume, illustratively, a floor of 30 for this example): the Guardrail triggers.
`Final Score = MIN(53, GuardrailCeiling=49) = 49`, **Final Status = At Risk** — even though the raw weighted average alone would have read "Needs Attention." This is exactly the Guardrail's purpose: one severely failing dimension cannot be diluted away by two mediocre-but-acceptable ones.

**Example C — insufficient historical activity.**
A brand-new tenant with 1 completed Debt Cycle, below the (pending) minimum. Outstanding Exposure cannot be normalized against a baseline that doesn't exist yet. The entire card displays the Neutral Baseline empty state (§9) — no score, no status band, no gauge percentage.

## 16. Acceptance Criteria

For Sprint 17B implementation to be considered correct against this specification:

1. Given current values for all 3 inputs and Sufficient Historical Activity met, the Business Health Score equals the exact weighted average in §4, rounded to the nearest integer.
2. The Guardrail fires if and only if at least one of the 3 normalized inputs is at or below the (calibrated) Critical Floor — never on any combination of otherwise-acceptable values.
3. A triggered Guardrail always forces Final Status to At Risk and caps Final Score at the Guardrail Ceiling (the live upper bound of the At Risk band) — never a partial/graduated adjustment.
4. Final Score is always an integer in [0, 100]; Final Status is always exactly one of Healthy / Needs Attention / At Risk.
5. Before Sufficient Historical Activity is met, the API/UI returns the Neutral Baseline state, never a computed score.
6. Two calls with identical underlying data always return an identical score and status (determinism) — no randomness, caching drift, or hidden state.
7. Changing one input (e.g., one customer's Risk Level changing) and recomputing produces a score that reflects that change fully, with no dependency on calculation order relative to other inputs.

## 17. Known Limitations

Carried forward, unchanged, from the frozen Formula Specification:
- **Critical Floor's numeric value** is not set — deferred to post-implementation Formula Calibration.
- **DD-032** (Recovery Rate's own exact formula) remains an open SRS item; Business Health consumes whatever DD-032 eventually resolves to, unchanged.
- **Exact minimum completed-Debt-Cycle count** for Sufficient Historical Activity is not yet fixed.

New, raised while writing this document:
- **"On-Time Payments" and "Stable Customer Portfolio"** (§7) currently have no home in the 3-input model — Pending Product Owner Decision, recommended resolution: leave both out of the scored composite (see §7 for full trade-offs).
- **Read-time aggregation cost at scale.** Because Business Health recomputes fully on every Dashboard load (§13) rather than caching or incrementally maintaining a stored value, a tenant with a very large customer/debt volume will do proportionally more aggregation work per Dashboard view. No caching or background-recomputation mechanism is introduced here, consistent with the standing "no queue, no background worker" architecture — this is an accepted, documented trade-off, not a defect, but worth monitoring once real usage data exists.

## 18. Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-31 | Initial standalone Business Health Engine specification (Sprint 17A), written retroactively in the same style as `Risk_Level_Engine_v1.0.md` to give the already-frozen Business Health architecture (`Business_Health_Formula_Specification_v1.0.md` §1) its own standalone document. A direct conflict between the Sprint 17A brief (5 Health Bands, a broad factor-list model) and the already-frozen 3-band/3-input architecture was identified and resolved with the Product Owner *before* writing: build on the frozen v1.0, do not redesign it (see "Conflict Check" above). Two items from the brief's factor list ("On-Time Payments," "Stable Customer Portfolio") had no home in the frozen 3-input model and are recorded as Pending Product Owner Decision (§7) rather than silently resolved. No PHP, Laravel, Flutter, migrations, services, tests, controllers, models, API endpoints, or database changes were made — documentation only. | Claude |

---

**Documentation-only sprint. No implementation code, migrations, services, tests, controllers, models, or API endpoints were written. Awaiting Product Owner approval — including resolution of the two Pending items in §7 — before Sprint 17B (implementation) may begin.**
