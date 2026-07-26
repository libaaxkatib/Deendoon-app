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
- [Payment Tracking (Module 6)](#payment-tracking-module-6)
- [Professional Collection (Module 7)](#professional-collection-module-7)
- [Documents (Module 8)](#documents-module-8)
- [Notifications & Calendar (Module 10)](#notifications--calendar-module-10)
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
| **Current Consumers** | `App\Listeners\CreateCreditLimitReachedNotification` (Module 10) — creates a `credit_limit_reached` Notification for every admin/sales_finance user in the affected Customer's tenant (no single-owner field exists on Customer, unlike Collection Case's assigned officer, so this fans out rather than picking one arbitrarily). Wired via Laravel's automatic event/listener discovery, verified by feature test — no manual registration needed, same as `PromiseBroken`. |
| **Future Consumers** | None further identified. |
| **Related Functional Requirements** | FR-028 (Credit Limit Reached Notification **Trigger** — the event-generation step only); FR-058 (Module 10, now implemented — the delivery/display side this event was always meant to feed) |
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

**Note on `refreshBrokenPromises()` vs. Module 6 (Payments):** BRL-034's trigger is "promised date passes with no qualifying payment." Module 6 now exists and evaluates the other side of BRL-032's outcome (`PromiseToPayService::evaluateFulfillment()`, called synchronously when a payment is recorded) — a promise is only ever marked broken while it is still `open`, so any promise a qualifying payment has already fulfilled is no longer eligible for this check. One ordering edge case is not handled: if a promise is *already marked broken* (its date passed and a Debt view triggered this method before any payment arrived) and a backdated payment is then recorded that would have qualified as fulfillment, the promise stays `broken` — there is no path back from `broken` to `fulfilled`, since Promise to Pay revision/correction (DD-013) is itself unresolved. Flagged as NON-BLOCKING in the Module 6 report, not silently resolved.

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
| **PromiseFulfilled** | `follow_up_history.action_type = promise_fulfilled` | `PromiseToPayService::evaluateFulfillment()` | A qualifying payment (Module 6) is recorded on or before the promised date | FR-031, BRL-032 | **Implemented** (recorded) — see Module 6 below |
| **RecoveryStageChanged (automatic)** | *(no distinct `audit_log.action` — reuses `status_changed` with a descriptive `reason`, see below)* | `RecoveryStageService::advanceTo()` | Debt's Recovery Stage advances per BRL-031's event-to-stage mapping (Stage 2: reminder while Overdue; Stage 3: call logged; Stage 4: promise broken; Stage 5: escalated to a Collection Case, Module 7; Stage 6: Debt reaches Paid, Module 6) | FR-032, BRL-031 | **Implemented** (recorded, reused action — see note) |

**Note on `RecoveryStageChanged (automatic)`'s reused action:** no distinct `audit_log.action` value exists for an *automatic* stage change (only `recovery_stage_override`, which FR-025 describes as specifically manual — see [Future Review](#future-review)). Following the same precedent already used for Risk Level changes (reusing `edited`), automatic stage advancement reuses `AuditAction::StatusChanged` with a descriptive `reason` string (e.g. "Recovery Stage advanced to 3 (Phone Follow-up): call logged") rather than inventing a new enum value. Flagged as a NON-BLOCKING SRS inconsistency, not resolved here.

**Current Consumers:** `AdvanceRecoveryStageOnBrokenPromise` (for `PromiseBroken`, as above); Notifications (Module 10) now consumes `ManualWhatsAppSent`/`ManualSmsSent`/`CallLogged` for the `reminder_sent` notification type (via `ReminderController`, a direct synchronous call, not a subscription to this table) and consumes an open Promise's `promised_date` directly for `promise_to_pay_due` (via `PromiseToPayService::refreshDuePromises()`) — see [Notifications & Calendar](#notifications--calendar-module-10). **Future Consumers of all of the above:** Debt Timeline display (FR-024 — the `timeline` endpoint sources whatsapp/sms/call/promise/payment stages from `follow_up_history` and shows them as `completed` once populated), Reporting (Module 9).

---

## Payment Tracking (Module 6)

Recorded, tested, working code paths in `PaymentService::record()` — each Payment triggers one `audit_log` row (`payment_added`) and one `follow_up_history` row (`payment_recorded`), plus the downstream consequences below. None has been given a dedicated `App\Events\*` class — unlike `PromiseBroken`, no approved Business Rule ties Payment Recording to a consequence that needs *decoupled* handling; every consequence below is synchronous, same-request, same-transaction, and already reuses an existing Service directly (`CustomerBalanceService`, `PromiseToPayService`, `RecoveryStageService`).

**Verified directly against the approved SRS (Product Owner review, Module 6):** the terms "Domain Event," "event-driven," "event bus," "dispatch," and "listener" do not appear anywhere in `01`–`09`. FR-039's "System emits a qualifying payment-behavior event..." language is plain narrative describing required behavior, not a mandate for the dispatched-class architecture — that architecture (and the promotion criterion: only when a consequence needs decoupled handling) is this codebase's own implementation choice, not an SRS requirement. FR-039's three sub-steps were checked individually against that self-imposed criterion: Credit Score classification (deferred, no consumer), Promise fulfillment (implemented, direct synchronous call, no decoupling need), Payment Received → Notifications (now implemented, Module 10 — but still a direct synchronous call from `PaymentService::record()`, not a subscription, so this doesn't change the conclusion). None qualifies for promotion to a dispatched class; the synchronous implementation is correct as-is.

| Event Name | Source Enum | Publisher | Trigger (per approved FR/BRL) | Related FR / BR | Status |
|---|---|---|---|---|---|
| **PaymentRecorded** | `audit_log.action = payment_added`, `follow_up_history.action_type = payment_recorded` | `PaymentService::record()` | A payment (full or partial) is recorded against a Debt | FR-034, BRL-037 | **Implemented** (recorded) |
| **DebtStatusChanged — Partial Paid / Paid** | `audit_log.action = status_changed` (generic, `user_id = NULL` — "System", per FR-037 step 4's literal text), `debt_status` | `PaymentService::recalculateDebt()` | Cumulative payments partially or fully satisfy a Debt (BRL-039) | FR-037, BRL-021 | **Implemented** (recorded) |
| **RecoveryStageChanged — Stage 6 (Recovered)** | *(reuses `status_changed`, see Recovery Workflow above)* | `PaymentService::recalculateDebt()` → `RecoveryStageService::advanceTo()` | Debt Status transitions into Paid | FR-032, FR-037, BRL-031 | **Implemented** (recorded, reused action) |
| **PromiseFulfilled** | *(see Recovery Workflow above)* | `PaymentService::record()` → `PromiseToPayService::evaluateFulfillment()` | A qualifying (any positive) payment is recorded on or before an open Promise's promised date | FR-031, FR-039, BRL-032 | **Implemented** (recorded) |
| **ReceiptGenerated** | `audit_log.action = receipt_generated`, `entity_type = payment` | `PaymentService::record()` → `DocumentService::generateReceipt()` | A payment is successfully recorded | FR-038, FR-047 | **Implemented** (recorded; real Receipt entity + PDF, Module 8) |

**Note on `ReceiptGenerated`:** FR-038 splits into a triggering/audit step (this module's job) and actual document generation (Module 8 — Documents, owned mechanics: PDF, `RCT-` Auto Numbering, the `receipts` table). Module 8 is now implemented — `PaymentService::record()` calls `DocumentService::generateReceipt()` directly (synchronous, same transaction), which creates the real `receipts` row, renders the PDF, and records both the audit entry and a `document_events` `generated` row. Per FR-047 E1 ("Receipt generation fails... Payment Recording is not rolled back"), `DocumentService::generateReceipt()` catches its own failures internally and returns `null` rather than throwing — Payment Recording always commits regardless of PDF/storage outcome. See [Documents (Module 8)](#documents-module-8) for full detail.

**Not implemented in this module (explicitly deferred, not invented):**
- **CreditScoreRecalculated (payment-driven)** — FR-039 step 1 asks this module to classify a payment as on-time/late/partial and emit that to Module 4 for scoring. Module 4's scoring computation itself remains deferred (DD-008 baseline, DD-009 point-value catalog — both still unresolved), so there is no consumer to classify for, and the approved `follow_up_history.action_type` enum has no distinct slot for the classification (only the generic `payment_recorded`). Implementing a classification with nothing to consume it, or inventing a new enum value, would both be invented behavior. See [Deferred Events](#deferred-events).
- **Overpayment capping/crediting** (DD-016) and **blocking payments against Paid/Cancelled/Written-Off Debts** (DD-017) — both explicitly unresolved; `06_Database_Design.md` §6.4 and `07_API_Design.md` §7/§15 both state the `amount` check is "positive only, no ceiling" and that the endpoint "succeeds unconditionally" pending DD-016. Implementing either would mean deciding an open Product Owner question, not implementing an approved rule.
- **Payment editing, archival, or reversal** (DD-018) — `payments` has no `updated_at`, `archived_at`, or delete path; the table is insert-only, exactly as `06` specifies pending that decision.

**Current Consumers:** Notifications (Module 10) now creates a `payment_received` Notification directly from `PaymentService::record()` (a direct synchronous call, not a subscription — see [Notifications & Calendar](#notifications--calendar-module-10)). **Future Consumers:** Reporting (Module 9, read-only over `payments`/`audit_log`), Credit & Risk (Module 4, once DD-008/DD-009 are resolved).

---

## Professional Collection (Module 7)

Recorded, tested, working code paths in `CollectionCaseService` and `ProfessionalCollectionRequestService` — each writes an `audit_log` row and, for Collection Case activity, a companion `follow_up_history` row (via the existing `FollowUpHistoryService`, extended with an optional `collection_case_id` parameter — additive, backward-compatible, every other call site unaffected). None has been given a dedicated `App\Events\*` class: every consequence below is synchronous, same-request, same-transaction, reusing an existing Service directly (`RecoveryStageService` for Stage 5, exactly like Stage 6 in Module 6) — no case here has a decoupled consumer that would justify one, the same criterion already applied in Modules 5 and 6.

| Event Name | Source Enum | Publisher | Trigger (per approved FR/BRL) | Related FR / BR | Status |
|---|---|---|---|---|---|
| **CollectionRequested** | `audit_log.action = collection_requested` | `CollectionCaseService::escalate()` | A Collection Case is created against a Debt | FR-040, BRL-045 | **Implemented** (recorded) |
| **Escalated** | `follow_up_history.action_type = escalated` | `CollectionCaseService::escalate()` | Same occurrence as CollectionRequested, recorded into the Debt's own Follow-up History/Timeline | FR-040 | **Implemented** (recorded) |
| **RecoveryStageChanged — Stage 5 (Professional Collection)** | *(reuses `status_changed`, see Recovery Workflow above)* | `CollectionCaseService::escalate()` → `RecoveryStageService::advanceTo()` | A Collection Case is created (BRL-031 Stage 5's own "Entered When" — case creation is the cause, not the effect; see the module report for the BRL-031-vs-BRL-035 circularity this resolves) | FR-032, FR-040, BRL-031, BRL-045 | **Implemented** (recorded, reused action) |
| **CollectionCaseEdited (assignment)** | `audit_log.action = edited` | `CollectionCaseService::assign()` | A Collection Officer is assigned/reassigned | FR-041 | **Implemented** (recorded) |
| **CollectionActivityLogged** | `follow_up_history.action_type = collection_activity`, `audit_log.action = edited` | `CollectionCaseService::recordActivity()` | Activity logged against an open Collection Case | FR-044, BRL-049 | **Implemented** (recorded) |
| **CollectionCaseClosed** | `audit_log.action = status_changed` | `CollectionCaseService::close()` | Collection Case closed with a recorded outcome | FR-045, BRL-050 | **Implemented** (recorded) |
| **ProfessionalCollectionRequestSubmitted** | `audit_log.action = professional_collection_request_submitted` | `ProfessionalCollectionRequestService::submit()` | A tenant submits an open Collection Case to Deendoon | FR-072, BRL-078 | **Implemented** (recorded) |
| **ProfessionalCollectionRequestStatusChanged** | `audit_log.action = professional_collection_request_status_changed` | `ProfessionalCollectionRequestService::transitionStatus()` / `close()` | The Deendoon Platform Administrator transitions a Request's status, including the terminal outcome | FR-073, FR-076, BRL-079 | **Implemented** (recorded) |

**Note on `RecoveryStageChanged — Stage 5`'s trigger direction:** BRL-035/FR-040 read as if "Debt reaches Stage 5" precedes and causes Collection Case creation, but BRL-031's own stage table defines Stage 5 as "Entered When: Debt is escalated to a Collection Case" — case creation is the cause, Stage 5 the effect, exactly the same direction already used for Stage 6 (Payment reaching Paid, Module 6). There is no other approved mechanism that independently advances a Debt to Stage 5 first. This is a genuine SRS circularity (not silently resolved) — every call to `escalate()` is treated as DD-014's "manual escalation," which is left unresolved but not forbidden.

**Not implemented in this module (explicitly deferred, not invented):**
- **Payment Added consumption into Collection Case activity** (FR-044 A1) — would require `PaymentService` (Module 6, previously approved and frozen) to look up an open Collection Case for the Debt and tag its `follow_up_history` row's `collection_case_id` — modifying an already-approved module without an explicit Product Owner instruction to do so. Flagged as a NON-BLOCKING gap, not silently wired around the boundary.
- **Credit Score deduction on broken/closed collection outcomes** — Module 4's scoring computation remains deferred (DD-008/DD-009), unchanged by this module.

**Current Consumers:** Notifications (Module 10) now creates `collection_assignment` (from `CollectionCaseService::assign()`) and `professional_collection_request_update` (from `ProfessionalCollectionRequestService::transitionStatus()/close()/postMessage()`) Notifications directly — both direct synchronous calls, not subscriptions (see [Notifications & Calendar](#notifications--calendar-module-10), including the one-way limitation on the latter). **Future Consumers:** Reporting (Module 9, Active Collection Cases / SM-006).

---

## Documents (Module 8)

Recorded, tested, working code paths in `DocumentService` — every generation writes one `audit_log` row and one `document_events` `generated` row; downloading writes a further `document_events` `downloaded` row only (no `audit_log` entry — FR-050/051's text never says "records an event in the Audit Trail," unlike FR-047/048/049). None has been given a dedicated `App\Events\*` class: generation is always a direct, synchronous call from the requesting Controller or (for Receipts) `PaymentService` — no case here has a decoupled consumer that would justify one, the same criterion already applied in Modules 5–7.

| Event Name | Source Enum | Publisher | Trigger (per approved FR/BRL) | Related FR / BR | Status |
|---|---|---|---|---|---|
| **ReceiptGenerated** | `audit_log.action = receipt_generated`, `document_events (type=receipt, event=generated)` | `DocumentService::generateReceipt()`, called by `PaymentService::record()` | A payment is successfully recorded (automatic, system-initiated only — BR-019) | FR-038, FR-047 | **Implemented** (recorded) |
| **DemandLetterGenerated** | `audit_log.action = demand_letter_generated`, `document_events (type=demand_letter, event=generated)` | `DocumentService::generateDemandLetter()`, called by `DemandLetterController::store()` | An authorized user requests a Demand Letter against a Debt, selecting one of the four approved templates (BRL-055: always explicit, never auto-selected) | FR-048 | **Implemented** (recorded) |
| **StatementGenerated** | `audit_log.action = statement_generated`, `document_events (type=statement, event=generated)` | `DocumentService::generateStatement()`, called by `StatementController` | An authorized user requests a Statement of Account, from either Customer Profile or Debt Details | FR-049 | **Implemented** (recorded) |
| **DocumentDownloaded** | `document_events (event=downloaded)` only — no `audit_log` action exists for this, matching FR-051's own text | `DocumentController::download()` | An authorized user downloads a generated document | FR-051 | **Implemented** (recorded) |

**Note on branding (BRL-054):** every generated document reads `tenants.business_name`/`logo_path`/`address`/`contact_email`/`contact_phone` directly at generation time. These ARE the approved FR-068 Company Profile fields — `06_Database_Design.md` §3 folds them into the `tenants` table rather than a separate 1:1 table — so no Module 12 lookup is needed for the data to be real; only Module 12's dedicated *management UI* for editing these fields doesn't exist yet. This satisfies the Development Roadmap's Phase 9 note ("documents are functionally complete... using placeholder/default branding, with final branding wired in during Phase 12") using the tenant's actual current values, not a fabricated placeholder string.

**Not implemented in this module (explicitly deferred, not invented):**
- **Document regeneration** (BRL-056/DD-029) — unresolved whether permitted, and if so, new row vs. reused reference number; `document_events.event_type = 'regenerated'` exists in the schema/enum but nothing writes it.
- **Watermarking, digital signatures, retention policy, tenant-configurable numbering format** (BRL-058, DD-028/030/031) — all explicitly unresolved or out of Version 1 scope; none invented.
- **Signed/pre-signed URL access** (08 §11: "Access is via short-lived, pre-signed URLs") — no real S3-compatible provider is configured in this environment (local disk only), so `GET /documents/{id}` and `.../download` stream bytes through a normal Sanctum-authenticated, policy-checked endpoint instead of a literal pre-signed URL. Every request is still individually authorized (never a static public link), satisfying the underlying security property, but not the letter of "pre-signed URL." Flagged NON-BLOCKING in the module report; revisit once real S3-compatible storage is provisioned (`Storage::disk('s3')` already exists in `config/filesystems.php` — swapping the disk is a config change, not a code change).

**Current Consumers:** `document_available` notifications are now created directly by `DocumentService` (Module 10, see below) on every generation. **Future Consumers:** Reporting (Module 9, document metadata/counts), Module 12 (once built, supplies a management UI over the same `tenants` branding fields already read here).

---

## Notifications & Calendar (Module 10)

FR-058/BRL-064: every Notification is created only as a direct, passive, *synchronous* consequence of a qualifying event already generated by an owning module — this module never originates one of its own. Six of the seven approved types (`06` §6.7's `notifications.type` CHECK, matching FR-058's precondition list plus the reopened Request-update type — see the Payment Tracking/Professional Collection sections above for that confirmation trail) are wired directly into the owning module's existing service via `NotificationService`, added as a small, additive constructor dependency each — no dispatched `App\Events\*` class was created for any of them, since none has a *decoupled* consumer distinct from the synchronous call itself (the one type that already had a dispatched event, `CreditLimitReached`, is consumed via a real Listener instead — see Credit & Risk above).

| Type | Publisher | Recipient | Related FR / BR | Status |
|---|---|---|---|---|
| **credit_limit_reached** | `CreateCreditLimitReachedNotification` listener on the existing `CreditLimitReached` event | Every admin/sales_finance user in the Customer's tenant (fan-out — no single-owner field exists on Customer) | FR-058, BR-007 | **Implemented** |
| **payment_received** | `PaymentService::record()` | The user who recorded the payment | FR-058, FR-039 | **Implemented** |
| **document_available** | `DocumentService::generateReceipt()/generateDemandLetter()/generateStatement()` | The requesting user; for the automatic Receipt case (no acting user — FR-047 is "System"-initiated), `Payment.recorded_by_user_id` | FR-058 | **Implemented** |
| **collection_assignment** | `CollectionCaseService::assign()` | The newly assigned Collection Officer (not the assigning user) | FR-058, FR-041 | **Implemented** |
| **reminder_sent** | `ReminderController` (whatsapp/sms/call) | The user who sent the manual reminder | FR-058 | **Implemented** — see note below |
| **promise_to_pay_due** | `PromiseToPayService::refreshDuePromises()`, lazily on Debt access (same pattern as `refreshOverdueStatus`/`refreshBrokenPromises`) | `PromiseToPay.created_by_user_id` | FR-058, FR-031 | **Implemented** |
| **professional_collection_request_update** | `ProfessionalCollectionRequestService::transitionStatus()/close()/postMessage()` | `ProfessionalCollectionRequest.submitted_by_user_id` (tenant side only — see note below) | FR-058, FR-073, FR-075, FR-076 | **Implemented** (one direction only) |

**Note on `reminder_sent`'s trigger:** FR-058's own Precondition list cites FR-029 (automated reminder scheduling) as the source — FR-029 remains entirely deferred (no scheduler infrastructure exists), so a strictly literal reading would leave this type permanently unreachable. This hooks into FR-030's manual reminder flow instead — the only currently-real "reminder sent" occurrence in the system — as a deliberate, flagged judgment call, not a strict implementation of that citation.

**Note on `professional_collection_request_update`'s one-way limitation:** `notifications.tenant_id` is `NOT NULL`, and the Deendoon Platform Administrator (`tenant_id IS NULL`) has no tenant to attribute a notification to. So only the tenant-facing direction is schema-valid: when the Platform Administrator changes status or posts a message, the submitting tenant user is notified. When the tenant posts a message, the reverse (notifying the Platform Administrator) cannot be represented in this schema at all — flagged as a NON-BLOCKING gap in the module report, not silently worked around or dropped.

**`notifyOnce` — a narrow mechanical safeguard, not a BRL-065 resolution:** BRL-065 (duplicate/re-trigger suppression) is explicitly unresolved (DD-011) and no general de-duplication is implemented — every type above fires every time its trigger condition occurs, matching the precedent already set for `CreditLimitReached`. The one exception is `promise_to_pay_due`: unlike the open→broken/fulfilled transitions, "due today" has no state change of its own to naturally stop a *lazy, repeatedly-polled* check from re-firing on every page view within the same day, so `NotificationService::notifyOnce` guards specifically against that — a mechanical fix for a lazy-check artifact, not a business-rule decision about repeat notifications in general.

### Calendar (FR-062/BRL-068)

Read-only aggregation, reusing existing date fields directly — no new scheduling concept, no stored copy:

| Source | Field | Included When |
|---|---|---|
| Debt Due Dates (Module 3) | `debts.due_date` | Debt is not Paid/Cancelled/Written Off |
| Promise to Pay dates (Module 5) | `promises_to_pay.promised_date` | Promise is `open` |
| Follow-up / "Call Reminders" (Module 5) | `follow_up_history.occurred_at` where `action_type IN (manual_whatsapp, manual_sms, call_logged)` | Within the requested range |

**Not aggregated (explicitly undefined, not invented):**
- **Collection Appointments** (Module 7) — BRL-068 itself flags this as unresolved (DD-036): "Collection Appointments are not a distinct schedulable entity in Module 7... exactly how a future-dated Collection Activity becomes a Calendar entry is undefined." `collection_cases` has no date field to aggregate at all.

**Current/Future Consumers:** the Notification Center and Calendar View themselves are the terminal consumers — nothing downstream of Module 10 exists yet.

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
| **CreditScoreRecalculated** | DD-008 (baseline score), DD-009 (point-value catalog, band thresholds) | Both Modules 5 and 6 now exist and supply trigger events (a broken Promise to Pay, `PromiseBroken`; an on-time/late/partial payment, Module 6), but there is still no approved formula to calculate a score with. Building any version now would mean inventing DD-008/DD-009's answers, which the Credit & Risk Module report explicitly declined to do. |

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
