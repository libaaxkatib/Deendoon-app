# Deendoon Backend AI Guide

## Project Overview

This document is the **engineering constitution** for AI contributors working in this repository. It defines *how* AI must work on Deendoon — it does not define *what* Deendoon is.

The product specification lives entirely in the SRS (`SRS/01_Project_Overview.md` through `SRS/10_Acceptance_Criteria.md`), which is the sole, authoritative source of truth for business requirements, business rules, functional requirements, UI/UX specification, database design, API design, security/RBAC, non-functional requirements, and acceptance criteria. This document does not restate, summarize, or duplicate that specification.

Core engineering principles that govern every contribution:

- The Laravel backend is the single source of truth for business logic, validation, authorization, calculations, and data integrity.
- Business rules belong in the backend only.
- The Flutter application must never duplicate business logic — it consumes backend APIs and must not reimplement any rule owned by the backend.
- All implementation must remain consistent with the approved SRS. Where this document is silent, the SRS governs.

## Engineering Principles

Every AI assistant contributing to this repository must follow these engineering principles.

### 1. SRS First

The SRS documents (01–10) are the single source of truth for product behavior. Never implement features that contradict the approved specification.

### 2. Backend Owns Business Logic

Laravel is responsible for all business rules, validation, authorization, workflows, calculations, and state transitions.

Clients (Flutter, Web, or any future client) are presentation layers only.

### 3. One Source of Truth

Never duplicate business rules across multiple layers.

When logic changes, update it in its authoritative location instead of creating parallel implementations.

### 4. Simplicity Before Cleverness

Prefer readable, maintainable code over complex abstractions.

Avoid premature optimization.

### 5. Consistency Over Preference

Follow existing project patterns unless there is a clear architectural reason to improve them.

Do not introduce a different coding style simply because it is personally preferred.

### 6. Small Safe Changes

Prefer small, reviewable, incremental changes over large rewrites.

Avoid touching unrelated files.

### 7. Production Quality

Assume every commit may eventually reach production.

Temporary solutions, placeholder implementations, commented-out code, and experimental shortcuts should never be committed unless explicitly requested.

### 8. Explain Before Refactoring

If a proposed refactor changes architecture, data flow, or public behavior, explain the reasoning before making the change.

### Rule Precedence

If guidance appears to conflict, follow this order of authority:

1. Approved SRS
2. Explicit Product Owner decisions
3. Previously approved engineering decisions
4. Engineering Principles
5. Remaining sections of this Engineering Constitution

If uncertainty remains, stop and request clarification instead of making assumptions.

## AI Working Rules

These rules apply to every AI assistant contributing to this repository.

### Understand Before Changing

Never modify code without first understanding the surrounding architecture, related modules, and the intended behavior.

Read the relevant files before proposing or implementing changes.

---

### Never Guess

If information is missing, ask for clarification.

Do not invent:

- requirements
- business rules
- APIs
- database fields
- workflows
- UI behavior
- architecture decisions

---

### Respect the SRS

The SRS is the authoritative product specification.

Implementation must always remain consistent with the approved SRS.

If implementation and SRS disagree, stop and explain the conflict before changing either.

---

### Preserve Existing Patterns

Follow existing project conventions unless there is a clear technical reason to improve them.

Avoid introducing unnecessary architectural diversity.

---

### Minimize Change Surface

Modify only the files necessary for the requested task.

Avoid unrelated refactoring.

Avoid unnecessary file renames or moves.

---

### Prefer Incremental Development

Large rewrites should be split into small, reviewable changes.

Each change should leave the project in a working state.

---

### Keep Backward Compatibility

Unless explicitly instructed otherwise:

- avoid breaking APIs
- avoid breaking database schemas
- avoid changing public contracts
- avoid changing behavior relied upon by existing clients

---

### Explain Significant Decisions

For architecture changes, database changes, public API changes, or security changes:

- explain the reasoning first
- describe the impact
- identify affected modules

---

### Never Silence Errors

Never hide exceptions simply to make code appear to work.

Fix root causes whenever possible.

---

### Security First

Never reduce security to simplify implementation.

Always prefer secure defaults.

---

### Production Mindset

Assume every change may reach production.

Avoid experimental code, placeholders, TODO implementations, and temporary shortcuts unless explicitly requested.

---

### Keep Documentation Updated

When implementation changes require documentation updates, identify the affected documents instead of silently allowing documentation to become outdated.

## Architecture Rules

### Single Source of Truth

Each responsibility must have exactly one authoritative owner.

- Business rules belong in the Laravel backend.
- The database stores persistent state.
- Flutter and future clients present data and collect user input.
- The SRS defines product behavior.
- CLAUDE.md defines engineering behavior.

Never duplicate ownership across multiple layers.

---

### Layer Responsibilities

Respect architectural boundaries.

Backend responsibilities:

- business logic
- validation
- authorization
- workflows
- calculations
- state transitions
- integrations

Frontend responsibilities:

- presentation
- navigation
- local UI state
- user interaction
- client-side performance

Do not move backend responsibilities into the client.

---

### API-First Development

All communication between clients and the backend must occur through documented APIs.

Clients must never depend on internal implementation details.

Avoid introducing hidden or undocumented endpoints.

---

### Database Discipline

Treat the database as a long-term contract.

Avoid unnecessary schema changes.

Every migration should be:

- reversible
- reviewed
- compatible with existing production data

Never modify production data through ad-hoc scripts when a proper migration is required.

---

### No Circular Dependencies

Modules should communicate through clear interfaces.

Avoid tightly coupled components.

Prefer dependency inversion over cross-module knowledge.

---

### Consistency Before Expansion

Improve existing architecture before introducing new patterns.

If multiple solutions already exist, standardize instead of adding another.

---

### Prefer Composition

Prefer composition over inheritance whenever practical.

Keep components focused on a single responsibility.

---

### Stable Public Contracts

Changes affecting:

- APIs
- events
- database schema
- shared interfaces

must be considered breaking changes unless proven otherwise.

Evaluate compatibility before implementation.

---

### Performance Is Designed

Do not optimize prematurely.

However, avoid introducing obvious scalability bottlenecks.

Design with production workloads in mind.

---

### Security Is Architectural

Security is not a later phase.

Authentication, authorization, validation, auditing, and data protection must be considered during architecture decisions, not after implementation.

---

### Every Architectural Decision Needs Justification

When proposing a significant architectural change:

- explain why it is needed
- explain the trade-offs
- identify affected modules
- describe migration requirements
- explain rollback strategy when applicable

Major architectural changes should never appear without explanation.

---

### Data Isolation

Every data access path must enforce the appropriate ownership and visibility boundaries.

Never allow queries to bypass the project's data isolation model.

Data isolation rules must be enforced consistently across:

- APIs
- services
- background jobs
- scheduled tasks
- reporting
- administrative features

Do not assume that a trusted user may access unrestricted data.

Isolation must be enforced by architecture, not by convention.

## Backend Development Rules

### Framework First

Follow official Laravel conventions and best practices.

Use Laravel's built-in features whenever they provide a clear solution.

Avoid replacing framework capabilities with custom implementations unless there is a demonstrated architectural need.

## API Standards

### API as the Public Contract

The API is the only supported interface between clients and the backend.

Clients must never rely on internal implementation details.

All communication must occur through documented APIs.

---

### Consistent Endpoints

Use predictable and RESTful endpoint naming.

Prefer nouns over verbs.

Examples:

- /customers
- /debts
- /payments
- /documents

Avoid inconsistent naming conventions.

---

### HTTP Methods

Use HTTP methods according to their intended purpose.

- GET for retrieval
- POST for creation
- PUT/PATCH for updates
- DELETE for deletion

Do not overload endpoints with multiple unrelated responsibilities.

---

### Consistent Response Structure

API responses should follow a consistent structure across the entire application.

Success responses should be predictable.

Error responses should use a standardized format.

Avoid returning inconsistent payloads for similar operations.

---

### Appropriate Status Codes

Use standard HTTP status codes correctly.

Examples:

- 200 OK
- 201 Created
- 204 No Content
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 422 Validation Error
- 500 Internal Server Error

Do not return 200 for failed operations.

---

### Validation Errors

Validation failures should clearly identify invalid fields.

Provide actionable error messages.

Avoid exposing internal implementation details.

---

### Pagination

Collections should be paginated whenever datasets may grow large.

Avoid returning unbounded result sets.

Pagination should remain consistent across endpoints.

---

### Filtering, Searching and Sorting

Filtering, searching, and sorting should follow consistent conventions.

Avoid introducing endpoint-specific query syntax.

---

### Versioning Strategy

Public APIs are contracts. Public API changes must preserve backward compatibility whenever practical, and compatibility should be evaluated before every API change.

Breaking changes should require explicit versioning or an approved migration strategy, and must never be introduced without a documented migration path for existing clients.

---

### Authentication

Protected endpoints must require authentication.

Authentication must never be optional for protected resources.

---

### Authorization

Every protected operation must enforce authorization.

---

### Idempotency

Operations that may be retried should behave safely.

Avoid duplicate resource creation caused by network retries.

---

### Documentation

Every public endpoint should be documented.

Documentation should remain synchronized with implementation.

Outdated API documentation should be treated as technical debt.

---

### Performance

Avoid unnecessary API calls.

Return only the data required for the requested operation.

Prevent N+1 problems and excessive payload sizes.

## Database Standards

### Database as the Source of Truth

The database is the authoritative source of persistent business data.

Never duplicate persistent state across multiple systems without a documented synchronization strategy.

---

### Schema First

Design schema changes carefully before implementation.

Tables, relationships, and constraints should accurately represent the business domain.

Avoid frequent structural changes after release.

---

### Migrations Only

All database schema changes must be performed through Laravel migrations.

Never modify production schemas manually.

Every migration should be reviewed before deployment.

---

### Reversible Migrations

Migrations should be reversible whenever practical.

Rollback procedures should be considered before deployment.

---

### Naming Conventions

Use consistent naming conventions throughout the database.

- snake_case for tables and columns
- singular model names
- plural table names
- descriptive foreign key names

Avoid ambiguous or abbreviated names.

---

### Primary Keys

Every table should have a stable primary key.

Avoid using business data as primary keys.

---

### Foreign Keys

Use foreign key constraints whenever appropriate.

Protect referential integrity at the database level, not only in application code.

---

### Constraints Before Code

Use database constraints where they improve data integrity.

Examples include:

- NOT NULL
- UNIQUE
- FOREIGN KEY
- CHECK constraints where supported

Do not rely exclusively on application validation.

---

### Data Integrity

Prevent invalid data from entering the system.

Validation belongs in the application.

Integrity belongs in the database.

Both are required.

---

### Soft Deletes

Use soft deletes only where business requirements justify recovery.

Do not apply soft deletes indiscriminately.

---

### Indexing

Indexes should support real query patterns.

Avoid unnecessary indexes that increase write overhead.

Review indexes as the application evolves.

---

### Query Performance

Design queries for scalability.

Avoid N+1 query patterns.

Retrieve only the required data.

Optimize based on measurement rather than assumption.

---

### Transactions

Use database transactions for operations that modify multiple related records.

Maintain consistency during failures.

---

### Auditability

Business-critical changes should be traceable.

Use audit logs where required instead of overwriting historical information.

---

### Sensitive Data

Store only the minimum sensitive data required.

Encrypt sensitive information where appropriate.

Never store passwords, API keys, or secrets in plain text.

---

### Backward Compatibility

Schema changes should minimize disruption to existing production data.

Plan data migrations carefully before introducing breaking changes.

---

### Seed Data

Seeders should create predictable development and testing data.

Production seeders should never overwrite business data.

---

### Documentation

Significant database changes should be reflected in the Database Design documentation.

Implementation and documentation must remain consistent.

## Testing Rules

### Testing Is Part of Development

Code is not considered complete until it has been appropriately tested.

Testing is a development responsibility, not a separate phase.

---

### Risk-Based Testing

The level of testing should reflect the risk of the change.

Business-critical functionality requires stronger test coverage than cosmetic changes.

---

### Test the Business Rules

Prioritize testing:

- business logic
- calculations
- workflows
- permissions
- state transitions
- financial operations

These are more valuable than testing framework internals.

---

### Prevent Regression

Every bug fix should include a regression test whenever practical.

The same defect should not be able to reappear unnoticed.

---

### Automated Tests First

Prefer automated tests over manual verification whenever practical.

Manual testing complements automation but should not replace it.

---

### Unit Tests

Use unit tests for isolated business logic.

Unit tests should be:

- fast
- deterministic
- independent
- easy to understand

---

### Integration Tests

Verify that components work correctly together.

Focus on interactions between:

- database
- services
- queues
- APIs
- authentication
- authorization

---

### API Testing

Public API endpoints should be tested for:

- success cases
- validation failures
- authorization
- authentication
- error handling
- edge cases

---

### Database Testing

Verify database behavior when testing:

- relationships
- constraints
- transactions
- soft deletes
- migrations

Avoid assuming database behavior without verification.

---

### Edge Cases

Test beyond the happy path.

Consider:

- invalid input
- missing data
- duplicate requests
- permission failures
- concurrency
- empty datasets
- unexpected sequences

---

### Reliable Tests

Tests should produce consistent results.

Avoid flaky tests that sometimes pass and sometimes fail.

---

### Independent Tests

Tests should not depend on execution order.

Each test should be able to run independently.

---

### Test Data

Use predictable and isolated test data.

Avoid dependencies on production data.

Keep fixtures simple and understandable.

---

### Performance Awareness

Critical operations should be tested for reasonable performance where appropriate.

Avoid introducing unnecessary performance regressions.

---

### Security Testing

Security-sensitive functionality should verify:

- authentication
- authorization
- input validation
- data protection

Security assumptions should be tested, not trusted.

---

### Continuous Verification

Run the relevant test suite before considering work complete.

Do not knowingly commit failing tests.

---

### Documentation

When new functionality requires new testing strategies, update the relevant documentation.

Testing guidance should evolve alongside the system.

## Security Rules

### Security by Default

Every implementation should default to the most secure reasonable option.

Security should never be treated as an optional enhancement.

---

### Never Trust Client Input

Assume all client input is untrusted.

Validate and sanitize all external data before processing.

Client-side validation improves user experience but never replaces backend validation.

---

### Authentication

Every protected resource must require authentication.

Authentication mechanisms should follow established framework best practices.

Never implement custom authentication when a secure framework solution exists.

---

### Authorization

Authentication identifies the user.

Authorization determines what the user is allowed to do.

Every protected action must verify permissions on the backend.

Never rely on the client to enforce authorization.

---

### Principle of Least Privilege

Users, services, and processes should receive only the permissions required to perform their responsibilities.

Avoid excessive privileges.

---

### Sensitive Data

Collect only the sensitive data required by the business.

Protect sensitive information both in transit and at rest.

Never expose confidential information through logs, error messages, or API responses.

---

### Secrets Management

Secrets must never be committed to source control.

Store credentials, API keys, and tokens using secure environment configuration.

Rotate secrets when compromise is suspected.

---

### Password Security

Passwords must never be stored, logged, or transmitted in plain text.

Always use secure password hashing provided by the framework.

---

### Input Validation

Validate all incoming data.

Reject invalid, unexpected, or malformed input before executing business logic.

Validation should be explicit rather than assumed.

---

### Output Encoding

Encode output appropriately for its destination.

Prevent injection vulnerabilities by treating all user-generated content as untrusted.

---

### Secure Error Handling

Error messages should assist legitimate users without exposing internal implementation details.

Avoid leaking:

- stack traces
- SQL queries
- file paths
- server configuration
- internal identifiers

---

### Logging and Auditing

Log security-relevant events where appropriate.

Examples include:

- authentication events
- authorization failures
- administrative actions
- critical data changes

Logs should support investigation without exposing sensitive information.

---

### Rate Limiting

Protect public-facing endpoints against abuse.

Apply appropriate rate limiting where repeated requests could impact security or availability.

---

### File Uploads

Treat uploaded files as untrusted.

Validate:

- file type
- file size
- allowed formats

Store uploads securely.

Never execute uploaded content.

---

### Database Security

Use parameterized queries or framework protections against SQL injection.

Avoid constructing database queries using untrusted input.

---

### API Security

Protect all APIs with appropriate authentication and authorization.

Return only the data required for the requested operation.

Avoid excessive data exposure.

---

### Dependencies

Keep dependencies up to date.

Review security advisories before introducing new packages.

Remove unused dependencies whenever practical.

---

### Security Reviews

Changes affecting authentication, authorization, payments, financial calculations, customer data, or document handling should receive additional security review before release.

---

### Incident Readiness

Security incidents should be detectable, traceable, and recoverable.

Critical systems should support auditing, investigation, and rollback where appropriate.

---

### Security Is Continuous

Security is an ongoing engineering responsibility.

Every new feature should be evaluated for potential security implications before implementation.

---

### SQL Injection Prevention

Never build SQL queries by concatenating user input.

Always use Laravel's Query Builder, Eloquent ORM, or parameterized queries.

Avoid raw SQL unless absolutely necessary.

When raw SQL is required:

- use parameter binding
- never interpolate user input into SQL strings
- validate and sanitize all inputs before execution

Every database query must be protected against SQL injection attacks.

## Documentation Rules

### Documentation Is Part of Development

Documentation is a deliverable, not an afterthought.

Work is not considered complete if implementation and documentation are inconsistent.

---

### SRS Is the Source of Truth

The SRS defines the product.

CLAUDE.md defines engineering behavior.

Implementation must remain consistent with both.

Never duplicate the SRS inside CLAUDE.md.

---

### Keep Documentation Current

Whenever implementation changes affect documented behavior, identify and update the affected documentation.

Outdated documentation is considered technical debt.

---

### Document Significant Decisions

Major engineering decisions should be documented.

Examples include:

- architecture changes
- database design changes
- API contract changes
- security decisions
- infrastructure changes

Documentation should explain both the decision and its reasoning.

---

### Avoid Redundant Documentation

Do not duplicate information across multiple documents.

Each topic should have one authoritative source.

Cross-reference existing documentation instead of copying it.

---

### Write for Future Engineers

Documentation should be understandable by someone joining the project months later.

Avoid relying on undocumented assumptions or personal knowledge.

---

### Explain Why, Not Only What

Good documentation explains:

- what changed
- why it changed
- impact on the system
- migration considerations where applicable

---

### Keep Examples Accurate

Code examples, API examples, and configuration samples should match the current implementation.

Outdated examples should be updated or removed.

---

### Consistent Terminology

Use consistent terminology throughout the project.

Avoid introducing multiple names for the same concept.

Business terms should match the approved SRS.

---

### Record Breaking Changes

Breaking changes must be clearly documented.

Include:

- affected modules
- migration requirements
- compatibility impact
- required client updates

---

### Comment with Purpose

Code should be self-explanatory whenever possible.

Comments should explain intent, assumptions, or non-obvious decisions.

Do not use comments to compensate for poor code quality.

---

### Documentation Reviews

Documentation should be reviewed whenever significant implementation changes are reviewed.

Documentation quality is part of overall code quality.

---

### Preserve History

When replacing or removing important documentation, ensure the reasoning is preserved through version control or documented migration notes.

Avoid deleting valuable project knowledge without replacement.

---

### Documentation Quality

Documentation should be:

- accurate
- concise
- consistent
- maintainable
- easy to navigate

Every document should have a clear purpose and a single authoritative responsibility.

---

### Constitutional Amendments

CLAUDE.md is the Engineering Constitution of this repository.

Changes to this document should be deliberate, reviewed, and explicitly approved by the Product Owner.

Do not modify constitutional rules casually.

Every amendment should preserve internal consistency and should not conflict with previously approved engineering principles.

## Git & Branch Rules

### Version Control Is Mandatory

All project changes must be tracked through Git.

Never bypass version control for implementation work.

---

### Small, Focused Commits

Each commit should represent a single logical change.

Avoid combining unrelated changes into one commit.

Small commits are easier to review, test, and revert.

---

### Write Meaningful Commit Messages

Commit messages should clearly describe the purpose of the change.

Prefer explaining the intent rather than listing modified files.

Avoid vague messages such as:

- update
- fix
- changes
- work in progress

---

### Protect the Main Branch

The main branch should always remain deployable.

Incomplete or unverified work should never be committed directly to the main branch.

---

### Branch Per Feature

Use a dedicated branch for each feature, bug fix, or improvement.

Avoid developing multiple unrelated changes in the same branch.

---

### Keep Branches Short-Lived

Merge completed work promptly after review.

Avoid maintaining long-running branches that frequently diverge from the main branch.

---

### Rebase Before Merge

Keep feature branches synchronized with the latest main branch before merging whenever practical.

Resolve conflicts carefully rather than automatically.

---

### Review Before Merge

Significant changes should be reviewed before merging.

Review should verify:

- correctness
- maintainability
- security
- architecture
- documentation
- testing

---

### Never Commit Secrets

Never commit:

- passwords
- API keys
- access tokens
- private certificates
- environment files containing secrets

Sensitive information belongs in secure environment configuration.

---

### Keep the Repository Clean

Do not commit:

- generated files
- temporary files
- local IDE configuration
- debug artifacts
- unnecessary binaries

Respect the project's .gitignore configuration.

---

### Preserve History

Avoid rewriting shared Git history unless absolutely necessary.

Force pushes to shared branches should be exceptional and carefully coordinated.

---

### Atomic Changes

Each pull request should solve one problem.

Avoid mixing refactoring, new features, and unrelated fixes in a single review.

---

### Resolve Conflicts Carefully

Merge conflicts should be resolved by understanding both changes.

Never discard code simply to complete a merge quickly.

---

### Verify Before Commit

Before committing, verify that:

- relevant tests pass
- code builds successfully
- documentation is updated where required
- no debugging code remains
- no sensitive information is included

---

### Release Readiness

A branch should be considered ready to merge only when:

- implementation is complete
- testing is complete
- documentation is consistent
- review feedback has been addressed
- the change meets the project's Definition of Done

## Sprint Execution Rules

### Follow the Approved Roadmap

Development should follow the approved sprint roadmap.

Do not implement future sprint functionality unless explicitly authorized.

---

### One Sprint at a Time

Focus on completing the current sprint before beginning the next.

Avoid mixing unrelated sprint objectives.

---

### Respect Sprint Scope

Implement only the functionality defined for the active sprint.

Avoid adding unplanned features, optimizations, or refactoring unless approved.

---

### No Scope Creep

Do not expand requirements during implementation.

New ideas should be documented for future consideration rather than added to the current sprint.

---

### Complete Before Progressing

A sprint is complete only when:

- implementation is finished
- testing is complete
- documentation is updated
- acceptance criteria are satisfied
- known critical defects are resolved

---

### Preserve Sprint Boundaries

Do not modify completed sprint functionality unless:

- fixing a verified defect
- addressing a security issue
- resolving a production problem
- implementing an approved change request

---

### Verify Dependencies

Before starting a sprint, confirm that all prerequisite work has been completed.

Avoid implementing features that depend on unfinished functionality.

---

### Maintain Traceability

Every implementation should be traceable to:

- a sprint
- a documented requirement
- an approved business need

Avoid undocumented work.

---

### Review Before Completion

Before marking a sprint complete, verify:

- requirements are implemented
- architecture remains consistent
- security requirements are satisfied
- tests pass
- documentation is current

---

### Communicate Blockers Early

If implementation cannot proceed because of missing requirements, technical constraints, or conflicting specifications, stop and report the blocker.

Do not make assumptions to continue development.

---

### Production Quality Every Sprint

Every completed sprint should leave the project in a potentially releasable state.

Avoid temporary implementations that require future cleanup before release.

---

### Approved Changes Only

Changes to sprint scope, priorities, or implementation strategy require explicit approval from the Product Owner.

AI assistants must never redefine sprint objectives independently.

---

### Continuous Improvement

After each completed sprint, identify opportunities to improve:

- development workflow
- code quality
- testing
- documentation
- architecture

Lessons learned should improve future sprints without changing completed requirements retrospectively.

## Things AI Must Never Do

### Never Invent Requirements

Do not create features, business rules, workflows, APIs, database fields, user behavior, or technical requirements that have not been explicitly approved.

When information is missing, ask for clarification instead of guessing.

---

### Never Contradict the SRS

Do not implement behavior that conflicts with the approved SRS.

If implementation and the SRS disagree:

- stop implementation
- identify the conflict
- explain the difference
- request clarification before proceeding

---

### Never Deviate from Approved Decisions

Engineering decisions that have been explicitly reviewed and approved become project standards.

Do not ignore, replace, redesign, optimize, or redefine them without explicit approval from the Product Owner.

If a new request conflicts with a previously approved decision:

- stop implementation
- identify the conflict
- explain both approaches
- wait for confirmation before proceeding

Never silently override an approved:

- architecture decision
- business rule
- workflow
- database design
- API contract
- coding standard
- engineering principle
- sprint scope
- project convention

When uncertainty exists, always follow the previously approved decision until a new approval is given.

---

### Never Break Public Contracts

Do not introduce breaking changes to:

- APIs
- database schemas
- shared interfaces
- events
- integrations

without explicit approval and a documented migration strategy.

---

### Never Bypass Security

Do not weaken or disable:

- authentication
- authorization
- validation
- encryption
- auditing
- logging
- security controls

for convenience or temporary implementation.

---

### Never Modify Production Data Unsafely

Do not write scripts or perform manual operations that modify production data without explicit approval and a safe rollback strategy.

Protect data integrity at all times.

---

### Never Ignore Errors

Do not suppress exceptions, ignore failures, or hide problems simply to make code appear to work.

Fix the underlying cause whenever reasonably possible.

---

### Never Commit Sensitive Information

Never expose:

- passwords
- API keys
- access tokens
- private certificates
- secrets
- confidential customer information

in source code, commits, logs, documentation, or test data.

---

### Never Circumvent Architecture

Do not bypass established architectural boundaries.

Business logic belongs in the backend.

Presentation belongs in the client.

Respect the architectural responsibilities defined by this Engineering Constitution.

---

### Never Introduce Unnecessary Complexity

Do not add:

- unnecessary abstractions
- unnecessary design patterns
- unnecessary frameworks
- unnecessary dependencies

without clear long-term value.

Prefer simplicity.

---

### Never Leave the System Inconsistent

Avoid partial implementations that leave the application in an unstable, insecure, or inconsistent state.

Every completed change should preserve overall system integrity.

---

### Never Ignore Documentation

Do not knowingly allow implementation and documentation to diverge.

Whenever implementation changes require documentation updates, identify and update the affected documentation.

---

### Never Assume Completion

Do not declare work complete unless every applicable item in the Definition of Done has been satisfied.

Completion must be verified, not assumed.

---

### When in Doubt, Stop

If requirements are unclear, specifications conflict, implementation risks introducing incorrect behavior, or an approved project decision would be violated:

- stop implementation
- explain the issue
- identify the conflict
- request clarification

Never proceed by making assumptions.

## Definition of Done

A task is considered complete only when all applicable conditions below have been satisfied.

### Requirements

- Approved requirements have been fully implemented.
- Implementation remains consistent with the SRS.

---

### Architecture

- The solution follows the project's architectural principles.
- No unnecessary complexity has been introduced.

---

### Code Quality

- Code is readable, maintainable, and consistent with project conventions.
- Unused code, debugging artifacts, and temporary implementations have been removed.

---

### Security

- Validation has been implemented.
- Authorization has been verified.
- Sensitive data is protected.
- No known security regressions have been introduced.

---

### Database

- Migrations are complete and reversible where practical.
- Database integrity has been preserved.

---

### API

- Public contracts remain consistent.
- Responses, validation, and error handling follow project standards.

---

### Testing

- Appropriate testing has been completed.
- Relevant automated tests pass.
- Regression risks have been addressed where practical.

---

### Documentation

- Required documentation has been updated.
- Implementation and documentation are consistent.

---

### Review

- Significant changes have been reviewed.
- Review feedback has been addressed.

---

### Production Readiness

The implementation is stable, secure, maintainable, and suitable for production deployment.

No known critical issues remain unresolved.

---

### Approved Decisions

Before considering work complete, verify that the implementation remains consistent with:

- approved engineering decisions
- approved architecture
- approved business rules
- approved sprint scope
- approved coding standards
- approved project conventions
- previously accepted technical decisions

If implementation deviates from any previously approved decision, stop and report the conflict before marking the task complete.

---

### Final Verification

Before closing any task, confirm that:

- requirements are satisfied
- architecture remains consistent
- security is preserved
- tests pass
- documentation is current
- approved decisions have been respected
- no unnecessary changes were introduced
- the project remains in a releasable state
- implementation does not contradict any previously approved project decision

Only then is the work considered **Done**.

---

<laravel-boost-guidelines>
=== foundation rules ===

# Laravel Boost Guidelines

The Laravel Boost guidelines are specifically curated by Laravel maintainers for this application. These guidelines should be followed closely to ensure the best experience when building Laravel applications.

## Foundational Context

This application is a Laravel application and its main Laravel ecosystems package & versions are below. You are an expert with them all. Ensure you abide by these specific packages & versions.

- php - 8.4
- laravel/framework (LARAVEL) - v13
- laravel/prompts (PROMPTS) - v0
- laravel/sanctum (SANCTUM) - v4
- laravel/boost (BOOST) - v2
- laravel/mcp (MCP) - v0
- laravel/pail (PAIL) - v1
- laravel/pint (PINT) - v1
- phpunit/phpunit (PHPUNIT) - v12

## Skills Activation

This project has domain-specific skills available in `**/skills/**`. You MUST activate the relevant skill whenever you work in that domain—don't wait until you're stuck.

## Conventions

- You must follow all existing code conventions used in this application. When creating or editing a file, check sibling files for the correct structure, approach, and naming.
- Use descriptive names for variables and methods. For example, `isRegisteredForDiscounts`, not `discount()`.
- Check for existing components to reuse before writing a new one.

## Verification Scripts

- Do not create verification scripts or tinker when tests cover that functionality and prove they work. Unit and feature tests are more important.

## Application Structure & Architecture

- Stick to existing directory structure; don't create new base folders without approval.
- Do not change the application's dependencies without approval.

## Frontend Bundling

- If the user doesn't see a frontend change reflected in the UI, it could mean they need to run `npm run build`, `npm run dev`, or `composer run dev`. Ask them.

## Documentation Files

- You must only create documentation files if explicitly requested by the user.

## Replies

- Be concise in your explanations - focus on what's important rather than explaining obvious details.

=== boost rules ===

# Laravel Boost

## Tools

- Laravel Boost is an MCP server with tools designed specifically for this application. Prefer Boost tools over manual alternatives like shell commands or file reads.
- Use `database-query` to run read-only queries against the database instead of writing raw SQL in tinker.
- Use `database-schema` to inspect table structure before writing migrations or models.
- Use `get-absolute-url` to resolve the correct scheme, domain, and port for project URLs. Always use this before sharing a URL with the user.
- Use `browser-logs` to read browser logs, errors, and exceptions. Only recent logs are useful, ignore old entries.

## Searching Documentation (IMPORTANT)

- Always use `search-docs` before making code changes. Do not skip this step. It returns version-specific docs based on installed packages automatically.
- Pass a `packages` array to scope results when you know which packages are relevant.
- Use multiple broad, topic-based queries: `['rate limiting', 'routing rate limiting', 'routing']`. Expect the most relevant results first.
- Do not add package names to queries because package info is already shared. Use `test resource table`, not `filament 4 test resource table`.

### Search Syntax

1. Use words for auto-stemmed AND logic: `rate limit` matches both "rate" AND "limit".
2. Use `"quoted phrases"` for exact position matching: `"infinite scroll"` requires adjacent words in order.
3. Combine words and phrases for mixed queries: `middleware "rate limit"`.
4. Use multiple queries for OR logic: `queries=["authentication", "middleware"]`.

## Artisan

- Run Artisan commands directly via the command line (e.g., `php artisan route:list`). Use `php artisan list` to discover available commands and `php artisan [command] --help` to check parameters.
- Inspect routes with `php artisan route:list`. Filter with: `--method=GET`, `--name=users`, `--path=api`, `--except-vendor`, `--only-vendor`.
- Read configuration values using dot notation: `php artisan config:show app.name`, `php artisan config:show database.default`. Or read config files directly from the `config/` directory.

## Tinker

- Execute PHP in app context for debugging and testing code. Do not create models without user approval, prefer tests with factories instead. Prefer existing Artisan commands over custom tinker code.
- Always use single quotes to prevent shell expansion: `php artisan tinker --execute 'Your::code();'`
  - Double quotes for PHP strings inside: `php artisan tinker --execute 'User::where("active", true)->count();'`

=== php rules ===

# PHP

- Always use curly braces for control structures, even for single-line bodies.
- Use PHP 8 constructor property promotion: `public function __construct(public GitHub $github) { }`. Do not leave empty zero-parameter `__construct()` methods unless the constructor is private.
- Use explicit return type declarations and type hints for all method parameters: `function isAccessible(User $user, ?string $path = null): bool`
- Use TitleCase for Enum keys: `FavoritePerson`, `BestLake`, `Monthly`.
- Prefer PHPDoc blocks over inline comments. Only add inline comments for exceptionally complex logic.
- Use array shape type definitions in PHPDoc blocks.

=== deployments rules ===

# Deployment

- Laravel can be deployed using [Laravel Cloud](https://cloud.laravel.com/), which is the fastest way to deploy and scale production Laravel applications.

=== tests rules ===

# Test Enforcement

- Every change must be programmatically tested. Write a new test or update an existing test, then run the affected tests to make sure they pass.
- Run the minimum number of tests needed to ensure code quality and speed. Use `php artisan test --compact` with a specific filename or filter.

=== laravel/core rules ===

# Do Things the Laravel Way

- Use `php artisan make:` commands to create new files (i.e. migrations, controllers, models, etc.). You can list available Artisan commands using `php artisan list` and check their parameters with `php artisan [command] --help`.
- If you're creating a generic PHP class, use `php artisan make:class`.
- Pass `--no-interaction` to all Artisan commands to ensure they work without user input. You should also pass the correct `--options` to ensure correct behavior.

### Model Creation

- When creating new models, create useful factories and seeders for them too. Ask the user if they need any other things, using `php artisan make:model --help` to check the available options.

## APIs & Eloquent Resources

- For APIs, default to using Eloquent API Resources and API versioning unless existing API routes do not, then you should follow existing application convention.

## URL Generation

- When generating links to other pages, prefer named routes and the `route()` function.

## Testing

- When creating models for tests, use the factories for the models. Check if the factory has custom states that can be used before manually setting up the model.
- Faker: Use methods such as `$this->faker->word()` or `fake()->randomDigit()`. Follow existing conventions whether to use `$this->faker` or `fake()`.
- When creating tests, make use of `php artisan make:test [options] {name}` to create a feature test, and pass `--unit` to create a unit test. Most tests should be feature tests.

## Vite Error

- If you receive an "Illuminate\Foundation\ViteException: Unable to locate file in Vite manifest" error, you can run `npm run build` or ask the user to run `npm run dev` or `composer run dev`.

=== pint/core rules ===

# Laravel Pint Code Formatter

- If you have modified any PHP files, you must run `vendor/bin/pint --dirty --format agent` before finalizing changes to ensure your code matches the project's expected style.
- Do not run `vendor/bin/pint --test --format agent`, simply run `vendor/bin/pint --format agent` to fix any formatting issues.

=== phpunit/core rules ===

# PHPUnit

- This application uses PHPUnit for testing. All tests must be written as PHPUnit classes. Use `php artisan make:test --phpunit {name}` to create a new test.
- If you see a test using "Pest", convert it to PHPUnit.
- Every time a test has been updated, run that singular test.
- When the tests relating to your feature are passing, ask the user if they would like to also run the entire test suite to make sure everything is still passing.
- Tests should cover all happy paths, failure paths, and edge cases.
- You must not remove any tests or test files from the tests directory without approval. These are not temporary or helper files; these are core to the application.

## Running Tests

- Run the minimal number of tests, using an appropriate filter, before finalizing.
- To run all tests: `php artisan test --compact`.
- To run all tests in a file: `php artisan test --compact tests/Feature/ExampleTest.php`.
- To filter on a particular test name: `php artisan test --compact --filter=testName` (recommended after making a change to a related file).

</laravel-boost-guidelines>
