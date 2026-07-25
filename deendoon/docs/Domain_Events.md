# Domain Events

**Status:** Living document — single source of truth for every Domain Event used or planned throughout Deendoon.
**Scope:** Every event documented here traces to one of three authoritative sources in the approved SRS:

1. `06_Database_Design.md` §6.9 — the `audit_log.action` CHECK constraint (19 approved values).
2. `06_Database_Design.md` §6.3 — the `follow_up_history.action_type` CHECK constraint (10 approved values).
3. `06_Database_Design.md` §6.7 — the `notifications.type` CHECK constraint (7 approved values).

An event not traceable to one of these three enums (or to an explicit FR/BRL statement) is **not documented here as approved** — it is listed under [Future Review](#future-review) instead, with the specific reason it doesn't yet qualify.

**Two different things share the word "event" in this codebase, and this document is careful to distinguish them:**
- A **dispatched Domain Event** — an actual `App\Events\*` class raised via Laravel's `Event::dispatch()`, which other code can listen for. Today, two exist: `CreditLimitReached` and `PromiseBroken`.
- A **recorded occurrence** — an already-approved business action that gets written to `audit_log` (via `AuditLogService`) or `follow_up_history`, but has no dedicated dispatchable class. Most "events" below are currently only this. They are real and implemented, but another module cannot yet *subscribe* to them the way it could a dispatched Event — promoting one to a real Event class (as was done for `CreditLimitReached`) is a small, well-precedented step whenever a future module first needs to react to it.

The **Current Implementation Status** field on every event states which of these it is today.

---

## Table of Contents

- [Implemented Events](#implemented-events)
- [Customer Lifecycle (recorded, Module 2)](#customer-lifecycle-recorded-module-2)
- [Debt Lifecycle (recorded, Module 3)](#debt-lifecycle-recorded-module-3)
- [Credit & Risk (Module 4)](#credit--risk-module-4)
- [Authentication (approved, not yet wired)](#authentication-approved-not-yet-wired)
- [Recovery Workflow (Module 5)](#recovery-workflow-module-5)
- [Planned Events — Payment Tracking (Module 6)](#planned-events--payment-tracking-module-6)
- [Planned Events — Professional Collection (Module 7)](#planned-events--professional-collection-module-7)
- [Planned Events — Documents (Module 8)](#planned-events--documents-module-8)
- [Planned Events — Administration (Module 12)](#planned-events--administration-module-12)
- [Deferred Events](#deferred-events)
- [Future Review](#future-review)
- [Appendix: Authoritative Enums](#appendix-authoritative-enums)

---

## Implemented Events

### CreditLimitReached

| Field | Detail |
|---|---|
| **Purpose** | Signals that a Customer's Outstanding Balance has reached or exceeded their approved Credit Limit, so a future module can notify the business owner. |
| **Publisher** | `App\Services\CustomerBalanceService::recalculate()` |
| **Trigger Condition** | After recomputing `outstanding_balance` (BRL-022), if `outstanding_balance >= credit_limit`. Fires from both Debt creation and Debt status transitions to a terminal state, since either can move the balance across the threshold. |
| **Payload** | `Customer` (the full model instance) |
| **Current Consumers** | None — no listener is registered. |
| **Future Consumers** | Reminder Engine / Notification Center (Module 10), per FR-028 step 3. |
| **Related Functional Requirements** | FR-028 (Credit Limit Reached Notification **Trigger** — the event-generation step only; delivery is explicitly Module 10's responsibility, not this event's) |
| **Related Business Rules** | BC-001 (advisory only, never a block); BRL-023 (the exact threshold formula) |
| **Current Implementation Status** | **Implemented** — a real `App\Events\CreditLimitReached` class, dispatched via `Event::dispatch()`, covered by 3 feature tests (fires at threshold, doesn't fire under it, fires again on repeat with no suppression). |

**Open item carried from the Credit & Risk Module report:** DD-011 (`04_Business_Rules.md`) leaves re-trigger/suppression behavior unresolved. This event currently fires on *every* qualifying recalculation while the condition holds — no de-duplication is implemented, since inventing one would mean deciding DD-011 rather than documenting it.

---

### PromiseBroken

| Field | Detail |
|---|---|
| **Purpose** | Signals that an open Promise to Pay's promised date has passed with no qualifying payment, so Recovery Stage automation can react. |
| **Publisher** | `App\Services\PromiseToPayService::refreshBrokenPromises()` |
| **Trigger Condition** | Lazy, on-access check (fires when a Debt is viewed via `show`/`index`, same pattern as the Overdue transition): an open `PromiseToPay` whose `promised_date` is in the past is marked `broken`. |
| **Payload** | `PromiseToPay` (the full model instance) |
| **Current Consumers** | `App\Listeners\AdvanceRecoveryStageOnBrokenPromise` — advances the Debt's Recovery Stage to 4 (Final Notice) via `RecoveryStageService`, wired through Laravel's automatic event/listener discovery (verified by feature test, no manual registration needed). |
| **Future Consumers** | Credit Score recalculation (Module 4) once DD-008/DD-009 are resolved — BRL-034 names a Credit Score deduction on a broken promise, but this is **not** implemented today since no approved point-value formula exists yet (see [Deferred Events](#deferred-events)). |
| **Related Functional Requirements** | FR-031 (Promise to Pay — Broken outcome), FR-032 (Recovery Stage Automation) |
| **Related Business Rules** | BRL-031 (Stage 4 mapping), BRL-034 (broken-promise trigger condition) |
| **Current Implementation Status** | **Implemented** — a real `App\Events\PromiseBroken` class, dispatched via `Event::dispatch()`, covered by feature tests (transitions to broken, dispatches the event, advances Recovery Stage, does not fire for promises not yet due). |

**Note on why the promise-broken condition can be evaluated at all without Module 6 (Payments):** BRL-034's trigger is "promised date passes with no qualifying payment." Since zero payments can exist anywhere in the system today (Module 6 doesn't exist), that condition is unconditionally true once the date passes — a logically sound shortcut, not an invented rule.

---

## Customer Lifecycle (recorded, Module 2)

All six of the following are real, tested, working code paths in `CustomerController` today — each writes one `audit_log` row via `AuditLogService`. None has a dedicated dispatchable Event class yet.

| Event Name | `audit_log.action` | Publisher | Trigger | Payload (audit_log columns) | Related FR | Status |
|---|---|---|---|---|---|---|
| **CustomerCreated** | `created` | `CustomerController::store()` | A new Customer is successfully created | `tenant_id`, `user_id`, `entity_type=customer`, `entity_id` | FR-007 | **Implemented** (recorded) |
| **CustomerEdited** | `edited` | `CustomerController::update()` | Name/phone/credit_limit updated without a credit-limit change | same | FR-009 | **Implemented** (recorded) |
| **CustomerCreditLimitChanged** | `credit_limit_changed` | `CustomerController::update()` / `updateCreditLimit()` | Credit Limit specifically changed | same | FR-009 (A1), FR-013 | **Implemented** (recorded) |
| **CustomerStatusChanged** | `status_changed` | `CustomerController::updateStatus()` | Customer Status set to one of the 7 approved values | same | FR-012 | **Implemented** (recorded) |
| **CustomerArchived** | `archived` | `CustomerController::archive()` | Customer soft-deleted | same | FR-010 | **Implemented** (recorded) |
| **CustomerRestored** | `restored` | `CustomerController::restore()` | Archived Customer reactivated | same | FR-011 | **Implemented** (recorded) |

**Current Consumers (all six):** None. **Future Consumers (all six):** Reporting (Module 9, read-only over `audit_log`), Notifications (Module 10) if a future FR ever attaches one of these to a notification type — none currently does.

---

## Debt Lifecycle (recorded, Module 3)

| Event Name | `audit_log.action` | Publisher | Trigger | Related FR / BR | Status |
|---|---|---|---|---|---|
| **DebtCreated** | `created` | `DebtController::store()` | A new Debt is created against a Customer | FR-017 | **Implemented** (recorded) |
| **DebtEdited** | `edited` | `DebtController::update()` | Non-financial fields (due date, notes) updated | FR-020 | **Implemented** (recorded) |
| **DebtStatusChanged — manual** | `status_changed` | `DebtController::updateStatus()` | Authorized user sets Cancelled or Written Off | FR-021, BRL-021 | **Implemented** (recorded) |
| **DebtStatusChanged — automatic (Overdue)** | `status_changed`, `user_id = NULL` | `DebtController::refreshOverdueStatus()` | Due date has passed on a Draft/Pending Debt, detected lazily on next access | FR-021 (A1), BRL-021 | **Implemented** (recorded) — see note below |
| **DebtArchived** | `archived` | `DebtController::archive()` | Debt soft-deleted | FR-022, BRL-024 | **Implemented** (recorded) |
| **DebtRestored** | `restored` | `DebtController::restore()` | Archived Debt reactivated | FR-023, BRL-024 | **Implemented** (recorded) |
| **RecoveryStageOverride** | `recovery_stage_override` | `DebtController::updateRecoveryStage()` | Authorized user manually overrides Recovery Stage, with mandatory reason | FR-025, BRL-002 | **Implemented** (recorded) |

**Note on the automatic Overdue transition:** implemented as a lazy, on-access check (fires when a Debt is viewed via `show`/`index`), not a scheduled job — no queue/scheduler infrastructure decision has been made yet. A Debt nobody views won't show as Overdue in an aggregate context (e.g., a future dashboard) until accessed. See [Future Review](#future-review) for the distinctly-named "DebtOverdue" question.

**Current Consumers (all seven):** None. **Future Consumers:** Reporting (Module 9); Recovery Workflow (Module 5) already reacts to Debt Overdue status via its lazy reminder-stage logic (see [Recovery Workflow](#recovery-workflow-module-5)).

---

## Credit & Risk (Module 4)

| Event Name | Publisher | Trigger | Related FR / BR | Status |
|---|---|---|---|---|
| **CustomerRiskLevelChanged** | `edited` (audit_log), `CreditRiskController::updateRiskLevel()` | Authorized user assigns/updates Risk Level | FR-027, BRL-006 | **Implemented** (recorded) |
| **CreditScoreRecalculated** | *(none — see below)* | A qualifying payment-behavior event (On-Time/Late Payment, Broken Promise, Partial Payment, Long Outstanding Debt) | FR-026, BC-007 | **Deferred** |

`CreditScoreRecalculated` is listed here for completeness (it is an approved `audit_log.action` value) but genuinely cannot be implemented yet: DD-008 (baseline score) and DD-009 (point-value catalog and band thresholds) are both unresolved in `04_Business_Rules.md`, and its triggering events come exclusively from Modules 5 and 6, neither of which exists. See [Deferred Events](#deferred-events).

---

## Authentication (approved, not yet wired)

| Event Name | `audit_log.action` | Approved Trigger | Related FR | Status |
|---|---|---|---|---|
| **Login** | `login` | Successful authentication | FR-001 | **Planned** — `login` is an approved `audit_log.action` value, but `AuthController::login()` does not currently call `AuditLogService`. No audit row is written on login today. |
| **Logout** | `logout` | Session/token invalidated | FR-002 | **Planned** — same gap; `AuthController::logout()` does not call `AuditLogService`. |
| **RoleChanged** | `role_changed` | A user's role assignment changes | FR-067 (Module 12) | **Planned** — approved action exists; Module 12's Role Management isn't built, and the current RBAC is still the interim 3-role model (Product Owner Decision 4). |

This is a genuine, pre-existing implementation gap (not introduced by this documentation task) — `06` approves `login`/`logout` as audit actions, but no code path writes them. Flagged here since it directly affects Reporting/Security-audit completeness once discovered.

---

## Recovery Workflow (Module 5)

Follow-up History actions below are real, tested, working code paths (`ReminderController`, `PromiseToPayController`) — each writes one `follow_up_history` row via `FollowUpHistoryService`, plus a companion `audit_log` row. `PromiseBroken` is additionally a dispatched Event (see [Implemented Events](#implemented-events)). None has been given a dedicated `App\Events\*` class except `PromiseBroken`.

| Event Name | Source Enum | Publisher | Trigger (per approved FR/BRL) | Related FR / BR | Status |
|---|---|---|---|---|---|
| **ManualWhatsAppSent** | `follow_up_history.action_type = manual_whatsapp` | `ReminderController::whatsapp()` | User manually sends a WhatsApp reminder | FR-030 | **Implemented** (recorded) |
| **ManualSmsSent** | `follow_up_history.action_type = manual_sms` | `ReminderController::sms()` | User manually sends an SMS reminder | FR-030 | **Implemented** (recorded) |
| **CallLogged** | `follow_up_history.action_type = call_logged` | `ReminderController::call()` | User logs a phone call | FR-030 | **Implemented** (recorded) |
| **PromiseRecorded** | `follow_up_history.action_type = promise_recorded` | `PromiseToPayController::store()` | A Promise to Pay is recorded against a Debt | FR-031 | **Implemented** (recorded) |
| **PromiseBroken** | `follow_up_history.action_type = promise_broken` | `PromiseToPayService::refreshBrokenPromises()` | Promised date passes with no qualifying payment | FR-031, BRL-034 | **Implemented** (dispatched — see above) |
| **RecoveryStageChanged (automatic)** | *(no distinct `audit_log.action` — reuses `status_changed` with a descriptive `reason`, see below)* | `RecoveryStageService::advanceTo()` | Debt's Recovery Stage advances per BRL-031's event-to-stage mapping (Stage 2: reminder while Overdue; Stage 3: call logged; Stage 4: promise broken) | FR-032, BRL-031 | **Implemented** (recorded, reused action — see note) |

**Not implemented in this module (explicitly out of scope or blocked):**
- **ReminderSent** as an actual *delivery* — this module only records that a manual reminder action was taken (FR-030 scoping); the `notifications.type = reminder_sent` delivery path belongs to Module 10.
- **PromiseFulfilled** — requires a real Payment (Module 6) to determine "fulfilled." No payments can exist yet, so this branch is unreachable and is not implemented (not simulated).
- **PromiseToPayDue** (`notifications.type`) — a Calendar-facing notification; out of scope per the task's explicit exclusion of Notifications Delivery.
- **Escalation Rules → Professional Collection** — the actual escalation action (creating a Collection Case) is Module 7, which doesn't exist. Recovery Stage automation stops at Stage 4 (Final Notice); Stage 5+ requires Module 7/6.

**Note on `RecoveryStageChanged (automatic)`'s reused action:** no distinct `audit_log.action` value exists for an *automatic* stage change (only `recovery_stage_override`, which FR-025 describes as specifically manual — see [Future Review](#future-review)). Following the same precedent already used for Risk Level changes (reusing `edited`), automatic stage advancement reuses `AuditAction::StatusChanged` with a descriptive `reason` string (e.g. "Recovery Stage advanced to 3 (Phone Follow-up): call logged") rather than inventing a new enum value. Flagged as a NON-BLOCKING SRS inconsistency, not resolved here.

**Current Consumers:** `AdvanceRecoveryStageOnBrokenPromise` (for `PromiseBroken`, as above). **Future Consumers of all of the above:** Debt Timeline display (FR-024 — the `timeline` endpoint now sources whatsapp/sms/call/promise stages from `follow_up_history` and shows them as `completed` once populated), Notifications (Module 10), Reporting (Module 9).

---

## Planned Events — Payment Tracking (Module 6)

| Event Name | Source Enum | Trigger | Related FR / BR |
|---|---|---|---|
| **PaymentRecorded** | `audit_log.action = payment_added`, `follow_up_history.action_type = payment_recorded` | A payment is recorded against a Debt | FR-034, BRL-037 |
| **PaymentReceived** | `notifications.type = payment_received` | Same underlying occurrence as PaymentRecorded, surfaced as a notification | FR-039 |
| **DebtStatusChanged — Partial Paid / Paid** | `audit_log.action = status_changed` (generic) | Cumulative payments partially or fully satisfy a Debt | FR-037, BRL-021 |
| **ReceiptGenerated** | `audit_log.action = receipt_generated` | A payment automatically triggers Receipt generation | FR-038, FR-047 |
| **CreditScoreRecalculated (payment-driven)** | `audit_log.action = credit_score_recalculated` | A payment is classified on-time/late/partial | FR-039, FR-026 — see [Deferred Events](#deferred-events) |

**Future Consumers:** Customer Balance recalculation (`CustomerBalanceService`, already built and ready to consume a real Payment once Module 6 exists), Credit & Risk (Module 4), Documents (Module 8), Notifications (Module 10).

---

## Planned Events — Professional Collection (Module 7)

| Event Name | Source Enum | Trigger | Related FR / BR |
|---|---|---|---|
| **Escalated** | `follow_up_history.action_type = escalated` | A Debt is escalated to a Collection Case | FR-040, BRL-035 |
| **CollectionRequested** | `audit_log.action = collection_requested` | A Collection Case is created | FR-040 |
| **CollectionActivityLogged** | `follow_up_history.action_type = collection_activity` | Activity logged against an open Collection Case | FR-044 |
| **CollectionAssignment** | `notifications.type = collection_assignment` | A Collection Case is assigned to a Collection Officer | FR-041 |
| **ProfessionalCollectionRequestSubmitted** | `audit_log.action` | A tenant submits a Professional Collection Request | FR-072 |
| **ProfessionalCollectionRequestStatusChanged** | `audit_log.action` | The Deendoon Platform Administrator transitions a Request's status | FR-073, FR-076 |
| **ProfessionalCollectionRequestUpdate** | `notifications.type = professional_collection_request_update` | Either party posts to the Request's conversation, or status changes | FR-075 |

**Note:** this entire module is additionally blocked on the RBAC divergence (Product Owner Decision 4) — it requires the `deendoon_platform_administrator` actor, which doesn't exist in the current interim 3-role model. Flagged previously in the Architecture Audit; restated here since it affects every event in this section.

---

## Planned Events — Documents (Module 8)

| Event Name | Source Enum | Trigger | Related FR / BR |
|---|---|---|---|
| **DemandLetterGenerated** | `audit_log.action = demand_letter_generated` | A Demand Letter template is generated against a Debt | FR-048 |
| **StatementGenerated** | `audit_log.action = statement_generated` | A Statement of Account is generated | FR-049 |
| **DocumentAvailable** | `notifications.type = document_available` | Any of the three document types finishes generating (generic notification, covers all of Receipt/Demand Letter/Statement) | FR-052 |

---

## Planned Events — Administration (Module 12)

| Event Name | Source Enum | Trigger | Related FR / BR |
|---|---|---|---|
| **RoleChanged** | `audit_log.action = role_changed` | A user's role assignment changes | FR-067 — see also [Authentication](#authentication-approved-not-yet-wired) |

Module 12 itself has never received the explicit standalone approval every other module got (a standing gap carried since `03_Functional_Requirements.md`) — flagged again here since it affects this event's ultimate implementation.

---

## Deferred Events

Events that are approved in principle but cannot be correctly specified today because a **Business Rule they depend on is itself unresolved** — distinct from events merely waiting on a missing module.

| Event Name | Blocked By | Why It's Deferred, Not Planned |
|---|---|---|
| **CreditScoreRecalculated** | DD-008 (baseline score), DD-009 (point-value catalog, band thresholds) | Even once Modules 5/6 exist to supply trigger events, there is no approved formula to calculate a score with. Building any version now would mean inventing DD-008/DD-009's answers, which the Credit & Risk Module report explicitly declined to do. A broken Promise to Pay (`PromiseBroken`, Module 5) is one of BRL-034's named triggers for this, but the deduction itself remains deferred. |

---

## Future Review

Events considered during this review that are **not** documented above as approved, with the specific reason each falls short:

| Candidate Name | Why It's Not an Approved Event |
|---|---|
| **PaymentCancelled** | No FR, Business Rule, or enum (`audit_log`, `follow_up_history`, `notifications`) supports payment cancellation. Payments are explicitly insert-only in `06` §6.4 — DD-018 (editing/reversal mechanism) is unresolved. |
| **PromiseCreated** | Close to approved, but not the SRS's own term — `follow_up_history.action_type` uses `promise_recorded`. Documented above under that name; flagging the naming mismatch so it isn't reintroduced under a different spelling later. |
| **DebtOverdue** | No enum has a distinct value for this — it is expressed as the generic `status_changed` action (already implemented that way in `DebtController::refreshOverdueStatus()`). A dedicated name could be introduced later if a future module needs to filter specifically for this transition, but doing so now would mean inventing a database value `06` doesn't define. |
| **DebtRecovered** | Same issue as DebtOverdue — "Recovered" is Recovery Stage 6's *name* (BRL-031) and/or Debt Status `paid`, but neither has its own distinct audit action. Expressed generically today. |
| **RecoveryStageChanged** | The **manual** case is approved and implemented (`recovery_stage_override`). The **automatic** case (Module 5's engine, now implemented in `RecoveryStageService`) still has no corresponding distinct `audit_log.action` — only the override action exists, and FR-025 describes it as specifically manual. Implemented today by reusing `status_changed` with a descriptive `reason` (see [Recovery Workflow](#recovery-workflow-module-5)), consistent with the Risk Level precedent, rather than left unimplemented. This remains a genuine gap between `03`'s Module 5 automation description (FR-032) and `06`'s audit action catalog — recommend a Product Owner / SRS decision on a distinct action name (e.g. `recovery_stage_advanced`). |
| **ReminderDue** | Not approved under this name — only `reminder_sent` (past-tense, after delivery) exists in any of the three enums. A "due" (pre-send) concept isn't named anywhere in `03`/`06`. |

---

## Appendix: Authoritative Enums

For direct reference, the three CHECK-constrained enums this entire document is built from (verified against `06_Database_Design.md` directly, not from memory):

**`audit_log.action`** (06 §6.9): `created`, `edited`, `archived`, `restored`, `status_changed`, `reminder_sent`, `payment_added`, `collection_requested`, `login`, `logout`, `role_changed`, `credit_limit_changed`, `credit_score_recalculated`, `demand_letter_generated`, `receipt_generated`, `statement_generated`, `recovery_stage_override`, `professional_collection_request_submitted`, `professional_collection_request_status_changed`.

**`follow_up_history.action_type`** (06 §6.3): `reminder_sent`, `manual_whatsapp`, `manual_sms`, `call_logged`, `promise_recorded`, `promise_fulfilled`, `promise_broken`, `payment_recorded`, `collection_activity`, `escalated`.

**`notifications.type`** (06 §6.7): `credit_limit_reached`, `payment_received`, `document_available`, `collection_assignment`, `reminder_sent`, `promise_to_pay_due`, `professional_collection_request_update`.
