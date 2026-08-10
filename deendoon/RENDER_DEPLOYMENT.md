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
4. At container start: `config:cache` + `view:cache`, then
   `php artisan serve --host=0.0.0.0 --port=$PORT`.

`route:cache` is deliberately **not** run — `routes/web.php`'s stub `/`
route is a closure, which `route:cache` cannot serialize; running it would
break every container boot.

`php artisan serve` is used instead of nginx+php-fpm as the simplest
reliable option for a few-day demo. This is a deliberate simplification,
not a production recommendation — revisit before any extended deployment.

## Migrations — explicit, manual step (not automated)

The `Dockerfile` does **not** run `php artisan migrate` at build or start
time. Once the Render Postgres instance and Web Service exist and env vars
are configured, migrations must be run as a separate, explicitly-approved
step (e.g. via Render's Shell/one-off job feature), not automatically on
every deploy.

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
