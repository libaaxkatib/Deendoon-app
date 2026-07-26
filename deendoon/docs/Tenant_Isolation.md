# Tenant Isolation Strategy

**Status:** Product Owner decision on record (Phase 14 — Production Readiness).

## Decision

**PostgreSQL Row-Level Security (RLS) is intentionally NOT implemented for Version 1.**

`06_Database_Design.md` §2 has, since it was first written, described RLS as a
*recommended second layer* — "in addition to, never instead of" application-layer
`tenant_id` filtering — with adoption explicitly left as "a Product Owner
decision, not something this document settles unilaterally." That decision has
now been made: **Version 1 relies exclusively on application-level tenant
isolation.** RLS is deferred to a future major version, not abandoned — the
policy table `06` §2 already specifies (relationship-scoped bypasses for
`professional_collection_requests`, `request_messages`, `collection_cases`,
`debts`, `tenants`, `audit_log`) remains valid and ready to adopt later without
any schema change, since it was designed against the schema exactly as built.

## What Version 1 relies on instead

Tenant isolation is enforced entirely at the application layer, through four
independent, already-implemented controls:

1. **Global scopes** — `App\Models\Concerns\BelongsToTenant` applies a
   mandatory `WHERE tenant_id = ?` to every query against every tenant-owned
   model, and auto-assigns `tenant_id` on `creating()`. It fails closed for a
   null-tenant actor (the Deendoon Platform Administrator): the filter is
   still applied using their `tenant_id` (`NULL`), which no tenant-owned row
   ever satisfies — hiding every tenant's data by default rather than
   bypassing the filter. Every model in `app/Models/` uses this trait except
   the one deliberately-bimodal case (`ProfessionalCollectionRequest`, scoped
   by hand — see its own docblock) and `Tenant`/`User` (the tenancy boundary
   and its cross-tenant actor).
2. **Policies** — every tenant-scoped Eloquent model has a corresponding
   Policy (`app/Policies/`) enforcing role-based authorization on top of the
   tenant scope, registered in `AppServiceProvider::boot()`.
3. **Middleware** — `auth:sanctum` resolves `tenant_id` server-side from the
   authenticated session on every request; `07_API_Design.md` §2's rule that
   `tenant_id` is never accepted from client input is unchanged and is what
   the global scope reads from.
4. **Authorization** — the established masking rule (404, never 403, for a
   resource that exists but belongs to another tenant) is applied
   consistently across every Controller, so a cross-tenant probe cannot even
   distinguish "doesn't exist" from "exists but isn't yours."

## Compensating control

Per the Roadmap's own risk register (`11_Development_Roadmap.md` §9): *"if RLS
is not adopted, document the compensating control (mandatory code-review
checklist item for tenant scoping on every query)."* That checklist item is
this: **every new query against a tenant-owned table must use a model that
applies `BelongsToTenant`, or, where a model is deliberately unscoped (as
`ProfessionalCollectionRequest` is), must have its tenant-vs-platform-admin
visibility rule reviewed by hand at the point of query construction** — not
assumed safe by default the way an `RLS`-backed table would be. This is a
process control, not a technical one, and is the explicit trade-off of
deferring RLS: a single missed `tenant_id` filter in application code is not
caught by a second database-level layer in Version 1.

## Revisiting this decision

Nothing about deferring RLS requires revisiting the schema — `06` §2's policy
table can be adopted as-is whenever a future major version's Product Owner
decides the risk profile (data volume, insider-threat model, compliance
requirement) justifies the added operational complexity of managing RLS
policies alongside applic­ation-layer scoping.
