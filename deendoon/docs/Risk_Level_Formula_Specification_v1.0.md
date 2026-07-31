# Risk Level Formula Specification v1.0

# Module Information

Module Name: Risk Level Engine — Formula Design
Version: v1.0
Status: DRAFT — Pending Product Owner Approval
Owner: Product Owner
Dependencies: Risk Level Engine architecture (`Risk_Level_Engine_v1.0.md`, Approved/Frozen); consumed by Business Health (`Business_Health_Formula_Specification_v1.0.md`, Health Contribution Weights); System Settings (FR-069, `system_settings` table) for the Long Outstanding Debt threshold
Related Documents: `docs/00_PROJECT_GOVERNANCE.md`; `SRS/03_Functional_Requirements.md` (FR-027, FR-069); `SRS/04_Business_Rules.md` (BRL-006, BRL-028, DD-024); `SRS/06_Database_Design.md` §6.8 (`system_settings`); `deendoon/docs/Risk_Level_Engine_v1.0.md` §7 ("What Remains — Formula Design")
Last Updated: 2026-07-31
Next Planned Work: Backend implementation (Sprint 2 technical design already produced); post-launch Formula Calibration if real data shows the proposed point values or thresholds need adjustment; DD-024 resolution to reactivate Collection Case Closure scoring

---

**Date:** 2026-07-31
**Status:** DRAFT — Pending Product Owner Approval. This document completes the one item `Risk_Level_Engine_v1.0.md` explicitly left open (§7, Formula Design). Everything below is a **proposal**, presented as a single, complete, internally-consistent specification rather than a decision tree — ready for approval or amendment, not yet implemented.
**Author:** Business Analyst / Solution Architect (Claude)
**Approved By:** Pending
**Scope:** Defines exact point values for every Primary and Secondary event, the combination rule, the Low/Medium/High thresholds, and the behavioral guarantees (boundedness, same-day recalculation, lazy time-based evaluation, oscillation resistance) required before this can be implemented.

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-31 | Initial complete Formula Specification, produced per Product Owner direction to skip decision-by-decision facilitation and deliver a finished, ready-to-approve proposal (Sprint 2A). | Claude |
| 1.0 (revised) | 2026-07-31 | **Three Product Owner revisions applied pre-approval.** (1) Repeated Missed Commitments changed from a lifetime broken-promise count to a rolling 12-month window, continuously re-evaluated from source — no permanent penalty stored. (2) Long Outstanding Debt's 90-day threshold changed from hardcoded to a configurable System Setting (`system_settings.long_outstanding_debt_days`, default 90) — a new column, not yet a pre-existing setting. (3) Collection Case Successfully Closed's interim "−5 for any closure" rule withdrawn — this event now has no scoring effect at all until DD-024 is resolved. Architecture, all other point values, the Secondary Cap, and the thresholds in §3 are unchanged. | Claude |

---

## 1. Scoring Scale

**Risk Score: an integer from 0 to 100.**

- **0** = no risk indicators present.
- **100** = maximum risk indicators present.
- Higher score = more risk. This is the literal, plain-English reading of "Risk Increase" (adds points) and "Risk Reduction" (subtracts points) — chosen deliberately over an inverted "health score" to satisfy the "simple to understand" requirement: no mental inversion is ever needed when reading an event's effect.

This is an internal calculation value only. The customer-facing and API-facing value remains exactly the approved three-label output (Low / Medium / High) — see §3. The numeric score is never itself exposed as a "risk percentage" anywhere; that framing belongs to Business Health, not to this engine.

---

## 2. Event Scoring

### 2.1 Primary Events (customer behavior) — the dominant signal, uncapped

| Event | Points | Trigger condition |
|---|---|---|
| **Broken Promise to Pay** | **+15** per occurrence | Fires once, at the moment a `promises_to_pay` row transitions to `broken` (per-promise, not per-debt) |
| **Repeated Missed Commitments** | **+20**, applies while condition holds | Applies whenever the customer has **3 or more Broken Promise to Pay events within the trailing 12 months** (`promises_to_pay.resolved_at >= today − 12 months`, `status = 'broken'`). Re-evaluated fresh from source on every recalculation — no permanent penalty is stored. If enough time passes that older broken promises age out of the 12-month window and the count drops below 3, the +20 stops applying at the very next recalculation. This is a rolling-window pattern check layered on top of the individual Broken Promise points already accrued (§2.1), not a repeating multiplier, and it deliberately keeps Risk Level reflecting **current** behavior rather than lifetime history |
| **Long Outstanding Debt** | **+12** per qualifying debt | A debt where `remaining_balance > 0` and `due_date` is more than `system_settings.long_outstanding_debt_days` days in the past — a per-tenant configurable value (default **90**; see §8). Evaluated lazily (§7) — recomputed fresh every time the customer's debts are read, not stored as a standing penalty |
| **Fulfilled Promise to Pay** | **−10** per occurrence | Fires once, at the moment a `promises_to_pay` row transitions to `fulfilled` |
| **Debt Recovered / Paid in Full** | **−20** per debt | Fires once, at the moment a `debts` row transitions to `debt_status = 'paid'` |
| **Sustained Positive Repayment Behavior** | **−15**, applies while condition holds | Applies whenever the customer's **3 most recently resolved** promises (fulfilled or broken, ordered by `resolved_at`) are **all fulfilled** — an unbroken streak of 3, not a lifetime count. Re-evaluated fresh from source on every recalculation — no permanent bonus is stored; it stops applying the moment a broken promise breaks the streak |

**Why the asymmetry (breaking costs more than keeping helps):** a broken commitment is weighted 1.5× its fulfilled counterpart (15 vs. 10), and a fully recovered debt is weighted exactly twice a single fulfilled promise (20 vs. 10) — a debt being paid off is a materially stronger positive signal than one promise being kept. This is a deliberate, standard credit-risk design choice ("trust is harder to earn back than to lose") and is also what prevents simple alternating behavior from oscillating the score evenly around a boundary (see §9).

### 2.2 Secondary Events (workflow/escalation) — confirmation-only, capped

| Event | Points | Trigger condition |
|---|---|---|
| **Recovery Stage Advancement** | **+3** per advancement | Fires once per stage increase (`RecoveryStageService::advanceTo()`) |
| **Collection Case Created** | **+5** per case | Fires once, at case escalation |
| **Professional Collection Request Submitted** | **+5** per request | Fires once, at submission |
| **Collection Case Successfully Closed** | **No effect (reserved)** | See explanation below — Product Owner decision, 2026-07-31 |
| **Professional Collection Request Successfully Completed** | **−5** per request | Fires once, when a Request closes with a `recovered` outcome specifically (not a generic `closed` outcome) |

**Collection Case closure currently has no effect on Risk Level.** `collection_cases.closure_outcome` has no fixed, SRS-approved value set — `04_Business_Rules.md` DD-024 remains open — so there is no approved way to distinguish a genuinely successful closure from any other outcome. Rather than approximate this with an interim rule (as an earlier draft of this specification proposed), the Product Owner has directed that **no score adjustment of any kind occurs when a Collection Case closes**, in either direction, until DD-024 is formally resolved. This event is **reserved for a future revision** of this specification once DD-024 defines an approved outcome value set — at that point, whichever outcome(s) DD-024 designates as successful can be wired to a Reduction contribution without any other part of this formula changing.

**Secondary Cap — this is what makes "Primary always outweighs Secondary" a mechanical guarantee, not just an intention:**

> The sum of all Secondary event contributions, in any single recalculation, is clamped to the range **[−15, +15]** before being added to the Primary subtotal.

With band widths of 34 points each (§3), a fully-maxed Secondary contribution (±15) can never by itself move a customer across more than a fraction of one band boundary — it can nudge a score within a band, or tip an already-borderline Primary-driven score, but it can never independently manufacture a Low→High or High→Low swing. Secondary events are advisory pressure, never the deciding factor.

---

## 3. Final Thresholds

| Score Range | Label |
|---|---|
| 0–33 | **Low Risk** |
| 34–66 | **Medium Risk** |
| 67–100 | **High Risk** |

Even thirds — the simplest possible split, with no asymmetric carve-out, matching the approved semantics directly: a customer needs to accumulate a genuinely substantial amount of negative signal (more than two Broken Promises' worth, or one Long Outstanding Debt plus a couple of lesser signals) before crossing out of Low, and needs to clear that same substantial bar again before reaching High.

---

## 4. How Multiple Events Combine

Pure linear addition — no multiplicative interactions, no conditional rules between event types. This is deliberate: multiplicative or conditional scoring is harder to test, harder to explain to a business owner, and not justified by anything in the approved SRS.

```
PrimarySubtotal   = sum of every applicable Primary event's points (§2.1)
SecondarySubtotal = clamp( sum of every applicable Secondary event's points (§2.2), −15, +15 )
RawScore          = PrimarySubtotal + SecondarySubtotal
FinalScore        = clamp( RawScore, 0, 100 )
FinalLabel        = band lookup on FinalScore (§3)
```

Every event type present for a customer at calculation time contributes independently and simultaneously — there is no ordering dependency and no "first event wins" rule, because the score is recomputed fully from source every time (§7), never incremented step-by-step.

---

## 5. Can the Score Go Below Zero?

No. `FinalScore = clamp(RawScore, 0, 100)` — a customer with an overwhelming amount of positive history (many recovered debts, long fulfillment streaks) floors at **0**, not a negative number. A negative score would have no meaning against the approved 0–100 scale and no corresponding label.

---

## 6. Is There a Maximum Score?

Yes. The same clamp caps the score at **100**. A customer cannot become "more than maximally risky" — 100 is High Risk regardless of how many additional Broken Promises or Long Outstanding Debts accumulate beyond that point. This also means the score is always a well-defined integer in [0, 100], with no unbounded growth to guard against elsewhere (in storage, in display, or in Business Health's own consumption of the Low/Medium/High label).

---

## 7. Recalculation With Multiple Events on the Same Day

Because the score is **always recomputed from source, in full, on every call** — never incremented or decremented — the order and timing of same-day events cannot cause double-counting, missed events, or drift. If a customer has a Promise break in the morning and a Debt get fully paid off in the afternoon, `RiskLevelService::recalculate()` runs once after each write (per Sprint 2's technical design), and the **second** run's fresh computation already reflects **both** events, correctly, regardless of which happened first. This is the same guarantee `CustomerBalanceService::recalculate()` already relies on for Outstanding Balance, for the identical reason: recompute-from-source eliminates order-dependency by construction.

---

## 8. Time-Based Events Without Cron Jobs

**Long Outstanding Debt** is the one event with no discrete triggering write — its truth changes purely because time has passed. Per the Sprint 2 technical design and the standing architectural decision in `docs/Performance_Architecture.md` (no queue, no scheduler, no background worker), this is evaluated **lazily, on access** — the exact pattern already established for Promise-to-Pay "broken" detection (`PromiseToPayService::refreshBrokenPromises()`).

Concretely: `RiskLevelService::recalculate()` is invoked wherever a customer's data is actually read for display — at minimum, `DebtController::index()`/`show()` (extending the existing lazy-check call sites) **and** `CustomerController::index()`/`show()` (a new call site, added specifically so Risk Level is fresh whenever a Customer profile is viewed, not only when Debts are separately browsed).

**Threshold is configurable, not hardcoded.** The day-count used for this check is read from `system_settings.long_outstanding_debt_days` (per-tenant, matching the existing `professional_collection_threshold_days` column's shape and purpose on the same table, FR-069) — **not** a fixed `90` in code. A tenant administrator may configure 30, 60, 90, or any other business-appropriate value; a new installation ships with the default (**90**) already populated, so no configuration step is required for the threshold to work correctly on day one. This is a genuinely new column — it does not exist on `system_settings` today — added via migration as part of implementation (not specified further here, per instruction to produce a specification only).

Because recalculation is a pure recompute-from-source function (§4, §7), evaluating it lazily produces **identical correctness** to a real-time trigger — the only practical consequence is that a newly-crossed threshold may not be reflected in `customers.risk_level` until the next time that customer is actually accessed through an endpoint that performs the check. This is the same accepted trade-off already approved for broken-promise detection, not a new one. Changing the threshold value itself takes effect immediately on the next recalculation for every customer — there is no migration or backfill step tied to changing the setting, since nothing is cached from it.

---

## 9. Avoiding Oscillation (High → Medium → High)

Three independent design choices, already present above, combine to make rapid flapping across a boundary structurally unlikely rather than merely hoped-against:

1. **Secondary events are capped at ±15** (§2.2) — on their own, workflow/escalation noise can never cross a 34-point band boundary. Any real boundary crossing requires genuine Primary-level behavior change.
2. **Deliberate asymmetry** (§2.1) — breaking a promise (+15) costs more than fulfilling one recovers (−10), and a debt recovery (−20) is worth twice a single fulfillment. A customer alternating between one broken and one fulfilled promise does **not** net to zero and ping-pong around a boundary — it trends upward (worse) over repeated cycles, which is the behaviorally correct outcome, not a defect to suppress.
3. **Every transition is event-caused, never noise-caused** — because there is no periodic recalculation tick (§8), the score cannot drift or flap without a real, individually auditable event (a broken promise, a payment, a case closure) having actually occurred. Every label change has exactly one traceable cause in the Audit Trail.
4. **The rolling-window pattern penalties age off gradually, not abruptly** (§2.1) — Repeated Missed Commitments and Sustained Positive Repayment Behavior both fade out on their own schedule (12 months / streak-broken respectively) as a natural consequence of aging data, rather than being permanently stuck on or off. A customer who breaks the 3-in-12-months threshold once and then improves does not carry that +20 forever — it lifts on its own as the old broken promises age out, smoothing the score's trajectory rather than holding it artificially high or letting it snap back suddenly.

**What this design deliberately does not add:** a hysteresis band (different up/down thresholds) or a minimum-dwell-time rule before a label can change again. Either would directly work against the "simple to understand, easy to test" requirement, and nothing in the approved SRS asks for one. If real production data after launch shows customers genuinely flapping across a boundary from legitimate, repeated, closely-timed events, a hysteresis adjustment can be introduced later as a **Formula Calibration** — the same category of post-launch, non-architectural adjustment already established for Business Health's Critical Floor — without redesigning this specification.

---

## 10. Design Goals — How This Specification Meets Them

| Goal | How it's met |
|---|---|
| **Deterministic** | Every input is a plain count or a fixed lookup against current database state; no randomness, no ML (BC-007's own "no AI/ML" principle, already applied to Credit Score, is followed identically here) |
| **Simple to understand** | One flat point value per event, pure addition, one clamp, three even bands — explainable to a business owner in one sentence per row of §2 |
| **Easy to test** | Recompute-from-source means every test sets up database state directly and asserts the resulting score/label — no mocking of "previous state," no ordering dependencies (§7) |
| **Compatible with the frozen SRS** | Matches FR-027 (deterministic, event-driven, no manual override), BRL-006 (independent from Credit Score/Customer Status/Debt Status — nothing here reads or writes those fields), BRL-028 (Low/Medium/High + semantics), and `Risk_Level_Engine_v1.0.md`'s approved Primary/Secondary structure and precedence rule |
| **Suitable for SMEs** | No configuration is required to get correct behavior — the one configurable value (`system_settings.long_outstanding_debt_days`, §8) ships with a sensible default (90) already populated, so a new tenant needs zero setup. Every other event's point value is fixed and non-configurable. No concept a non-technical business owner would need explained beyond "this is what happened, this is what it's worth" |
| **Scalable for future versions** | New event types can be added later as additional rows in §2 without restructuring §4's combination rule; point values themselves can be revisited via Formula Calibration (§9) without reopening the architecture |

---

## 11. Explicitly Not Covered

- Collection Case Successfully Closed (§2.2) has **no effect on Risk Level in this version of the specification** — the DD-024 closure-outcome ambiguity remains unresolved, so no score adjustment is defined for this event. This is reserved for a future revision of this specification once DD-024 defines an approved outcome value set.
- Any change to Credit Score, Business Health's own formula, or any other module.
- Implementation code, migrations, or service classes — this is a specification only, per instruction.
