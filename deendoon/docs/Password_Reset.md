# Password Recovery (FR-004)

**Status:** Implemented — Sprint 1.1, Deendoon Backend Excellence Phase.

Closes the gap the Production Readiness audit (v1.4.0) flagged as a Critical
Issue: there was no way for a user to recover a forgotten password. Approved
by `03_Functional_Requirements.md` FR-004 and `08_Security_and_RBAC.md` §10
since Module 1; unimplemented until now.

---

## Endpoints

Both are unauthenticated (no `auth:sanctum`), added alongside the existing
`/register`/`/login`/`/logout` routes — flat, no `/auth/` prefix. Product
Owner decision (Deendoon Backend Excellence Phase, Sprint 1.1): the flat
convention is the one to keep; `07_API_Design.md` §5.1 has been corrected
to match (v1.2) rather than the code being changed to introduce `/auth/`.

### `POST /api/v1/forgot-password`

Rate-limited: `throttle:forgot-password` (5/minute, keyed by email+IP —
same shape as the existing `login` limiter).

**Request**
```json
{ "email": "user@example.com" }
```

**Response — always identical, regardless of whether the email exists:**
```json
{
  "success": true,
  "message": "If an account with that email exists, a password reset link has been sent.",
  "data": null,
  "errors": null
}
```
`422` only for a malformed email (missing/not-an-email-format) — never for
"email not found," which would itself leak account existence.

### `POST /api/v1/reset-password`

Rate-limited: `throttle:reset-password` (5/minute, keyed by email+IP —
defense-in-depth; the token itself is a 64-character CSPRNG string, so
brute force is infeasible regardless).

**Request**
```json
{
  "email": "user@example.com",
  "token": "the 64-character code emailed to the user",
  "password": "NewPassword123!",
  "password_confirmation": "NewPassword123!"
}
```

**Success (200):**
```json
{ "success": true, "message": "Password reset successfully", "data": null, "errors": null }
```

**Failure (422) — one generic message covers every rejection reason** (no
token on file, expired, wrong token, or unknown email):
```json
{ "success": false, "message": "This password reset token is invalid or has expired.", "data": null, "errors": null }
```

**Failure (422) — validation** (missing field, password/confirmation
mismatch, or password under the project's 12-character policy) uses the
standard `errors` object shape every other endpoint already returns.

**Failure (429)** — rate limited, same shape as every other throttled
endpoint in this project.

No response shape, status code convention, or envelope field was
introduced — every response above is the existing `{success, message,
data, errors}` shape already used everywhere in this API.

---

## Token lifecycle

| Property | Behavior |
|---|---|
| **Generation** | `Str::random(64)` — Laravel's CSPRNG-backed random string helper. |
| **Storage** | Hashed at rest (`Hash::make()`, same Argon2id-by-default hasher used for credentials) in the stock `password_reset_tokens` table — migrated since Foundation, unused until this feature. The plaintext value is never persisted anywhere and is only ever held in memory long enough to hash it and email it. |
| **Expiration** | `PASSWORD_RESET_TOKEN_EXPIRY_MINUTES` (default 60 — the upper end of `08`'s recommended 15–60 minute window), env-configurable, never hardcoded. |
| **Single-use** | The token row is deleted immediately after a successful reset. A second attempt with the same token — even before expiry — fails with the same generic error. |
| **Superseded on re-issue** | `email` is `password_reset_tokens`' own primary key; requesting a new token structurally replaces any prior one (`updateOrCreate`) rather than accumulating multiple valid tokens per account. |
| **Delivery** | Email only (`MAIL_MAILER`), synchronously — matching every other side effect in this codebase (notifications, document generation, audit logging); no queued job exists anywhere in this project, so this doesn't introduce a new, inconsistent async pattern. |

---

## Security considerations

- **User enumeration**: `forgot-password` never distinguishes "email sent" from "no such account" in its response — both return an identical `200`. `ForgotPasswordRequest` deliberately omits an `exists:users,email` validation rule, since a `422` for an unregistered email would itself be the enumeration leak. `reset-password` collapses every rejection reason (missing token, expired, wrong token, unknown email) into one generic `422` message for the same reason.
- **Deactivated accounts**: `User::where('email', ...)->first()` runs through the model's existing `SoftDeletes` global scope (`archived_at`), so a deactivated user is invisible to this lookup — `forgot-password` silently no-ops for an archived account exactly as it does for a nonexistent one, with no code change needed to get that behavior.
- **Session invalidation on reset**: a successful reset calls `$user->tokens()->delete()`, revoking every active Sanctum token — `08_Security_and_RBAC.md` §9's "Revoke all tokens: triggered automatically by password change" rule, applied here for the first time in this codebase (no prior self-service password-change endpoint existed to apply it to).
- **Audit trail**: a successful reset is recorded via the existing `AuditLogService`, reusing the `edited` action against the `user` entity (FR-004 Main Flow step 5's own text: "reuses the approved 'Edited' audit event type rather than introducing a new one").
- **Password policy**: reuses the project's global `Password::defaults()` registration (`AppServiceProvider`, 12-character minimum) — no separate or weaker policy for this flow.
- **Rate limiting**: both endpoints are throttled from day one (unlike `login`, which went unthrottled for a period before Phase 14's hardening pass) — `08` §8 explicitly names `POST /auth/forgot-password` rate limiting as a minimum requirement.

---

## Documentation vs. implementation: resolved

`07_API_Design.md` §5.1 originally documented this feature's endpoints as
`POST /auth/forgot-password` and `POST /auth/reset-password`, under an
`/auth/` path segment the already-shipped `/register`/`/login`/`/logout`
endpoints never used. Flagged at implementation time rather than resolved
unilaterally; the Product Owner has since decided (Deendoon Backend
Excellence Phase, Sprint 1.1) to keep the flat convention already in
production use. `07` §5.1 has been corrected to match (v1.2) — the `/auth/`
prefix was never adopted anywhere in this codebase.
