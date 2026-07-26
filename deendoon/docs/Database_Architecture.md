# Database Architecture — Accepted Decisions

**Status:** Product Owner decisions on record (v1.6.0 — Sprint 2.1, Database Architecture Audit).

Records two decisions arising from the Sprint 2.1 independent database audit.
Both are **acceptances of the current schema as-is** — neither requires or
authorizes a migration, schema change, or model change now or as a default
future action.

---

## Decision 1 — Mixed primary-key strategy is accepted, permanently

**`users.id` remains `bigint`. No migration to `CHAR(26)`/ULID will be
performed.** This is not a temporary compromise scheduled for future
cleanup — it is the accepted, long-term architecture for this table.

**What this means concretely:**

- Every other domain table (`tenants`, `customers`, `debts`, `payments`,
  `notifications`, `collection_cases`, `professional_collection_requests`,
  `receipts`, `demand_letters`, `statements`, `promises_to_pay`,
  `follow_up_history`, `audit_log`, `document_events`, `document_templates`,
  `system_settings`, `reference_data`, `request_messages`,
  `import_batches`, `import_rows`) uses `CHAR(26)` ULID primary keys.
  `users.id` is the one deliberate exception — verified, not incidental.
- Every "who did this" column across the schema (`recorded_by_user_id`,
  `assigned_officer_user_id`, `submitted_by_user_id`,
  `actioned_by_user_id`, `created_by_user_id`, `sender_user_id`,
  `actor_user_id`, `recipient_user_id`, `uploaded_by_user_id`,
  `audit_log.user_id`, `document_events.user_id`) remains a `CHAR(26)`
  string with **no database-enforced foreign key** to `users.id` — the
  type mismatch makes a real FK impossible without the migration this
  decision declines to make.
- The accepted compensating control is the same one already documented
  for tenant isolation (`Tenant_Isolation.md`)'s spirit: correctness for
  these columns is an application-layer responsibility (every write path
  sources the value from an authenticated `User` model, never raw
  client input), not a database-layer guarantee.

**Why this was accepted rather than fixed:** the migration this would
require is genuinely invasive relative to the problem it solves — it
touches Sanctum's `personal_access_tokens.tokenable_id` (a polymorphic
morph column), Spatie's `model_has_roles`/`model_has_permissions` (also
polymorphic), a data migration (not just a schema migration) of every
existing value in the eleven actor-reference columns above, and
`sessions.user_id`. The damage the current gap actually causes — a
possible unconstrained/orphaned actor reference — is bounded to
attribution metadata; it does not put Customer, Debt, or Payment data
integrity at risk, all of which remain fully foreign-key-protected.

**Revisit conditions:** this decision is not expected to be revisited
absent a concrete, demonstrated requirement — e.g., a real need for
enforced cascading behavior tied to user deletion, or a compliance
requirement mandating enforced referential integrity on every actor
field. A theoretical concern is not sufficient grounds to reopen it.

---

## Decision 2 — Two `CHECK` constraints remain deferred

**No `CHECK` constraint will be added to
`system_settings.professional_collection_threshold_days` or
`system_settings.soft_limit_warning_threshold` at this time.**

Every other enumerated/bounded numeric column in the schema (`recovery_stage`,
`credit_score`, every status/type enum) has a matching `CHECK` constraint;
these two currently do not — validated only at the application layer
(`UpdateSystemPreferencesRequest`: `professional_collection_threshold_days`
`min:1|max:365`, `soft_limit_warning_threshold` `min:0|max:100`).

**Why deferred rather than added now:** both columns are currently
unconsumed — no automation reads either value yet (the Recovery Policy
escalation-threshold check and the soft-limit-warning trigger are both
still unbuilt, per `docs/Domain_Events.md`'s existing note on this same
gap). Adding the constraint now would fix a real but currently
consequence-free gap in isolation from the feature that would give it
meaning. **The `CHECK` constraint is to be added alongside whichever
future module actually implements the corresponding automation**, so the
constraint and its consumer are designed and validated together, rather
than being a speculative addition today.

**Revisit condition:** this decision is automatically superseded — not
merely eligible for review — the moment either automation feature is
built. Implementing the automation without also adding the matching
`CHECK` constraint at that time would leave the very gap this decision
explicitly earmarked for closure still open.

---

## Source

Both decisions arise directly from the Sprint 2.1 Database Architecture
Audit (independent audit, verified against the live PostgreSQL schema via
`information_schema`/`pg_indexes`, not from documentation claims). See that
audit's Sections 5 (Primary Key Strategy) and 8 (Constraint Review) for the
full evidence and reasoning behind each. Neither decision reopens or
contradicts any other finding in that audit.
