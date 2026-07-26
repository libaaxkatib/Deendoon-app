# Security

**Status:** Sprint 1.2 — Security Hardening, Deendoon Backend Excellence Phase.

Consolidates the backend's security posture in one place. Doesn't restate
`08_Security_and_RBAC.md` in full — that remains the source of truth for
approved requirements; this document describes how the codebase currently
implements them, plus what this sprint added. See also
[Tenant_Isolation.md](./Tenant_Isolation.md) (multi-tenant isolation
strategy) and [Password_Reset.md](./Password_Reset.md) (FR-004 detail).

---

## Authentication Security

- **Mechanism:** Laravel Sanctum, Bearer token mode (not cookie/SPA mode) — matches `07_API_Design.md` §2 for a native mobile client (Flutter) plus a separate web app (React).
- **Login** (`POST /login`): email + password, Argon2id-hashed credential check (`Hash::check()`), issues a Sanctum token, writes a `login` `audit_log` entry. A failed attempt (wrong password or unknown email) returns a generic `401 Invalid credentials` — the same message either way, so a client cannot distinguish "wrong password" from "no such account" — and is now also written to the `security` log channel (Sprint 1.2) for brute-force monitoring, independent of the per-email+IP rate limiter (`throttle:login`, 5/minute).
- **Logout** (`POST /logout`): deletes only the current token (`$user->currentAccessToken()->delete()`) — other devices/sessions are untouched, matching 08 §3/§9. Writes a `logout` `audit_log` entry.
- **Sanctum configuration** (`config/sanctum.php`): `expiration` is `null` — Sanctum's own fixed-TTL-from-creation expiry is intentionally unused in favor of the sliding idle timeout below, which is a different (and here, the actually-required) expiry model. `guard => ['web']` and the stateful-domains list are stock, used only for the (unused-by-the-API) session-cookie path.
- **Idle timeout** (`EnsureTokenIsNotIdle` middleware, Phase 14): a token unused for `SANCTUM_IDLE_TIMEOUT` minutes (default 60) is revoked (deleted) on its next use, returning `401`. Sliding — every request that passes extends the window, since it lets Sanctum's own existing `last_used_at` update happen afterward rather than tracking a separate expiry timestamp. **Verified this sprint**: prepended to the *global* middleware stack, ahead of the general `api` rate limiter — the limiter's own `$request->user()` call would otherwise silently refresh `last_used_at` before the idle check ever read it (this exact bug was caught and fixed during Phase 14's own implementation; re-confirmed still correct here). A revocation is now also written to the `security` log channel (Sprint 1.2).
- **Token revocation** — 08 §9's "revoke all tokens" rule (`$user->tokens()->delete()`) is enforced at every trigger point that rule names:
  - Password change (FR-005-equivalent, via forgot-password) — `PasswordResetService::reset()`, since Sprint 1.1.
  - Role change (FR-067) — `AdminUserService::assignRole()`, **added this sprint** (was previously missing — flagged by the independent audit).
  - Account deactivation (FR-066) — `AdminUserService::deactivate()`, **added this sprint** (same gap).
- **Password reset flow** (FR-004) — see [Password_Reset.md](./Password_Reset.md) in full. Verified this sprint: enumeration-safe (identical responses regardless of account existence), single-use, hashed at rest, env-configurable expiry, revokes all sessions on success.
- **Password policy consistency** — every password-accepting endpoint (`RegisterRequest`, `CreateUserRequest`, `UpdateUserRequest`, `ResetPasswordRequest`) validates against `Password::defaults()`, and only one place defines what that resolves to (`AppServiceProvider::boot()`: `Password::min(12)`) — verified this sprint that no Request defines its own, divergent rule.

---

## Password Security

| Property | Value |
|---|---|
| Hashing algorithm | Argon2id (`config/hashing.php` — `'driver' => 'argon2id'`), bcrypt retained only as a compatibility fallback, never the default. |
| Minimum length | 12 characters (`AppServiceProvider`), no mandatory composition rules — current OWASP/NIST guidance per 08 §10. |
| Storage | `users.password`, cast `'hashed'` (Laravel's automatic hash-on-set cast) — a value is hashed exactly once, on assignment. **Known historical bug class, now guarded against**: several services were once found calling `Hash::make()` *before* assigning to `$user->password`, double-hashing and silently breaking login; every current call site (`AuthController::register()`, `AdminUserService::create()/update()`, `PasswordResetService::reset()`) assigns the plain value directly and relies on the cast. |
| Reset token | `Str::random(64)` (CSPRNG), hashed at rest, single-use, env-configurable expiry — see [Password_Reset.md](./Password_Reset.md). |
| Never logged | No password, plaintext reset token, or hash value appears in any log line this codebase writes — including the new `security` channel, which logs only identifiers (email, user id, IP, route). |

---

## Token Lifecycle

```
createToken()  →  used on every authenticated request (last_used_at refreshes)
                        │
                        ├─ idle > SANCTUM_IDLE_TIMEOUT minutes ──→ revoked (401), logged
                        ├─ logout ─────────────────────────────→ revoked (current token only)
                        ├─ password reset succeeds ─────────────→ ALL tokens revoked
                        ├─ role changed ─────────────────────────→ ALL tokens revoked   (Sprint 1.2)
                        └─ account deactivated ──────────────────→ ALL tokens revoked   (Sprint 1.2)
```

No token is ever "expired but recoverable" — every revocation path is a real `DELETE` on `personal_access_tokens`, matching 08 §9: "revoked tokens are never reusable... a deleted token fails authentication with 401, not a soft 'expired' state."

---

## Security Events

Two distinct logs exist, deliberately kept separate (09 §8: "application/error logs capture operational events for debugging; `audit_log` captures approved business events for accountability"):

### `audit_log` (database, immutable, `06` §6.9's approved catalog)

| Event | Action | Since |
|---|---|---|
| Login success | `login` | Phase 14 |
| Logout | `logout` | Phase 14 |
| Password reset completed | `edited` (entity: `user`) | Sprint 1.1 |
| Role changed | `role_changed` | Module 12 |
| User created/updated/deactivated | `created`/`edited`/`archived` | Module 12 |

### `security` log channel (file, `storage/logs/security.log`) — **new this sprint**

For events with no approved `audit_log.action` slot — adding one would be a database schema change, out of this sprint's scope. Written by the new `SecurityEventLogger` service:

| Event | Trigger | Level |
|---|---|---|
| `login_failed` | Wrong password or unknown email at `POST /login` | warning |
| `password_reset_requested` | `POST /forgot-password`, regardless of whether the email exists (the *response* stays identical either way — only the log differs) | info |
| `token_revoked_idle` | `EnsureTokenIsNotIdle` revokes a stale token | info |
| `permission_denied` | Any `403` from `$this->authorize()`/`Gate::authorize()`, centrally logged from the `AccessDeniedHttpException` handler in `bootstrap/app.php` rather than instrumenting every controller action individually | warning |

Configurable independently via `SECURITY_LOG_LEVEL` (default `info`).

---

## HTTP Security

- **Response headers** (`SecurityHeaders` middleware, new this sprint, global): `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` on every response; `Cache-Control: no-store, private` on every *authenticated* response (every endpoint behind `auth:sanctum` returns tenant-scoped financial/PII data that must never be cached by a shared proxy or left in a browser's disk cache).
- **CORS** (`config/cors.php`): scoped to `api/*` and `sanctum/csrf-cookie` only; origins come from `CORS_ALLOWED_ORIGINS` (now documented in `.env.example` — previously present in code but undocumented, which would surface as a browser-side CORS error with no server-side symptom on a fresh deployment); `supports_credentials` stays `false` since auth is Bearer-token, not cookie-based.
- **Trusted proxies** (`bootstrap/app.php`, new this sprint): opt-in via `TRUSTED_PROXIES`. Unset (the default) preserves existing behavior exactly — no proxy trusted, `$request->ip()` resolves the direct connection. **Must be set in any deployment behind a reverse proxy or load balancer** — otherwise every IP-keyed rate limiter in this project (login, register, forgot-password, reset-password, and the general `api` limiter's unauthenticated fallback) resolves to the proxy's IP for every request, silently defeating all of them. This is an infrastructure detail the application code has no basis to assume — see **Product Owner Decisions Required** below.
- **HTTPS**: assumed at the infrastructure/TLS-termination layer (08 §12), not enforced in application code — forcing it here would be redundant with normal reverse-proxy/load-balancer TLS termination and could break local HTTP development.

---

## Authorization

Every controller action that isn't intentionally public (register, login, forgot-password, reset-password) or intentionally self-scoped-by-query (Notifications, Search, and Professional Collection Requests' `index()` — each documented in its own class where this applies) calls `$this->authorize()` or `Gate::authorize()`. Verified this sprint by cross-checking every controller's method count against its authorization-call count — no gap found. The one consistency fix made: a `$this->authorize()`/`Gate::authorize()` denial (`AuthorizationException`) previously fell through to Laravel's default JSON error shape instead of this project's `{success, message, data, errors}` envelope — the one exception type among `ValidationException`/`AuthenticationException`/`ThrottleRequestsException` that had been missed when those three were given this treatment in Phase 14. Fixed by registering a handler for `AccessDeniedHttpException` (the exception Laravel's own `Handler::prepareException()` converts `AuthorizationException` into *before* any render callback runs — a callback type-hinted for `AuthorizationException` itself never matches).

---

## Deployment Security Checklist

Beyond `11_Development_Roadmap.md` §7/§8's existing Deployment/Production Readiness Checklists:

- [ ] `APP_ENV=production`, `APP_DEBUG=false` (documented in `.env.example` since Phase 14 — verify the *real* production `.env` actually sets these, not just the template).
- [ ] `CACHE_STORE=redis`, `QUEUE_CONNECTION=redis` (documented recommendation in `.env.example` since Phase 14 — the zero-infrastructure `database` defaults are for local dev only).
- [ ] **`TRUSTED_PROXIES` set to the actual load balancer/reverse proxy IP range for this deployment.** Product Owner Decision (Sprint 1.2): this value is never hardcoded in application code and ships empty in `.env.example` by default — the application will not guess it. **Configuring `TRUSTED_PROXIES` correctly for the real network topology is production infrastructure's responsibility**, not something this codebase decides on its behalf. Left unset, every IP-keyed rate limiter in this project (login, register, forgot-password, reset-password, and the general `api` limiter's unauthenticated fallback) resolves the proxy's IP instead of the real client's in any deployment that sits behind a reverse proxy or load balancer — silently defeating all of them. Set incorrectly (trusting a proxy that isn't actually there), a client could spoof its own IP via `X-Forwarded-For` and evade the same limiters in the opposite direction. Both failure modes are infrastructure configuration errors, not application bugs.
- [ ] `CORS_ALLOWED_ORIGINS` set to the real Super Admin Web Dashboard origin(s) — empty by default.
- [ ] `SESSION_SECURE_COOKIE=true` if the (Sanctum-adjacent, low-usage) session cookie path is reachable at all in production.
- [ ] `SANCTUM_IDLE_TIMEOUT`, `PASSWORD_RESET_TOKEN_EXPIRY_MINUTES`, `API_RATE_LIMIT_PER_MINUTE` reviewed against actual measured traffic, not left at their conservative defaults indefinitely.
- [ ] `SECURITY_LOG_LEVEL` and the `security` log channel's output (`storage/logs/security.log`) wired into whatever log aggregation/alerting the deployment uses — 08 §13's "periodic review... for anomalous patterns" recommendation is only actionable if someone/something is actually watching this file.
- [ ] PostgreSQL Row-Level Security: intentionally deferred for Version 1 — see [Tenant_Isolation.md](./Tenant_Isolation.md). Confirm this remains the Product Owner's position at each subsequent release, per the Production Readiness Checklist's explicit requirement that this not be "left silently unresolved."
- [ ] Backup restore verified at least once in a non-production environment (§8 of the Roadmap) — not something this sprint's code changes can satisfy; an operational action.

---

## Product Owner Decisions Resolved

**`TRUSTED_PROXIES` (Sprint 1.2).** Decision: never hardcode a trusted proxy address in application code; keep the setting entirely environment-driven; leave the shipped default empty. **Production infrastructure — whoever provisions and deploys the real environment — is responsible for setting `TRUSTED_PROXIES` correctly for that deployment's actual network topology** (reverse proxy, load balancer, or none). The application will not guess, default to `*`, or otherwise assume a value on infrastructure's behalf. No code changes were needed to implement this decision — `bootstrap/app.php`'s opt-in `trustProxies()` call and `.env.example`'s empty default already matched it; only the documentation (here and `.env.example`) was tightened to state this explicitly.
