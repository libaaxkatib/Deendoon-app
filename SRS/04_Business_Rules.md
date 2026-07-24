# 04. Business Rules

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-04 |
| **Document Title** | Business Rules |
| **Version** | 1.3 |
| **Status** | Reopened — Pending Re-Approval |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Pending |
| **Last Updated** | 2026-07-24 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened v1.3) · `02_Business_Requirements.md` (Reopened v1.3) · `03_Functional_Requirements.md` (Module 7 reopened, v1.7) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: 70 Business Rules (BRL-007–BRL-076) across 11 sections, 4 state transition matrices, consolidated calculation/validation rules, configuration policy, consistency validation, and Deferred Decisions register. | Claude |
| 1.0 | 2026-07-24 | Correction pass: removed 8 out-of-scope Deferred Decisions (former DD-020 Refund, DD-029 External Collection Agencies, DD-030 Legal Escalation, DD-034 Watermarking, DD-035 Digital Signature, DD-037 Legal Notice Wording, DD-041 Export Size Limits, DD-047 Logo File Constraints) without replacement; renumbered remaining Deferred Decisions sequentially to DD-001–DD-041 and updated every internal cross-reference; trimmed BRL-044, BRL-052, BRL-058, BRL-062, BRL-073 to remove now-out-of-scope content and redirect jurisdiction (NFR/UI) where applicable; corrected BRL-031 so Recovery Stage transitions are driven only by approved business events, never by document generation; clarified BRL-012's Default Credit Limit reference to Module 12 System Preferences. No Functional Requirement, Business Requirement, or approved scope was changed; Business Rule numbering (BRL-xxx) is unchanged. | Claude |
| 1.1 | 2026-07-24 | **Reopened — intentional scope change.** Added Business Rules for Professional Collection Requests (hand-off to Deendoon's own recovery team): BRL-078–BRL-082, a new "Professional Collection Request Status" state transition matrix, and Deferred Decisions DD-042–DD-046. Amended BRL-052 to remove the "external collection agencies are outside Version 1 scope" clause (superseded — this is precisely what was just approved) while explicitly preserving its "legal escalation remains outside Version 1 scope" clause, which this reopening does not touch. No other Business Rule was altered. | Claude |
| 1.2 | 2026-07-24 | **Correction to 1.1.** Removed the invented "Deendoon Recovery Specialist" actor from BRL-079 and the Professional Collection Request Status transition matrix — all transitions are now attributed to the **Deendoon Super Admin**, the already-approved Deendoon Platform Administrator actor, via the already-approved Super Admin Web Panel. Removed the now-resolved former DD-044 ("Deendoon-side actor/permission model") entirely, without replacement, and renumbered DD-045–DD-047 to DD-044–DD-046, updating every cross-reference in BRL-080/081/082 and the Deferred Decisions table. No other Business Rule was altered. | Claude |
| 1.3 | 2026-07-24 | Clarified, in BRL-079's Rule Statement and the Professional Collection Request Status transition matrix note, that "Assigned" means the Deendoon Super Admin has accepted ownership of the Request and started handling it — not assignment to another system user, role, or team. Any coordination with other Deendoon staff is manual and outside the system. | Claude |

---

## Document Purpose

This document defines the Business Rules governing already-approved Version 1 functionality: business policies, validation rules, decision logic, state transition rules, calculation rules, and configuration rules. It clarifies **how** approved behavior resolves in specific cases — it does not introduce functionality, expand scope, redesign workflows, or replace `03_Functional_Requirements.md`.

This document does **not** define UI design, API design, database schema, technical architecture, or security implementation — those belong to `05_UI_UX_Specification.md`, `07_API_Design.md`, `06_Database_Design.md`, and `08_Security_and_RBAC.md` respectively.

**Numbering continuity:** `02_Business_Requirements.md` §2.8 already established BRL-001–BRL-006 as high-level business rules. This document continues that sequence from **BRL-007** rather than restarting, to preserve a single, non-colliding rule-ID space across the SRS.

Where the approved SRS (Documents 01–03) does not contain sufficient information to safely define a rule, this document does not invent business behavior — it records the gap in the **Deferred Decisions** register instead.

---

## 0. Inherited Business Rules (from `02_Business_Requirements.md`)

These six rules are frozen and restated here for reference only; they are not modified.

| ID | Rule |
|---|---|
| BRL-001 | Credit limit checks are advisory; the system must never prevent a transaction from being recorded solely due to a credit limit breach. |
| BRL-002 | Recovery Stage is normally system-determined; manual override requires a recorded reason and is restricted to authorized roles. |
| BRL-003 | Every override, archive action, and status change must be attributable to a specific user, timestamp, and reason where applicable. |
| BRL-004 | Archived records are excluded from default operational views but are never permanently removed, and remain subject to role-based visibility in search and reporting. |
| BRL-005 | Duplicate customer detection is advisory; it must never prevent a new customer record from being created once the user confirms it is not a duplicate. |
| BRL-006 | Risk Level, Credit Score, Customer Status, and Debt Status are independently maintained; a change to one must not automatically overwrite another. |

---

## 1. Authentication Rules

### BRL-007 — Login Validation
- **Purpose:** Ensure only valid, active accounts with a resolvable role can authenticate.
- **Applies To:** All user roles; both Customer Mobile App and Super Admin Web Panel.
- **Rule Statement:** A login attempt succeeds only if (a) the submitted identifier matches an existing, non-Archived account, (b) the submitted credential validates against the stored credential, and (c) the account has at least one assigned Role.
- **Trigger:** User submits identifier + credential.
- **Result:** On success, a session is established and Role/permissions are resolved (BRL-072). On failure, no session is created and no Login event is recorded.
- **Exceptions:** Account Archived (rejected, BRL-008); no Role assigned (session may be created but all role-gated modules deny access per Module 1, FR-006, E1).
- **Related Functional Requirements:** FR-001, FR-006.

### BRL-008 — Account Status Gating
- **Purpose:** Prevent authentication against deactivated accounts.
- **Applies To:** All user accounts.
- **Rule Statement:** An Archived (deactivated) user account cannot authenticate under any circumstance. Archiving a user account does not terminate that user's already-active sessions instantaneously by rule of this section — session invalidation timing is a security-implementation concern deferred to `08_Security_and_RBAC.md`.
- **Trigger:** Login attempt against an Archived account.
- **Result:** Login rejected (Module 1, FR-001, A2).
- **Exceptions:** None.
- **Related Functional Requirements:** FR-001, FR-066 (Module 12).

### BRL-009 — Session Timeout & Sliding Expiration
- **Purpose:** Limit the exposure window of an idle authenticated session while preventing inconsistent partial records.
- **Applies To:** All authenticated sessions.
- **Rule Statement:** A session remains valid as long as authenticated activity occurs within the configured idle-timeout threshold (sliding window; exact threshold value defined in `09_Non_Functional_Requirements.md`). If a session expires while a user action is in progress and unsubmitted, that action is never committed; the user must re-authenticate before resubmitting it.
- **Trigger:** Idle duration exceeds the configured threshold.
- **Result:** Session invalidated; next request redirected to login (FR-001).
- **Exceptions:** None.
- **Related Functional Requirements:** FR-003.
- **Notes:** The numeric threshold itself is a Deferred Decision (see DD-001) — it is intentionally configurable, not hardcoded, per BC-003.

### BRL-010 — Password Reset Rules
- **Purpose:** Allow credential recovery without compromising account security.
- **Applies To:** All user accounts with a verified recovery contact.
- **Rule Statement:** A password reset token is time-limited and single-use. Once consumed (successfully or via expiry), it cannot be reused. The recovery channel used to deliver the token is platform-configured (email, SMS, or other supported channel), not user-selected per request.
- **Trigger:** User requests "Forgot Password."
- **Result:** New credential accepted only alongside a valid, unexpired, unused token.
- **Exceptions:** Expired/used token → rejected, new token must be requested (FR-004, A1). Undeliverable recovery contact → user directed to an administrator (FR-004, E1).
- **Related Functional Requirements:** FR-004.
- **Notes:** Exact token lifetime is a Deferred Decision (see DD-002).

### BRL-011 — Failed Login Handling
- **Purpose:** Deter credential-guessing without inventing an unapproved lockout policy in this document.
- **Applies To:** All login attempts.
- **Rule Statement:** Failed login attempts are tracked per account. The specific threshold, lockout duration, and rate-limiting mechanics are **not defined in this document** — Module 1 (FR-001, A1) explicitly routes this detail to `08_Security_and_RBAC.md`, and this rule preserves that routing rather than duplicating or pre-empting it.
- **Trigger:** Invalid credential submitted.
- **Result:** Attempt rejected; no session created; counter incremented (mechanics defined in 08).
- **Exceptions:** None defined here.
- **Related Functional Requirements:** FR-001.
- **Notes:** See `08_Security_and_RBAC.md` for the authoritative lockout policy.

---

## 2. Customer Rules

### BRL-012 — Customer Creation Defaults
- **Purpose:** Ensure every new Customer starts from a consistent, well-defined state.
- **Applies To:** Customer creation (manual and Import).
- **Rule Statement:** A newly created Customer defaults to Customer Status = **Active**. If no explicit Credit Limit is submitted, the Configured Company Default Credit Limit defined in Module 12 System Preferences is applied.
- **Trigger:** Customer Creation (FR-007) or Import row acceptance (FR-016).
- **Result:** Customer record exists with Status = Active and a resolved Credit Limit.
- **Exceptions:** Explicit Credit Limit submitted → overrides the tenant default (FR-007, A1).
- **Related Functional Requirements:** FR-007, FR-016.

### BRL-013 — Duplicate Detection Matching Logic
- **Purpose:** Surface likely duplicate Customers without blocking legitimate distinct records.
- **Applies To:** Customer Creation, Customer Update (identifying-field changes), Customer Import.
- **Rule Statement:** The system checks the submitted phone number and name against existing active Customers. A phone-number match against an existing active Customer is treated as a likely duplicate. The precise name-matching algorithm (exact vs. fuzzy/similarity matching) is not specified in the approved Feature Freeze.
- **Trigger:** New Customer submission or Import row containing phone/name.
- **Result:** Likely-duplicate match → "This customer may already exist" prompt (Open Existing / Continue Anyway). No match → proceeds without interruption.
- **Exceptions:** Never blocks record creation (BRL-005).
- **Related Functional Requirements:** FR-007, FR-009, FR-014, FR-016.
- **Notes:** Exact name-matching algorithm/sensitivity is a Deferred Decision (see DD-003).

### BRL-014 — Customer Status Value Definitions & Transition Freedom
- **Purpose:** Give operational meaning to the seven approved Customer Status values, since Module 2 (FR-012) deferred their meaning to this document.
- **Applies To:** Customer Status field.
- **Rule Statement:**
  | Value | Meaning |
  |---|---|
  | Active | Normal, ongoing relationship; no notable risk or collection activity. |
  | Good Standing | Consistently reliable payment history. |
  | Late Payer | Customer has a pattern of late payments. |
  | High Risk | Customer's payment behavior indicates elevated risk of non-payment. |
  | In Collection | Customer currently has one or more Debts in Professional Collection (Module 7). |
  | Recovered | Previously at-risk customer whose debts have since been recovered. |
  | Blocked | Business has ceased extending further credit/service to this customer. |

  Because Customer Status is manually managed (Module 2, Design Clarification — no automation was approved for this field), an authorized user may set **any** value at **any** time; there is no restricted transition graph. This is the conservative, permissive default consistent with the product principle that the system guides rather than blocks.
- **Trigger:** Authorized user selects a new Customer Status (FR-012).
- **Result:** Status updated; Status Changed event recorded.
- **Exceptions:** Only the seven listed values are valid.
- **Related Functional Requirements:** FR-012.
- **Notes:** The value *meanings* above are a clarification produced by this document, consistent with the approved value list; they do not add new values or change approved scope.

### BRL-015 — Customer Archive Eligibility
- **Purpose:** Determine whether a Customer with outstanding, unresolved Debts may be archived.
- **Applies To:** Customer Archive (FR-010).
- **Rule Statement:** **Not resolved in this document.** The approved Feature Freeze and Business Requirements do not state whether archiving is permitted, blocked, or merely warned when unresolved Debts exist.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-010.
- **Notes:** See DD-004. Until resolved, FR-010's Main Flow step 2 ("evaluates any archive-eligibility conditions") has no defined condition to evaluate — implementation should treat archiving as unconditionally permitted only after this decision is confirmed.

### BRL-016 — Customer Restore Mechanics
- **Purpose:** Define the mechanical effect of restoring an archived Customer.
- **Applies To:** Customer Restore (FR-011).
- **Rule Statement:** Restoring a Customer reverses exactly the effect of Archive: the record re-enters default operational lists/dashboards with its Customer Status, Credit Profile, and history unchanged from the moment of archiving.
- **Trigger:** Authorized Restore action.
- **Result:** Customer active again; Restored event recorded.
- **Exceptions:** Customer not currently Archived → no-op (FR-011, E2).
- **Related Functional Requirements:** FR-011.

### BRL-017 — Remaining Credit Calculation
- **Purpose:** Define the formula for a Customer's Remaining Credit.
- **Applies To:** Customer Credit Profile (FR-013).
- **Rule Statement:** `Remaining Credit = Credit Limit − Outstanding Balance`. The result may be negative (indicating the Customer is over their limit); a negative value is displayed as-is, not clamped to zero, so that the Credit Limit Reached condition (Module 4, FR-028) and Aging/KPI reporting reflect the true exposure.
- **Trigger:** Any change to Credit Limit or Outstanding Balance.
- **Result:** Remaining Credit recalculated and displayed immediately.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-013, FR-036.
- **Notes:** Rounding: monetary values are calculated and displayed to 2 decimal places, standard round-half-up — a technical formalization necessary to remove calculation ambiguity, not a policy choice (see Calculation Rules, §Rounding).

### BRL-018 — Partial-Import Validation Failure Behavior
- **Purpose:** Determine what happens when a Customer Import batch contains some invalid rows.
- **Applies To:** Customer Import (FR-016, A2).
- **Rule Statement:** **Not resolved in this document.** Whether the system imports valid rows and reports the failed ones, or rejects the entire batch, is not specified in the approved Feature Freeze.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-016.
- **Notes:** See DD-005.

---

## 3. Debt Rules

### BRL-019 — Debt Creation Validation
- **Purpose:** Ensure only well-formed Debt records are created.
- **Applies To:** Debt Creation (FR-017).
- **Rule Statement:** A Debt requires a positive numeric amount and a valid due date, against a Customer that exists and is not Archived.
- **Trigger:** Debt Creation submission.
- **Result:** Valid submission → record created with Auto Numbering ID. Invalid → rejected with field-level errors (FR-017, E1).
- **Exceptions:** Referenced Customer Archived → rejected (FR-017, E3).
- **Related Functional Requirements:** FR-017.

### BRL-020 — Default Debt Status at Creation
- **Purpose:** Determine which Debt Status a new Debt starts in.
- **Applies To:** Debt Creation (FR-017).
- **Rule Statement:** **Not resolved in this document.** The Feature Freeze lists both "Draft" and "Pending" as valid values but never specifies which applies at creation.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-017, FR-021.
- **Notes:** See DD-006. The transition matrix below (BRL-021) presents both as possible starting points pending this decision.

### BRL-021 — Debt Status Transition Matrix
- **Purpose:** Define every valid Debt Status transition, per the requirement that state transitions be deterministic with no undefined transitions.
- **Applies To:** Debt Status (Module 3, FR-021; Module 6, FR-037).
- **Rule Statement:** See the consolidated matrix in **§ State Transition Rules** below. Summary: Draft/Pending → Overdue (due date passes, automatic); Draft/Pending/Overdue → Partial Paid (partial payment recorded, Module 6); Draft/Pending/Overdue/Partial Paid → Paid (cumulative payments complete the amount, Module 6); Draft/Pending/Overdue → Cancelled (manual, authorized role); Draft/Pending/Overdue/Partial Paid → Written Off (manual, authorized role). No other transitions are valid — in particular, Paid, Cancelled, and Written Off are terminal states in Version 1 (no defined path back to an open status).
- **Trigger:** Due date passage, payment recording, or manual authorized action.
- **Result:** Debt Status updated; Status Changed event recorded.
- **Exceptions:** Manually forcing "Paid" without a recorded payment is rejected (FR-021, E1) — Paid is reachable only via Module 6.
- **Related Functional Requirements:** FR-017, FR-021, FR-037.
- **Notes:** Which roles may apply the manual Cancelled/Written Off transitions is deferred to `08_Security_and_RBAC.md` (Module 3, Open Item #2), not this document.

### BRL-022 — Outstanding & Remaining Balance Calculation
- **Purpose:** Define Debt-level and Customer-level balance formulas.
- **Applies To:** Debt (Module 3), Customer (Module 2), Payment Tracking (Module 6).
- **Rule Statement:**
  - Debt Remaining Balance = `Debt Amount − Sum(Payments recorded against that Debt)`.
  - Customer Outstanding Balance = `Sum(Remaining Balance across all of the Customer's open Debts)` — "open" meaning not Paid, Cancelled, or Written Off (Archived Debts, if not in a terminal status, still count; see Notes).
- **Trigger:** Debt Creation (adds to Outstanding Balance) or Payment Recording (reduces it).
- **Result:** Both values recalculated immediately and reflected on the Customer Profile and Debt Details.
- **Exceptions:** None beyond Payment Recording's own exceptions (BRL-040, BRL-041).
- **Related Functional Requirements:** FR-013, FR-017, FR-036.
- **Notes:** Whether an Archived-but-not-terminal Debt continues to count toward Outstanding Balance is a Deferred Decision (see DD-007), since archiving and financial closure are conceptually distinct in this SRS. Rounding: 2 decimal places, round-half-up.

### BRL-023 — Credit Limit Validation at Debt Entry
- **Purpose:** Formalize the soft-warning threshold check.
- **Applies To:** Debt Creation (FR-018).
- **Rule Statement:** `If (Customer Outstanding Balance + New Debt Amount) > Customer Credit Limit`, display the Soft Warning with Continue Anyway / Cancel. This check is advisory only (BC-001) and is never a hard block.
- **Trigger:** Debt Creation submission.
- **Result:** Threshold exceeded → warning shown, user decides. Not exceeded → no warning.
- **Exceptions:** None; Cancel is the user's own choice, not a system block.
- **Related Functional Requirements:** FR-018.

### BRL-024 — Debt Archive/Restore Mechanics
- **Purpose:** Confirm no special eligibility gate applies to Debt Archive, unlike Customer Archive.
- **Applies To:** Debt Archive/Restore (FR-022, FR-023).
- **Rule Statement:** A Debt may be archived regardless of its current Debt Status or Recovery Stage — Module 3's approved Main Flow for FR-022 defines no eligibility precondition beyond the Debt existing and not already being Archived. Restore reverses Archive exactly, per the same pattern as BRL-016.
- **Trigger:** Authorized Archive/Restore action.
- **Result:** Debt excluded from / restored to default operational views; Archived/Restored event recorded.
- **Exceptions:** Already Archived (Archive) or not Archived (Restore) → no-op.
- **Related Functional Requirements:** FR-022, FR-023.

---

## 4. Credit & Risk Rules

### BRL-025 — Initial Credit Score
- **Purpose:** Determine the starting Credit Score for a Customer with no scoring history.
- **Applies To:** New Customers (Module 4, FR-026, A1).
- **Rule Statement:** **Not resolved in this document.** No baseline starting score was specified during product discovery.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-026.
- **Notes:** See DD-008.

### BRL-026 — Credit Score Event Catalog & Point Values
- **Purpose:** Define the point adjustment for each qualifying event.
- **Applies To:** Credit Score calculation (FR-026).
- **Rule Statement:** **Not formally resolved in this document.** Illustrative values were discussed during product discovery (Paid On Time, Late Payment, Broken Promise to Pay, Partial Payment, Long Outstanding Debt each carrying a point adjustment) but were never confirmed as approved Business Rules — Module 4 explicitly declined to hardcode them pending this document, and this document does not manufacture approval that was never given.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-026.
- **Notes:** See DD-009.

### BRL-027 — Credit Score Band Thresholds
- **Purpose:** Define the numeric ranges for Excellent/Good/Fair/Poor.
- **Applies To:** Credit Score display (FR-026).
- **Rule Statement:** **Not resolved in this document.** The band *names* are approved; the numeric ranges are not.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-026.
- **Notes:** See DD-009 (combined with BRL-026 — both are part of the same pending scoring-calibration decision).

### BRL-028 — Risk Level Value Set
- **Purpose:** Define the qualitative values a Risk Level may take.
- **Applies To:** Risk Level Assignment (FR-027).
- **Rule Statement:** **Not resolved in this document.** Risk Levels predates the Version 1 discovery conversation as a pre-existing feature; its specific values were never enumerated anywhere in the approved SRS.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-027.
- **Notes:** See DD-010.

### BRL-029 — Credit Limit Reached Notification Suppression
- **Purpose:** Prevent notification spam when a Customer's balance fluctuates around their limit.
- **Applies To:** Credit Limit Reached notification (FR-028).
- **Rule Statement:** A notification is generated once per qualifying "reached" event. **Not resolved:** whether a subsequent re-crossing of the threshold (drop below, then exceed again) generates a new notification, or whether some cooldown/suppression window applies.
- **Trigger:** N/A for the unresolved part — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-028.
- **Notes:** See DD-011.

---

## 5. Recovery Rules

### BRL-030 — Reminder Schedule & Timing
- **Purpose:** Define how automated reminders are scheduled.
- **Applies To:** Smart Daily Reminder (FR-029).
- **Rule Statement:** Reminder timing (how many days before/after due date each channel fires) is governed entirely by the tenant's configured Recovery Policy (Module 12, System Settings) — it is never hardcoded, per BC-003. The evaluation cycle checks all open Debts against this configured policy on a recurring basis.
- **Trigger:** Scheduled evaluation cycle.
- **Result:** Debts matching the configured timing receive a reminder via the configured channel.
- **Exceptions:** Delivery failure — see BRL-036.
- **Related Functional Requirements:** FR-029.
- **Notes:** The specific default timing values are configuration data (Module 12), not a Business Rule to hardcode here.

### BRL-031 — Recovery Stage Transition Matrix
- **Purpose:** Define the event-to-stage mapping for Recovery Stage automation, per the requirement for deterministic, fully-defined state transitions.
- **Applies To:** Recovery Stage (Module 5, FR-032; Module 3, FR-025).
- **Rule Statement:** The approved Feature Freeze never phrased this as an explicit stage-automation table, but it did approve a specific Recovery Timeline sequence (Debt Created → WhatsApp Reminder → SMS Reminder → Phone Call → Promise to Pay → Payment → Professional Collection → Recovered). This document formalizes the six named stages against that sequence as follows — presented for confirmation, since it is a reasoned derivation rather than an explicitly pre-approved mapping:
  | Stage | Name | Entered When |
  |---|---|---|
  | 1 | Friendly Reminder | Debt created / first automated reminder sent |
  | 2 | Late Reminder | Debt becomes Overdue and a subsequent reminder is sent |
  | 3 | Phone Follow-up | A Call reminder is logged |
  | 4 | Final Notice | A Promise to Pay is broken |
  | 5 | Professional Collection | Debt is escalated to a Collection Case (Module 7) |
  | 6 | Recovered | Debt reaches Paid status (Module 6) |

  Recovery Stage transitions are driven only by the approved business events listed above. Document generation (Demand Letter, Receipt, Statement — Module 8) is a **consequence** of recovery activity, never a trigger of it: generating a document must never by itself advance Recovery Stage.
- **Trigger:** Any of the qualifying events in the right-hand column.
- **Result:** Recovery Stage advances to the mapped value; no transition occurs for events with no defined mapping, including document generation events.
- **Exceptions:** Manual override always available to authorized roles (BRL-002); this matrix governs automatic advancement only.
- **Related Functional Requirements:** FR-025, FR-032.
- **Notes:** The exact **timing thresholds** that trigger Stage 2 (how many days overdue) remain configuration data under BRL-030, not part of this mapping. See DD-012 for confirmation of this derived mapping itself.

### BRL-032 — Promise to Pay Fulfillment Determination
- **Purpose:** Define when a Promise to Pay is considered fulfilled vs. broken.
- **Applies To:** Promise to Pay (FR-031).
- **Rule Statement:** A Promise to Pay is **fulfilled** if a payment sufficient to close or reduce the Debt is recorded on or before the promised date. It is **broken** if the promised date passes with no qualifying payment recorded.
- **Trigger:** Promised date reached or passed; payment recorded.
- **Result:** Fulfilled → contributes positively to SM-008 (Promise Fulfillment Rate). Broken → emits a qualifying event to Credit Score (BRL-026, once resolved) and SM-008 negatively.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-031.

### BRL-033 — Promise to Pay Date Revision
- **Purpose:** Determine how revising a promised date is handled.
- **Applies To:** Promise to Pay (FR-031, A2).
- **Rule Statement:** **Not resolved in this document.** Whether revising a promised date replaces the existing promise or logs a broken-then-renewed promise is not specified.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-031.
- **Notes:** See DD-013.

### BRL-034 — Broken Promise Handling
- **Purpose:** Define the downstream effects of a broken promise.
- **Applies To:** Promise to Pay (FR-031); Credit Score (FR-026); Recovery Stage (FR-032).
- **Rule Statement:** A broken promise (BRL-032) triggers: (a) a qualifying negative Credit Score event (exact point value per BRL-026, pending), and (b) Recovery Stage advancement to Stage 4 — Final Notice (BRL-031).
- **Trigger:** Promised date passes with no qualifying payment.
- **Result:** Both downstream effects fire.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-031, FR-026, FR-032.

### BRL-035 — Escalation Eligibility
- **Purpose:** Define when a Debt becomes eligible for Professional Collection.
- **Applies To:** Collection Case Creation (Module 7, FR-040).
- **Rule Statement:** A Debt is automatically eligible once it reaches Recovery Stage 5 (BRL-031). **Not resolved:** whether an authorized user may manually escalate a Debt before Stage 5 is reached, and if so, under what authorization.
- **Trigger:** Stage 5 reached (resolved) / manual early escalation (unresolved).
- **Result:** Collection Case created (FR-040).
- **Exceptions:** N/A for the unresolved part.
- **Related Functional Requirements:** FR-032, FR-040.
- **Notes:** See DD-014.

### BRL-036 — Reminder Delivery Failure & Retry
- **Purpose:** Define behavior when an automated or manual reminder fails to deliver.
- **Applies To:** Automated reminders (FR-029), Manual reminders (FR-030).
- **Rule Statement:** **Not resolved in this document.** Retry count, backoff timing, and escalation-on-repeated-failure are not specified in the approved Feature Freeze.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** A failed delivery is always logged in Follow-up History regardless of retry policy.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-029, FR-030.
- **Notes:** See DD-015.

---

## 6. Payment Rules

### BRL-037 — Payment Validation
- **Purpose:** Ensure only well-formed payments are recorded.
- **Applies To:** Payment Recording (FR-034).
- **Rule Statement:** A payment requires a positive numeric amount and a valid date, recorded against a Debt that exists, is not Archived, and is not already Cancelled or Written Off.
- **Trigger:** Payment submission.
- **Result:** Valid → Payment record created. Invalid → rejected.
- **Exceptions:** See BRL-041 (payments against closed Debts).
- **Related Functional Requirements:** FR-034.

### BRL-038 — Payment Allocation (Single-Debt Scope)
- **Purpose:** Confirm the scope of a single payment.
- **Applies To:** Payment Recording (FR-034).
- **Rule Statement:** Every payment is recorded against exactly one Debt (BR-018, already approved). Version 1 does not support splitting one payment across multiple Debts or allocating one payment to a Customer's account in aggregate.
- **Trigger:** Payment submission.
- **Result:** Payment tied to a single, specific Debt.
- **Exceptions:** None — this is a resolved scope boundary, not an open item.
- **Related Functional Requirements:** FR-034.

### BRL-039 — Partial/Full Payment Status Effects
- **Purpose:** Define the Debt Status consequence of cumulative payments.
- **Applies To:** Payment Recording (FR-037).
- **Rule Statement:** `0 < Cumulative Payments < Debt Amount` → Debt Status = Partial Paid. `Cumulative Payments ≥ Debt Amount` → Debt Status = Paid.
- **Trigger:** Payment recorded.
- **Result:** Debt Status updated accordingly; Customer Outstanding Balance recalculated (BRL-022).
- **Exceptions:** Overpayment scenario (Cumulative Payments > Debt Amount) — see BRL-040.
- **Related Functional Requirements:** FR-037.

### BRL-040 — Overpayment Handling
- **Purpose:** Determine how a payment exceeding the remaining balance is treated.
- **Applies To:** Payment Recording (FR-034, E1).
- **Rule Statement:** **Not resolved in this document.** Whether an overpayment is rejected outright, capped at the remaining balance, or recorded as a credit against future debts is not specified.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-034, FR-037.
- **Notes:** See DD-016.

### BRL-041 — Payments Against Closed Debts
- **Purpose:** Determine whether a payment may be recorded against a Debt already Paid, Cancelled, or Written Off.
- **Applies To:** Payment Recording (FR-034, E4).
- **Rule Statement:** **Not resolved in this document.**
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-034.
- **Notes:** See DD-017.

### BRL-042 — Payment Correction, Reversal, and Deletion
- **Purpose:** Determine whether and how a recorded payment can be corrected.
- **Applies To:** Payment records (Module 6).
- **Rule Statement:** **Not resolved in this document.** Three related but distinct questions are all open: (a) can a payment be edited after recording; (b) can a payment be archived/removed, and if so, does it follow the same Archive/Restore pattern as Customer and Debt (BC-002), given Payment was not explicitly named alongside them in the approved Soft Delete/Archive scope; (c) does a distinct "reversal" action exist, separate from edit or delete.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-034, FR-035.
- **Notes:** See DD-018.

### BRL-043 — Payment Method Validation
- **Purpose:** Determine whether payment method is a controlled or free-text value.
- **Applies To:** Payment Recording (FR-034).
- **Rule Statement:** **Not resolved in this document.** Whether payment method is a fixed catalog (e.g., Cash, Bank Transfer, Mobile Money — managed via Module 12, Lookup & Reference Data) or a free-text reference field is not specified.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-034, FR-070 (Module 12).
- **Notes:** See DD-019.

### BRL-044 — Refund Behavior (Out of Scope)
- **Purpose:** Confirm that refund functionality is not part of Version 1.
- **Applies To:** Payment Tracking (Module 6).
- **Rule Statement:** Refund functionality is outside approved Version 1 scope. It is not referenced in `01_Project_Overview.md`, `02_Business_Requirements.md`, or `03_Functional_Requirements.md`.
- **Trigger:** N/A.
- **Result:** N/A — no refund capability exists in Version 1.
- **Exceptions:** None.
- **Related Functional Requirements:** None (no FR currently covers refunds).
- **Notes:** Not tracked as a Deferred Decision — any future refund capability would be a Version 2+ scope decision, not an unresolved Business Rule.

---

## 7. Collection Rules (including Professional Collection Requests)

### BRL-045 — Collection Case Creation Trigger
- **Purpose:** Confirm the entry condition for Collection Case creation.
- **Applies To:** Professional Collection (FR-040).
- **Rule Statement:** A Collection Case is created when a Debt reaches Recovery Stage 5 (BRL-031, BRL-035), referencing exactly one Debt.
- **Trigger:** Stage 5 reached, or authorized manual escalation (pending BRL-035).
- **Result:** Collection Case created with a unique `COL-000001` identifier.
- **Exceptions:** See BRL-048 (duplicate case prevention).
- **Related Functional Requirements:** FR-040.

### BRL-046 — Initial Collection Status
- **Purpose:** Determine the status a new Collection Case starts in.
- **Applies To:** Collection Case Creation (FR-040).
- **Rule Statement:** **Not resolved in this document.**
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-040.
- **Notes:** See DD-020.

### BRL-047 — Assignment Rules
- **Purpose:** Determine whether Collection Case assignment is automatic or always manual.
- **Applies To:** Collection Case Assignment (FR-041).
- **Rule Statement:** **Not resolved in this document.** Automatic assignment and collector workload balancing are not specified; only manual assignment is defined in Module 7 (FR-041).
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** Manual assignment (resolved): authorized user selects a Collection Officer; reassignment follows the same path.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-041.
- **Notes:** See DD-021 (auto-assignment) and DD-022 (reassignment notification policy).

### BRL-048 — Duplicate Collection Prevention
- **Purpose:** Prevent two open Collection Cases against the same Debt.
- **Applies To:** Collection Case Creation (FR-040, A1).
- **Rule Statement:** A Debt may have at most one **open** Collection Case at a time. **Not resolved:** whether a second escalation attempt is rejected outright or redirected to the existing case.
- **Trigger:** Escalation attempted against a Debt with an existing open case.
- **Result:** N/A for the unresolved part.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-040.
- **Notes:** See DD-023.

### BRL-049 — Collection Progression Mechanics
- **Purpose:** Define how a Collection Case accumulates activity.
- **Applies To:** Collection Activity Recording (FR-044).
- **Rule Statement:** Each recorded activity (call, notice, visit, consumed payment event) is appended to the Case's activity log with User, Timestamp, and details, and mirrored into the Debt's Follow-up History and Recovery Timeline without duplicating the underlying record (single source of truth remains the Collection Case for case-specific activity).
- **Trigger:** Activity recorded against an open case.
- **Result:** Activity logged; Case remains open.
- **Exceptions:** Case Closed → activity logging rejected (see BRL-051, reopening).
- **Related Functional Requirements:** FR-044.

### BRL-050 — Collection Closure & Outcome Value Set
- **Purpose:** Define what closing a Collection Case requires.
- **Applies To:** Collection Case Closure (FR-045).
- **Rule Statement:** Closure always requires a recorded outcome and never implies or creates a payment (already resolved, Module 7 architecture). **Not resolved:** the enumerated set of valid closure outcomes (e.g., Recovered, Unresolved, Written Off) — only "Recovered" was implied by the approved Recovery Timeline endpoint, not a full set.
- **Trigger:** Authorized user closes a case.
- **Result:** Case status = Closed with recorded outcome.
- **Exceptions:** Already-Closed case → no-op (FR-045, E2).
- **Related Functional Requirements:** FR-045.
- **Notes:** See DD-024.

### BRL-051 — Collection Reopening
- **Purpose:** Determine whether a Closed Collection Case can be reopened.
- **Applies To:** Collection Case Update/Activity (FR-043, FR-044).
- **Rule Statement:** **Not resolved in this document.**
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-043, FR-044.
- **Notes:** See DD-025.

### BRL-052 — Abandoned Cases and Maximum Collection Duration
- **Purpose:** Consolidate two related, entirely unspecified collection-governance questions.
- **Applies To:** Professional Collection (Module 7).
- **Rule Statement:** **Not resolved in this document**, for both: (a) handling of Collection Cases with no activity over an extended period; (b) any maximum allowable collection duration. A distinct legal-escalation process remains outside approved Version 1 scope — Version 1 defines Legal Notice only as a Demand Letter template (Module 8), with no Legal Workflow or Legal Case — and is not tracked as a Deferred Decision. **Superseded:** hand-off to an external party was previously noted here as out of scope; it is now an approved Version 1 capability — see Professional Collection Requests, BRL-078 through BRL-082.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-040 through FR-046 (general).
- **Notes:** See DD-026 and DD-027.

### BRL-078 — Professional Collection Request Submission Eligibility
- **Purpose:** Define when a Collection Case may be submitted to Deendoon's recovery team.
- **Applies To:** Professional Collection Request Submission (FR-072).
- **Rule Statement:** A Collection Case may be submitted as a Professional Collection Request only while it is Open and has no other active Request already pending against it (mirrors BRL-048's duplicate-prevention pattern). Submission does not change the Collection Case's own status (Open/Closed, BRL-050) — the Case and the Request are tracked independently.
- **Trigger:** User selects "Submit Case to Deendoon" on an open Collection Case.
- **Result:** Request created with status Submitted.
- **Exceptions:** Case Closed → submission rejected (FR-072, E2). Case already has an active Request → **not resolved**, see DD-042.
- **Related Functional Requirements:** FR-072.
- **Notes:** See DD-042.

### BRL-079 — Professional Collection Request Status Transition Matrix
- **Purpose:** Govern how a Request moves between statuses.
- **Applies To:** Professional Collection Request Status Tracking (FR-073).
- **Rule Statement:** The approved status set is: Submitted, Under Review, Need More Information, Accepted, Assigned, In Progress, Recovered, Closed. Submitted → Under Review is the only entry transition. Need More Information ⇄ Under Review may cycle. Recovered and Closed are terminal. All transitions are performed by the Deendoon Super Admin — the already-approved Deendoon Platform Administrator actor, via the already-approved Deendoon Super Admin Web Panel. No new actor, role, or permission model is introduced; Version 1 has exactly two application interfaces and this capability lives entirely within the second one. **"Assigned" definition:** this status does not mean assignment to another system user, role, or team. It means the Deendoon Super Admin has accepted ownership of the Request and started handling it. Any coordination with other Deendoon staff happens manually, outside the system, and is not represented by additional users, roles, or dashboards. **Not resolved:** the complete permitted/forbidden transition matrix beyond this named sequence (e.g., whether Under Review can go directly to Closed without Accepted).
- **Trigger:** The Deendoon Super Admin actions a Request.
- **Result:** Status updated per the transition; tenant view (FR-074) reflects it without tenant action.
- **Exceptions:** Transition outside the approved sequence → rejected (FR-073, E1).
- **Related Functional Requirements:** FR-073, FR-076.
- **Notes:** See DD-043 (full matrix).

### BRL-080 — Professional Collection Request Conversation Rules
- **Purpose:** Govern messaging between the submitting business and the Deendoon Super Admin.
- **Applies To:** Professional Collection Request Conversation (FR-075).
- **Rule Statement:** Either party may post a message at any time while the Request is active (Submitted through In Progress). Every message is attributable (BRL-003: sender, timestamp, content) and immutable once posted — no edit or delete capability exists, consistent with the Audit Trail's own immutability principle (BRL-076). **Not resolved:** whether messaging remains available after a terminal outcome (Recovered/Closed).
- **Trigger:** Either party posts a message.
- **Result:** Message recorded; other party notified (Module 10, consumption-only).
- **Exceptions:** N/A for the resolved part.
- **Related Functional Requirements:** FR-075.
- **Notes:** See DD-044.

### BRL-081 — Professional Collection Request Numbering
- **Purpose:** Confirm the Auto Numbering format for Professional Collection Requests.
- **Applies To:** Professional Collection Request Submission (FR-072).
- **Rule Statement:** Extends BR-036 (previously five Auto-Numbered entities: Debt, Receipt, Demand Letter, Statement, Collection Case) to a sixth: Professional Collection Request. A `PCR-000001` format is proposed, consistent with the existing prefix-plus-sequential-digits convention (BRL-053), but is **not yet formally confirmed**.
- **Trigger:** Request created (FR-072).
- **Result:** Request assigned a unique identifier once the format is confirmed.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-072.
- **Notes:** See DD-045.

### BRL-082 — Relationship Between Request Closure and Collection Case Closure
- **Purpose:** Determine whether closing a Professional Collection Request affects the underlying Collection Case.
- **Applies To:** Professional Collection Request Outcome & Closure (FR-076); Collection Case Closure (FR-045).
- **Rule Statement:** **Not resolved in this document.** Following the same reasoning already established for Collection Case closure never implying a payment (BRL-050), this document does not assume that closing a Request automatically closes its linked Collection Case, or vice versa — that coupling (or its absence) must be an explicit decision, not a silent inference.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-045, FR-076.
- **Notes:** See DD-046.

---

## 8. Document Rules

### BRL-053 — Document Numbering
- **Purpose:** Confirm the Auto Numbering format for each document type.
- **Applies To:** Documents (Module 8).
- **Rule Statement:**
  | Document | Format | Scope |
  |---|---|---|
  | Receipt | `RCT-000001` | Sequential, unique per tenant |
  | Demand Letter (all 4 templates, incl. Legal Notice) | `DL-000001` | Sequential, unique per tenant; shared across templates |
  | Statement of Account | `ST-000001` | Sequential, unique per tenant |
- **Trigger:** Document generation (FR-047, FR-048, FR-049).
- **Result:** Each generated document receives the next sequential number in its series.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-047, FR-048, FR-049.
- **Notes:** Whether the format itself (prefix, digit count) is tenant-configurable is a Deferred Decision (see DD-028).

### BRL-054 — Branding Application
- **Purpose:** Ensure generated documents reflect current Company branding.
- **Applies To:** Receipt, Demand Letter, Statement generation.
- **Rule Statement:** Every generated document uses the Company Profile & Branding values (Module 12, FR-068) in effect **at the moment of generation**. Changing branding later does not retroactively alter already-generated documents (consistent with Document Immutability, BRL-057).
- **Trigger:** Document generation.
- **Result:** Document reflects current branding at generation time.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-047, FR-048, FR-049, FR-068.

### BRL-055 — Template Usage
- **Purpose:** Confirm how a Demand Letter template is selected.
- **Applies To:** Demand Letter Generation (FR-048).
- **Rule Statement:** The requesting user or module explicitly selects one of the four approved templates (First Reminder, Second Reminder, Final Demand, Legal Notice) at the point of generation. Version 1 does not automatically select a template based on Recovery Stage or any other condition — this is a resolved scope boundary (Module 8, FR-048 Main Flow already specifies explicit selection), not an open item.
- **Trigger:** Demand Letter generation request.
- **Result:** Document generated from the explicitly chosen template.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-048.

### BRL-056 — Document Regeneration
- **Purpose:** Determine whether and how a document can be regenerated.
- **Applies To:** Document History (FR-052).
- **Rule Statement:** **Not resolved in this document.** Whether regeneration is permitted, and if so, whether it creates a new numbered document or reuses the original number, is not specified.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-052.
- **Notes:** See DD-029.

### BRL-057 — Document Immutability
- **Purpose:** Protect generated documents as fixed, trustworthy records.
- **Applies To:** Receipt, Demand Letter, Statement.
- **Rule Statement:** Once generated, a document's content is fixed and is never edited in place. A correction requires regeneration (once BRL-056 is resolved), not modification of the existing artifact. No update capability is provided for any generated document.
- **Trigger:** N/A (a standing constraint, not an event).
- **Result:** Generated documents remain trustworthy, unaltered snapshots.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-047, FR-048, FR-049, FR-050, FR-051.

### BRL-058 — Document Retention and Template Customization
- **Purpose:** Consolidate related, unspecified document-governance questions that remain genuinely open.
- **Applies To:** Documents (Module 8).
- **Rule Statement:** **Not resolved in this document**: (a) document retention period; (b) the exact customizable-field constraints for Document Templates (Module 12, FR-069) — see also BRL-053, Notes, regarding numbering-format configurability. Watermarking and digital signature support were never approved and are outside Version 1 scope; Legal Notice wording is outside SRS scope entirely (a legal-review concern, not a Business Rule). None of these three are tracked as Deferred Decisions.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-051, FR-052, FR-069.
- **Notes:** See DD-030 and DD-031.

---

## 9. Reporting Rules

### BRL-059 — KPI Calculation Definitions
- **Purpose:** Formalize the computation of each Executive KPI Card.
- **Applies To:** Dashboard Summary (FR-053).
- **Rule Statement:**
  | KPI | Formula |
  |---|---|
  | Total Outstanding Amount | Sum of Remaining Balance across all open Debts (per BRL-022) in scope (tenant or system-wide). |
  | Total Collected (Period) | Sum of Payment amounts recorded within the selected period. |
  | Total Overdue Debts | Count (and/or value) of Debts with Debt Status = Overdue. |
  | Customers Over Credit Limit | Count of Customers where Outstanding Balance > Credit Limit (Remaining Credit is negative, BRL-017). |
  | Active Collection Cases | Count of Collection Cases not in Closed status. |
  | Recovery Rate | **Not resolved in this document** — see below. |
- **Trigger:** Dashboard load or period change.
- **Result:** KPI values computed and displayed.
- **Exceptions:** None for the five resolved KPIs.
- **Related Functional Requirements:** FR-053.
- **Notes:** **Recovery Rate** has at least two valid business definitions (e.g., Collected ÷ Debt Raised in the period, vs. Collected ÷ (Collected + Outstanding)) and was never specified precisely enough to pick one — see DD-032. **SM-007 (Average Days to Recover Debt)** and **SM-008 (Promise Fulfillment Rate)** formulas are likewise not precisely defined for edge cases (e.g., which date counts as "recovered") — see DD-033.

### BRL-060 — Aging Analysis Bucket Assignment
- **Purpose:** Formalize how a Debt is placed into an Aging bucket.
- **Applies To:** Aging Analysis (FR-054).
- **Rule Statement:** Bucket = days between the Debt's due date and the current date, using the Debt's **Remaining Balance** (not original amount) as the bucketed value, so partially paid Debts are represented at their true remaining exposure: Current (not yet due), 1–30, 31–60, 61–90, Over 90 days past due.
- **Trigger:** Aging Analysis view/refresh.
- **Result:** Every open Debt appears in exactly one bucket.
- **Exceptions:** Paid, Cancelled, Written Off Debts are excluded (zero remaining exposure or closed).
- **Related Functional Requirements:** FR-054.

### BRL-061 — Reporting Periods & Timezone
- **Purpose:** Define calendar boundaries for historical KPI periods and Aging/date groupings.
- **Applies To:** Dashboard (FR-053), Aging Analysis (FR-054), Calendar View (FR-062).
- **Rule Statement:** **Not resolved in this document.** Which timezone governs "day" boundaries (tenant-local vs. UTC vs. server time), and where week/month boundaries fall (e.g., week starting Sunday vs. Monday), are not specified.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-053, FR-054, FR-062.
- **Notes:** See DD-034.

### BRL-062 — Export Rules
- **Purpose:** Confirm export fidelity and formats.
- **Applies To:** Report Export (FR-057).
- **Rule Statement:** An export (PDF, Excel, or CSV) reflects exactly the data and filters currently applied on screen at the moment of export. No export-only calculation is introduced.
- **Trigger:** User selects Export.
- **Result:** File generated matching on-screen state.
- **Exceptions:** Export size limits are a Non-Functional Requirement, governed by `09_Non_Functional_Requirements.md` — not tracked as a Business Rule Deferred Decision.
- **Related Functional Requirements:** FR-057.

### BRL-063 — Report Consistency Principle
- **Purpose:** Prevent Reporting from becoming a second source of truth.
- **Applies To:** All of Module 9.
- **Rule Statement:** Every report and KPI reads current state from its owning module (Customer, Debt, Payment, Collection Case, Document) at query time. Reporting never stores an independent, divergent copy of business data, and never performs a calculation that duplicates or could conflict with a calculation already defined for the owning module (e.g., Remaining Credit is always BRL-017's formula, never a separately-maintained reporting value).
- **Trigger:** N/A (a standing architectural constraint).
- **Result:** Reports are always consistent with the current state of their source modules.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-053 through FR-057.

---

## 10. Notification Rules

### BRL-064 — Notification Creation (Consumption-Only)
- **Purpose:** Reaffirm the Notification Center's consumption-only nature at the rule level.
- **Applies To:** Notification Center (FR-058).
- **Rule Statement:** A Notification is created only as a direct, passive consequence of a qualifying event already generated by an owning module (Credit Limit Reached, Payment Received, Document Available, Collection Assignment, Reminder Sent, Promise to Pay Due). This module never originates, schedules, or invents an event of its own.
- **Trigger:** Qualifying event received from an owning module.
- **Result:** In-app Notification created, linked to the originating entity.
- **Exceptions:** User's role restricts visibility of the underlying entity → Notification not shown (FR-058, E1).
- **Related Functional Requirements:** FR-058.

### BRL-065 — Duplicate Notification Suppression
- **Purpose:** Prevent redundant repeated notifications for the same underlying condition.
- **Applies To:** Notification Center (FR-058).
- **Rule Statement:** **Not resolved in this document.** Inherits the same unresolved question as BRL-029 (Credit Limit Reached re-trigger) and extends it generally to other repeatable event types.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-058.
- **Notes:** See DD-011 (shared with BRL-029).

### BRL-066 — Read/Unread Mechanics
- **Purpose:** Define the read-state model.
- **Applies To:** Notification Read/Unread (FR-059).
- **Rule Statement:** Each Notification carries a binary Read/Unread flag, defaulting to Unread at creation. A user may mark an individual Notification Read, or mark all of their Notifications Read in one action. Marking Read never removes a Notification from History (FR-061).
- **Trigger:** User views or explicitly marks a Notification.
- **Result:** Flag updated; Notification remains in history regardless of state.
- **Exceptions:** None.
- **Related Functional Requirements:** FR-059, FR-061.

### BRL-067 — Notification History & Expiry
- **Purpose:** Determine how long Notification History is retained.
- **Applies To:** Notification History (FR-061).
- **Rule Statement:** **Not resolved in this document.** Whether Notifications ever auto-expire/archive out of History is not specified; absent a decision, History is retained indefinitely by default.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-061.
- **Notes:** See DD-035.

### BRL-068 — Calendar Aggregation Rules
- **Purpose:** Define what the Calendar View displays and from where.
- **Applies To:** Calendar View (FR-062).
- **Rule Statement:** The Calendar aggregates, read-only: Debt Due Dates (Module 3), Promise to Pay Dates and Call Reminders (Module 5), and Collection Appointments (Module 7) where recorded. It never owns or writes any of this data.
- **Trigger:** User opens Calendar View.
- **Result:** All qualifying dated items within the requested period are displayed.
- **Exceptions:** **Not resolved:** Collection Appointments are not a distinct schedulable entity in Module 7 (only Collection Case, Assignment, and Activity exist) — exactly how a future-dated Collection Activity becomes a Calendar entry is undefined.
- **Related Functional Requirements:** FR-062.
- **Notes:** See DD-036.

---

## 11. Administration Rules

### BRL-069 — User Administration & Activation
- **Purpose:** Define the mechanics of creating and activating a user account.
- **Applies To:** User Administration (FR-066), Role Assignment (FR-067).
- **Rule Statement:** A new user account is created by an authorized administrator. **Not resolved:** the exact initial-credential mechanism (administrator-set password vs. self-service invitation link) and whether a Role must be assigned before the account is usable, or can be created role-less and activated later.
- **Trigger:** Administrator creates a user account.
- **Result:** User record created; account use is gated by Role assignment regardless of the unresolved mechanism (Module 1, FR-006, E1 already establishes that a roleless user cannot access role-gated modules).
- **Exceptions:** N/A for the unresolved part.
- **Related Functional Requirements:** FR-066, FR-067.
- **Notes:** See DD-037.

### BRL-070 — User Deactivation
- **Purpose:** Define deactivation mechanics and the sole-role-holder edge case.
- **Applies To:** User Deactivation (FR-066).
- **Rule Statement:** Deactivation follows the Archive/Restore pattern (BC-002) — a user account is never permanently deleted. **Not resolved:** whether deactivating the sole holder of a required role (e.g., the only Super Admin) is blocked, warned, or permitted.
- **Trigger:** Administrator deactivates a user.
- **Result:** Account archived; excluded from login (BRL-008); restorable.
- **Exceptions:** N/A for the unresolved part.
- **Related Functional Requirements:** FR-066.
- **Notes:** See DD-038.

### BRL-071 — Role Assignment
- **Purpose:** Determine whether a user may hold more than one Role.
- **Applies To:** Role & Permission Management (FR-067).
- **Rule Statement:** **Not resolved in this document.** The approved six roles (Super Admin, Operations Manager, Collection Officer, Finance, Support, Viewer) are defined, but whether a single user account may be assigned more than one simultaneously is not specified.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-067.
- **Notes:** See DD-039.

### BRL-072 — Permission Validation
- **Purpose:** Confirm permissions derive strictly from Role assignment.
- **Applies To:** All RBAC-gated actions across every module.
- **Rule Statement:** A user's effective permissions are determined entirely by their currently assigned Role(s), resolved at login and refreshed on role change (Module 1, FR-006). The detailed role-to-permission matrix itself is defined in `08_Security_and_RBAC.md`, not restated here.
- **Trigger:** Every authenticated request.
- **Result:** Action allowed or denied per the Role's permission set.
- **Exceptions:** No assigned Role → all role-gated actions denied.
- **Related Functional Requirements:** FR-006, FR-067.

### BRL-073 — Company Profile Rules
- **Purpose:** Define required vs. optional Company Profile fields.
- **Applies To:** Company Profile & Branding (FR-068).
- **Rule Statement:** Business name is required; logo, address, and contact details are optional but, once set, are applied to all subsequently generated documents (BRL-054). Logo file format and size constraints are a UI-validation / Non-Functional Requirement concern, not a Business Rule, and are addressed in `05_UI_UX_Specification.md` / `09_Non_Functional_Requirements.md`.
- **Trigger:** Administrator updates Company Profile.
- **Result:** Profile saved; branding applied going forward.
- **Exceptions:** Invalid data → rejected (FR-068, E2), per the format constraints defined in those documents.
- **Related Functional Requirements:** FR-068.
- **Notes:** Not tracked as a Business Rule Deferred Decision — jurisdiction belongs to UI/NFR documents per correction.

### BRL-074 — System Preferences Validation
- **Purpose:** Define acceptable ranges for configurable policy values.
- **Applies To:** System Preferences (FR-069).
- **Rule Statement:** **Not resolved in this document.** Minimum/maximum bounds for Credit Policy, Recovery Policy timing, and Professional Collection Threshold values are not specified — only that negative or otherwise nonsensical values are rejected (FR-069, E2).
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-069.
- **Notes:** See DD-040.

### BRL-075 — Lookup & Reference Data Lifecycle
- **Purpose:** Determine what happens when a reference value in active use is removed.
- **Applies To:** Lookup & Reference Data (FR-070).
- **Rule Statement:** **Not resolved in this document.** Whether removing a value currently referenced by existing records (e.g., a Payment Method in use) is blocked, warned, or silently orphans those records is not specified.
- **Trigger:** N/A — see Deferred Decisions.
- **Result:** N/A.
- **Exceptions:** N/A.
- **Related Functional Requirements:** FR-070.
- **Notes:** See DD-041.

### BRL-076 — Audit Trail Immutability
- **Purpose:** Guarantee the Audit Trail's evidentiary value.
- **Applies To:** Audit Trail (FR-071), and every module that writes to it.
- **Rule Statement:** No update or delete capability exists for any Audit Trail entry, anywhere in the system. Every entry, once written, is permanent and unalterable by any user regardless of Role.
- **Trigger:** N/A (a standing constraint).
- **Result:** The Audit Trail is a reliable, tamper-proof record.
- **Exceptions:** None — there are no exceptions to immutability.
- **Related Functional Requirements:** FR-071, and the write-path of every other FR that records an Audit Trail event.

---

## State Transition Rules

### Customer Status
Not a restricted graph — per BRL-014, any of the seven approved values may be set from any other by an authorized user. No transition is undefined; all are permitted.

### Debt Status
| From ↓ / To → | Overdue | Partial Paid | Paid | Cancelled | Written Off |
|---|---|---|---|---|---|
| Draft / Pending | ✅ (due date passes) | ✅ (payment) | ✅ (payment) | ✅ (manual) | ✅ (manual) |
| Overdue | — | ✅ (payment) | ✅ (payment) | ✅ (manual) | ✅ (manual) |
| Partial Paid | — | — | ✅ (payment) | — | ✅ (manual) |
| Paid | — | — | — | — | — |
| Cancelled | — | — | — | — | — |
| Written Off | — | — | — | — | — |

Paid, Cancelled, and Written Off are terminal — no defined path back to any open status in Version 1 (BRL-021). Which of Draft/Pending is the actual creation default remains DD-006.

### Recovery Stage
| Stage | Entry Condition | Next Possible Stage(s) |
|---|---|---|
| 1 — Friendly Reminder | Debt created | 2, or manual override to any stage |
| 2 — Late Reminder | Debt Overdue + subsequent reminder | 3, 4 |
| 3 — Phone Follow-up | Call logged | 4 |
| 4 — Final Notice | Promise broken | 5 |
| 5 — Professional Collection | Escalation (Collection Case created) | 6 |
| 6 — Recovered | Debt Paid | (terminal) |

Per BRL-031, this mapping is a reasoned derivation from the approved Recovery Timeline sequence, pending confirmation (DD-012). Manual override (BRL-002) can move a Debt to any stage regardless of this table, with mandatory reason.

### Collection Case Status
| From ↓ / To → | Closed |
|---|---|
| Open | ✅ (FR-045, with recorded outcome) |
| Closed | ❓ Not resolved — see BRL-051 / DD-025 |

Only two states are confirmed to exist (Open, Closed); the initial status value (DD-020) and the full closure-outcome value set (DD-024) remain pending, so this matrix is intentionally minimal rather than asserting undecided detail.

### Professional Collection Request Status *(added — reopened scope)*
| From ↓ / To → | Under Review | Need More Information | Accepted | Assigned | In Progress | Recovered | Closed |
|---|---|---|---|---|---|---|---|
| Submitted | ✅ | — | — | — | — | — | — |
| Under Review | — | ✅ | ✅ | ❓ DD-043 | ❓ DD-043 | — | ❓ DD-043 |
| Need More Information | — | — | ✅ (back to Under Review shown as re-entry) | — | — | — | — |
| Accepted | — | — | — | ✅ | — | — | — |
| Assigned | — | — | — | — | ✅ | — | — |
| In Progress | — | — | — | — | — | ✅ | ✅ |
| Recovered | — | — | — | — | — | — | — |
| Closed | — | — | — | — | — | — | — |

Recovered and Closed are terminal. Cells marked ❓ are not confirmed either way (BRL-079, DD-043) — this matrix asserts only the named sequence from BR-039–042/FR-073, not a fully resolved graph. Every transition is performed by the Deendoon Super Admin — the already-approved Deendoon Platform Administrator actor; no new actor or permission model is introduced. **"Assigned" does not mean assignment to another system user** — it means the Super Admin has accepted ownership of the Request and started handling it (BRL-079). Any coordination with other Deendoon staff is manual and outside the system.

---

## Calculation Rules

| Calculation | Formula | Inputs | Rounding | Ambiguity Status |
|---|---|---|---|---|
| Remaining Credit | Credit Limit − Outstanding Balance | Customer.CreditLimit, Customer.OutstandingBalance | 2 dp, round-half-up | Resolved (BRL-017) |
| Debt Remaining Balance | Debt Amount − Σ Payments (that Debt) | Debt.Amount, Payment.Amount[] | 2 dp, round-half-up | Resolved (BRL-022) |
| Customer Outstanding Balance | Σ Remaining Balance (open Debts) | Debt.RemainingBalance[] | 2 dp, round-half-up | Resolved (BRL-022); "open" scope for Archived-non-terminal Debts is DD-007 |
| Credit Score | Baseline + Σ(event point values) → normalized 0–100 → band | Event history, point catalog, band thresholds | Integer score | Baseline (DD-008), point catalog (DD-009), bands (DD-009) all pending |
| Aging Bucket | Current Date − Debt Due Date, applied to Remaining Balance | Debt.DueDate, Debt.RemainingBalance | N/A (day-count) | Resolved (BRL-060); timezone/day-boundary is DD-034 |
| Total Outstanding Amount (KPI) | Σ Remaining Balance (open Debts, in scope) | Debt.RemainingBalance[] | 2 dp | Resolved (BRL-059) |
| Total Collected (Period) (KPI) | Σ Payment.Amount within period | Payment.Amount[], period bounds | 2 dp | Resolved (BRL-059); period boundary/timezone is DD-034 |
| Recovery Rate (KPI) | Not defined — candidate: Collected ÷ Raised, or Collected ÷ (Collected + Outstanding) | — | — | Pending (DD-032) |
| Average Days to Recover (SM-007) | Not precisely defined (which date = "recovered") | — | — | Pending (DD-033) |
| Promise Fulfillment Rate (SM-008) | Fulfilled Promises ÷ Total Promises (period) | PromiseToPay records | Percentage, 1 dp | Mechanism resolved (BRL-032); exact edge-case handling is DD-033 |

**Rounding convention (general):** All monetary values use 2 decimal places with round-half-up rounding. This is a technical formalization necessary to remove calculation ambiguity per the requirement that no calculation remain ambiguous — it is not a business policy choice and carries low risk if revisited later.

---

## Validation Rules

| Entity | Required Fields | Optional Fields | Allowed Values | Invalid Condition → System Response |
|---|---|---|---|---|
| Customer | Name, Phone | Credit Limit (defaults per BRL-012), other profile fields (`06_Database_Design.md`) | Customer Status: 7 approved values (BRL-014); Risk Level: pending (DD-010) | Missing/invalid required field → reject with field-level error (FR-007, E1) |
| Debt | Amount (> 0), Due Date | Notes | Debt Status: 7 approved values (BRL-021) | Negative/zero amount, invalid date → reject (FR-017, E1) |
| Payment | Amount (> 0), Date, Debt reference | Payment Method (pending catalog, DD-019), reference notes | N/A | Non-positive/non-numeric amount → reject (FR-034 validation) |
| Collection Case | Debt reference (exactly one) | Assigned Officer, Notes & Attachments | Status: Open/Closed (initial value pending, DD-020; outcome set pending, DD-024) | Attempt to reference more than one Debt → not supported (BRL-038) |
| Professional Collection Request *(added)* | Collection Case reference (exactly one) | Conversation messages | Status: Submitted…Recovered/Closed (full matrix pending, DD-043) | Submission against a Closed Case → rejected (FR-072, E2); duplicate active Request → not resolved (DD-042) |
| User Account | Identifier (email or username, per tenant config), name | Contact details | Role: 6 approved values (Super Admin, Operations Manager, Collection Officer, Finance, Support, Viewer) | Missing required field → reject (FR-066, E2); invalid Role → reject (FR-067, E2) |

---

## Configuration Policy

Per the approved architectural principle **Configuration over Hardcoding** (`01_Project_Overview.md` §1.9, Principle 5; BC-003):

**Configurable (via Module 12, System Settings / Lookup & Reference Data):**
- Default Credit Limit, Credit Limit Reminder threshold, Soft Limit Warning threshold (BR-034).
- WhatsApp/SMS/Call Reminder timing, Professional Collection escalation threshold (BR-011, BR-034).
- Notification settings, Company Profile & Branding, Document Templates (BR-035).
- Reference value sets once formally defined: Risk Level values, Payment Method catalog, Collection closure-outcome values (pending DD-010, DD-019, DD-024).
- Login identifier type (email vs. username) — tenant-level setting (Module 1, FR-001).
- Recovery-channel selection for password reset (Module 1, FR-004).

**Fixed (approved, not configurable in Version 1):**
- The six RBAC roles and their existence (Super Admin, Operations Manager, Collection Officer, Finance, Support, Viewer) — the role *set* is fixed; only *assignment* to users is an administrative action.
- The seven Customer Status values, seven Debt Status values, and six Recovery Stage values — these enumerations are fixed; only usage/transition is governed by rules above.
- The four Demand Letter templates and their names (First Reminder, Second Reminder, Final Demand, Legal Notice).
- The Auto Numbering prefixes (`DBT-`, `RCT-`, `DL-`, `ST-`, `COL-`) and the five entities that receive them.
- The overall module/workflow structure defined in `03_Functional_Requirements.md`.

This document introduces no new configurable values beyond what Modules 1–12 already identified as configuration (System Settings, Lookup & Reference Data); it only clarifies which already-approved items belong in which category.

---

## Consistency Validation

Every Functional Requirement across Modules 1–12 (FR-001–FR-071) has been reviewed against this document. FRs whose Main Flow, Alternate Flows, or Exceptions referenced "defined in `04_Business_Rules.md`" are covered above; FRs with no referenced ambiguity (e.g., pure display/read FRs such as FR-008, FR-019, FR-042, FR-050) require no additional Business Rule beyond the RBAC/BRL-004/BRL-006 principles already stated.

| Module | FR Range | Business Rules Applied |
|---|---|---|
| 1 — Authentication | FR-001–006 | BRL-007–011, BRL-072 |
| 2 — Customer Management | FR-007–016 | BRL-012–018 |
| 3 — Debt Register | FR-017–025 | BRL-019–024, BRL-035 (cross-ref) |
| 4 — Credit & Risk Management | FR-026–028 | BRL-025–029 |
| 5 — Recovery Workflow | FR-029–033 | BRL-030–036 |
| 6 — Payment Tracking | FR-034–039 | BRL-037–044 |
| 7 — Professional Collection | FR-040–046 | BRL-045–052 |
| 8 — Documents | FR-047–052 | BRL-053–058 |
| 9 — Reporting & Analytics | FR-053–057 | BRL-059–063 |
| 10 — Notifications & Calendar | FR-058–062 | BRL-064–068 |
| 11 — Search & Productivity | FR-063–065 | BRL-013 (matching, cross-ref), BRL-004/BRL-006 (RBAC/visibility, general) |
| 12 — Administration & Settings | FR-066–071 | BRL-069–076 |

No Functional Requirement was found to require business logic that this document leaves entirely unaddressed — every ambiguity flagged in `03_Functional_Requirements.md`'s Open Items has a corresponding Business Rule entry above, resolved where the approved baseline permitted a safe answer, and deferred where it did not.

---

## Scope Control

This document does not, and has not:
- Introduced Version 2 functionality.
- Introduced new modules.
- Introduced new workflows.
- Introduced new entities beyond those already referenced in `03_Functional_Requirements.md`.
- Introduced new permissions or roles.
- Introduced new integrations.
- Modified any approved Functional Requirement in `03_Functional_Requirements.md`.
- Modified any approved Business Requirement in `02_Business_Requirements.md`.
- Modified the approved Project Scope in `01_Project_Overview.md`.

Every rule above either formalizes mechanics already implied by an approved FR/BR, or explicitly declines to invent an answer and routes the question to Deferred Decisions.

---

## Deferred Decisions

| ID | Decision Required | Reason | Impacted Functional Requirements |
|---|---|---|---|
| DD-001 | Session idle-timeout threshold value | Not specified; deliberately configurable (BC-003) | FR-003 |
| DD-002 | Password reset token lifetime | Not specified | FR-004 |
| DD-003 | Duplicate Customer name-matching algorithm/sensitivity | Not specified (exact vs. fuzzy match) | FR-014, FR-007, FR-009, FR-016 |
| DD-004 | Whether a Customer with outstanding Debts may be archived | Not addressed anywhere in Feature Freeze | FR-010 |
| DD-005 | Partial-import validation failure behavior (proceed with valid rows vs. reject batch) | Not specified | FR-016 |
| DD-006 | Default Debt Status at creation: Draft or Pending | Both named as valid; no default specified | FR-017, FR-021 |
| DD-007 | Whether an Archived-but-non-terminal Debt still counts toward Outstanding Balance | Archiving and financial closure are conceptually distinct; not addressed | FR-036, FR-022 |
| DD-008 | Initial/baseline Credit Score for a new Customer | Not specified | FR-026 |
| DD-009 | Credit Score point-value catalog and band numeric thresholds | Discussed as illustrative only; never formally approved | FR-026 |
| DD-010 | Risk Level qualitative value set | Pre-existing feature; values never enumerated | FR-027 |
| DD-011 | Credit Limit Reached (and other) notification re-trigger/suppression policy | Not specified | FR-028, FR-058 |
| DD-012 | Confirmation of the Recovery Stage → event mapping derived in BRL-031 | Derived from the approved Timeline, not explicitly pre-approved as a stage-automation table | FR-025, FR-032 |
| DD-013 | Promise to Pay date-revision handling (replace vs. break-then-renew) | Not specified | FR-031 |
| DD-014 | Whether early manual escalation to Professional Collection is permitted, and by whom | Not specified | FR-040 |
| DD-015 | Reminder delivery failure retry policy (count, backoff) | Not specified | FR-029, FR-030 |
| DD-016 | Overpayment handling (reject / cap / credit) | Not specified | FR-034, FR-037 |
| DD-017 | Whether payment may be recorded against a Paid/Cancelled/Written-Off Debt | Not specified | FR-034 |
| DD-018 | Payment editing, archival/deletion mechanism, and reversal — whether each exists and how | Not specified; Payment not explicitly named in approved Archive scope | FR-034, FR-035 |
| DD-019 | Payment Method: fixed catalog vs. free text | Not specified | FR-034, FR-070 |
| DD-020 | Initial Collection Case status at creation | Not specified | FR-040 |
| DD-021 | Automatic Collection Case assignment / workload balancing | Not specified | FR-041 |
| DD-022 | Reassignment notification policy | Not specified | FR-041 |
| DD-023 | Duplicate escalation handling (reject vs. redirect to existing case) | Not specified | FR-040 |
| DD-024 | Collection Case closure-outcome value set | Only "Recovered" implied; full set never enumerated | FR-045 |
| DD-025 | Whether a Closed Collection Case can be reopened | Not specified | FR-043, FR-044 |
| DD-026 | Abandoned Collection Case handling | Not specified | FR-040–046 |
| DD-027 | Maximum collection duration | Not specified | FR-040–046 |
| DD-028 | Whether document numbering format (prefix/digit count) is tenant-configurable | Not specified | FR-047–049 |
| DD-029 | Document regeneration mechanics (permitted? new number vs. reuse?) | Not specified | FR-052 |
| DD-030 | Document retention period | Not specified | FR-052 |
| DD-031 | Document Template customizable-field/wording constraints | Not specified | FR-069 |
| DD-032 | Recovery Rate KPI exact formula | Multiple valid definitions; none chosen | FR-053 |
| DD-033 | Average Days to Recover Debt (SM-007) and Promise Fulfillment Rate (SM-008) exact edge-case formulas | Not precisely defined | FR-031, FR-053 |
| DD-034 | Timezone and calendar-boundary rules (day/week/month start) | Not specified | FR-053, FR-054, FR-062 |
| DD-035 | Notification History retention/expiry | Not specified | FR-061 |
| DD-036 | Mechanism by which a Collection Activity becomes a Calendar entry (Collection Appointments not a distinct entity) | Not specified | FR-062 |
| DD-037 | Initial user credential/invitation mechanism | Not specified | FR-066 |
| DD-038 | Handling of deactivating the sole holder of a required Role | Not specified | FR-066 |
| DD-039 | Whether a user may hold more than one Role simultaneously | Not specified | FR-067 |
| DD-040 | Validation ranges (min/max) for each System Preference | Not specified | FR-069 |
| DD-041 | Handling of removing an in-use Lookup & Reference Data value | Not specified | FR-070 |
| DD-042 | Handling of a duplicate active Professional Collection Request against the same Collection Case (reject vs. surface existing) | Not specified | FR-072 |
| DD-043 | Full Professional Collection Request status transition matrix beyond the named sequence | Not specified | FR-073 |
| DD-044 | Whether Request Conversation remains available after a terminal outcome (Recovered/Closed) | Not specified | FR-075 |
| DD-045 | Professional Collection Request Auto Numbering format confirmation (`PCR-000001` proposed) | Not yet formally confirmed | FR-072 |
| DD-046 | Relationship between Professional Collection Request closure and the linked Collection Case's own closure (coupled vs. independent) | Not specified | FR-045, FR-076 |

---

**End of 04_Business_Rules.md — Awaiting review and approval.**
