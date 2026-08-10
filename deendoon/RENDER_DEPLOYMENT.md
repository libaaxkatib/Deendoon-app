# Render Deployment — Short-Term Customer Demo

This document is preparation only. No Render infrastructure has been created.
It records the decisions and exact environment variables needed once a Web
Service and PostgreSQL instance are manually created and approved.

## Scope (approved decisions)

- Target: a short-term customer demo lasting a few days, not a production
  deployment.
- Architecture: Flutter Customer APK → HTTPS → Render Web Service → Render
  PostgreSQL. No Worker, no Redis, no Cron — the backend is intentionally
  synchronous (see `docs/Performance_Architecture.md`); nothing in the
  codebase dispatches a queued job or registers a scheduled task.
- Storage: local disk storage (`Storage::disk('local')`) is kept exactly as
  implemented. Uploaded/generated files (attachments, receipts, demand
  letters, statements, invoices, tenant logos) are **not persistent** across
  a Render restart/redeploy — accepted for this demo's timeframe, not
  changed here.

## Database connection strategy — no code change

`config/database.php`'s `pgsql` connection already reads a full connection
string via `'url' => env('DB_URL')` (Laravel's standard `parseConfig` DSN
support). Render does not require environment variable names to match a
fixed convention for manually-created variables — when the Render Postgres
instance is created, its "Internal Database URL" (or "External Database
URL" if the web service and database aren't in the same region) can be
pasted as the value of a Render environment variable literally named
`DB_URL`, and the existing application code will pick it up unmodified.

**No change to `config/database.php` or `DB_URL` naming was made or is
required.**

## Environment variables to configure at deploy time

Names only — populate real values directly in the Render dashboard, never
in this file or in a commit.

| Variable | Required | Notes |
|---|---|---|
| `APP_NAME` | Yes | e.g. `Deendoon` |
| `APP_ENV` | Yes | `production` |
| `APP_KEY` | Yes | Generate once via `php artisan key:generate --show` locally and paste the output — do not regenerate after data exists |
| `APP_DEBUG` | Yes | `false` |
| `APP_URL` | Yes | The Render service's `https://...onrender.com` URL |
| `DB_CONNECTION` | Yes | `pgsql` |
| `DB_URL` | Yes | Render Postgres connection string — see strategy above |
| `DB_SSLMODE` | Recommended | `require` if connecting cross-region/externally; Render same-region internal connections typically don't need it — confirm against the created instance |
| `CACHE_STORE` | No | Defaults to `database`, already safe for a single instance |
| `QUEUE_CONNECTION` | No | Defaults to `database`; unused (no `ShouldQueue` jobs exist) |
| `MAIL_MAILER` | Only if password reset must actually deliver email | Defaults to `log` (no real send) |
| `MAIL_HOST` / `MAIL_PORT` / `MAIL_USERNAME` / `MAIL_PASSWORD` / `MAIL_FROM_ADDRESS` / `MAIL_FROM_NAME` | Only if `MAIL_MAILER` is set to a real transport | |
| `CORS_ALLOWED_ORIGINS` | No | Only relevant to the separate React admin dashboard; the Flutter app is a native HTTP client, not subject to browser CORS |

## Build / start strategy (`Dockerfile`)

Render requires Docker for PHP/Laravel (confirmed against Render's own
deployment docs — there is no native PHP runtime). The `Dockerfile` in this
directory:

1. Builds Vite assets in a `node:20-alpine` stage (`npm install
   --ignore-scripts && npm run build`, matching `composer.json`'s own
   `setup` script) — only needed so the stub `/` welcome route doesn't
   throw a Vite-manifest error; the API itself doesn't depend on it.
2. Installs PHP 8.3 with `pdo_pgsql` and the other required extensions.
3. Runs `composer install --no-dev --optimize-autoloader`.
4. At container start: `migrate --force`, then `config:cache` +
   `view:cache`, then `php artisan serve --host=0.0.0.0 --port=$PORT` —
   see "Migrations" below for why the migrate step was added.

`route:cache` is deliberately **not** run — `routes/web.php`'s stub `/`
route is a closure, which `route:cache` cannot serialize; running it would
break every container boot.

`php artisan serve` is used instead of nginx+php-fpm as the simplest
reliable option for a few-day demo. This is a deliberate simplification,
not a production recommendation — revisit before any extended deployment.

## Migrations — run automatically at container start (`migrate --force`)

**Incident record:** the original design here ran migrations as a manual,
separate step. In practice this was forgotten after the first successful
deploy — the Render Postgres instance had no tables applied, and because
`SESSION_DRIVER=database`/`CACHE_STORE=database` are this app's actual
defaults, nearly every request (including the bare `/` route) touches the
database, so the app returned HTTP 500
(`SQLSTATE[42P01]: Undefined table: relation "sessions" does not exist`)
on every request until this was diagnosed. Render Free also has no Shell
access to run `php artisan migrate` as a one-off command, which made the
manual-step design worse in practice than intended. The `Dockerfile`'s
`CMD` now runs `php artisan migrate --force` before `config:cache`/
`view:cache`/`serve`, so this cannot be forgotten again.

This is safe to run on every boot/restart/redeploy, not just the first:
- `php artisan migrate` only applies migrations not yet recorded in the
  `migrations` table — a no-op (fast, no schema change) once everything
  is already applied. It is never `migrate:fresh`/`migrate:refresh` and
  never drops, resets, or wipes anything.
- Every migration in `database/migrations/` is additive-only in its
  `up()` method (create table / add column / add constraint) — verified
  by inspecting all 71 files; none contain `dropColumn`, `dropIfExists`,
  `truncate`, or destructive raw SQL in `up()`.
- The one migration that inserts data
  (`2026_08_21_090800_seed_platform_owned_subscription_and_storage_rejection_reasons.php`)
  is hand-written idempotent (existence-check then insert-or-update, by
  its own docblock) specifically so it's safe to be part of the
  always-runs-on-migrate path.
- `--force` is required and correct here because `APP_ENV=production`
  blocks `migrate` without it — this was already anticipated, not a new
  risk introduced by automating the step.

Trade-off accepted knowingly: this couples container boot to migration
success (a failing migration would now block `serve` from starting,
where previously it would have failed as an isolated, separately-run
step). Given every current migration is additive-only and this project's
Render deployment is single-instance (Free tier, no autoscaling), this
was judged an acceptable trade against the demonstrated real-world risk
of the manual step being forgotten.

## Worker / Redis / Cron

Confirmed not required — no code in this repository implements
`ShouldQueue`, dispatches a job, or registers a scheduled task
(`docs/Performance_Architecture.md` documents this as a deliberate
architecture decision, not an oversight). Do not add a Render Background
Worker, Key Value (Redis) instance, or Cron Job for this demo.

## Flutter build command (once the Render URL exists)

```
flutter build apk --dart-define=API_BASE_URL=https://<render-service>.onrender.com/api/v1
```

No code change is required to support this — `lib/core/config/env.dart`
already reads `API_BASE_URL` via `String.fromEnvironment` at build time.
