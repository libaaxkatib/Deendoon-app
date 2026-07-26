# Performance Architecture — Accepted Decisions & Approved Future Work

**Status:** Product Owner decisions on record (v1.7.0 — Sprint 3.1, Performance & Scalability Audit).

Records the outcome of the Sprint 3.1 audit: the current fully-synchronous
architecture is accepted as-is, and two specific, narrow engineering
improvements are approved for a **future** implementation sprint — not
implemented now. Neither approval authorizes queue infrastructure.

---

## Decision — Synchronous architecture accepted; no async infrastructure

**The backend remains fully synchronous.** No queue, no Redis, no Horizon,
no background worker, no scheduled task will be introduced as a general
architectural change. This was independently audited (Sprint 3.1) against
every long-running operation in the codebase — receipts, notifications,
imports, reports, audit logging, email — and found, with evidence, not to
need any of that machinery today.

**Why:** every operation reviewed executes in low tens of milliseconds of
real work, at concurrency and data-volume levels realistic for this
product (SME back-office staff, tenant-isolated data growth). Introducing
queue infrastructure now would add real operational surface (worker
processes, retry/idempotency design, failure monitoring) with no
demonstrated problem for it to solve. See the Sprint 3.1 audit report in
full for the complete evidence trail across every candidate evaluated.

**What remains explicitly out of scope, unchanged by this decision:** SMS/
WhatsApp real delivery, Email at scale, and Customer Import background
processing were each identified as the kind of feature that *would*
justify async infrastructure — but only once that feature is actually
approved and built, not speculatively ahead of it. Nothing here approves
building any of those now.

---

## Approved future engineering improvements

Both approved for a **future implementation sprint**. Neither is
implemented as part of this decision — this section exists so that future
sprint can proceed directly to implementation without re-deriving the
audit's reasoning.

### 1. Move receipt generation outside the database transaction

**Current state:** `PaymentService::record()` calls
`$this->documents->generateReceipt($payment)` from *inside* the
`DB::transaction()` closure that also updates `debts.remaining_balance`/
`debt_status` and `customers.outstanding_balance`. PDF rendering (DomPDF)
and the resulting disk write happen while row-level locks on the affected
Debt/Customer rows are held open.

**Approved change:** call `generateReceipt()` after the transaction
commits, not inside it. `DocumentService::generateReceipt()` already
catches its own failures internally and returns `null` rather than
throwing (FR-047 E1 — "Receipt generation fails... Payment Recording is
not rolled back") — that guarantee must be preserved exactly; moving the
call outside the transaction doesn't change it, since the receipt was
already designed to never affect whether the payment itself commits.

**Explicitly not approved as part of this:** queuing receipt generation.
This is a same-request, synchronous reordering — the response still
waits for the receipt to finish generating, exactly as today. Only the
transaction boundary changes.

**Why this matters:** removes the coupling between PDF-render latency and
financial-write lock duration — real under concurrent writes to the same
Debt/Customer (a rare access pattern for this product, but the fix is low
-risk enough to be worth doing regardless of how rarely it bites).

### 2. Bound/stream Statement generation's data loading

**Current state:** `DocumentService::generateStatement()` loads a
Customer's entire Debt and Payment history unbounded —
`$customer->debts()->withTrashed()->get()` and
`$customer->payments()->with('debt')->get()`, with no limit, date range,
or chunking. Statement generation is the one document type whose cost
scales with a single Customer's cumulative history rather than with a
single transaction's bounded dataset.

**Approved change:** replace the unbounded `->get()` calls with an
appropriate bounding strategy — a chunked/lazy read (`chunk()`/`cursor()`/
`lazy()`) if the full history must still be included in one Statement, or
a reasonable lookback window if partial history is acceptable. **Which of
these is correct is itself a decision for the implementing sprint to
make** against FR-049's actual requirement (a full-account Statement, per
its Main Flow) — this document does not pre-decide that; it only records
that the unbounded load is the approved target for whatever bounding
strategy is chosen.

**Explicitly not approved as part of this:** queuing Statement generation.
The fix is to bound what's loaded, not to defer when it's loaded.

**Why this matters:** the current implementation's memory cost is
unbounded by the business domain — a sufficiently long-lived, high-volume
Customer relationship could make one Statement request meaningfully more
expensive than any other single request this system serves.

---

## Source

Both improvements and the synchronous-architecture decision arise directly
from the Sprint 3.1 Performance & Scalability Audit (independent audit,
evidence-driven, no load test performed — see that report's Sections 6
and 16 for the full reasoning, cost estimates, and risk classification
behind each). This document does not restate the audit's evidence in
full; it records only the decisions and enough implementation-relevant
detail for a future sprint to act on them without re-reading the whole
audit first.
