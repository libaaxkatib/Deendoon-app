<?php

namespace App\Providers;

use App\Models\CollectionCase;
use App\Models\CollectionCaseAttachment;
use App\Models\Customer;
use App\Models\CustomerAttachment;
use App\Models\Debt;
use App\Models\DebtAttachment;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\Notification;
use App\Models\ProfessionalCollectionRequest;
use App\Models\Receipt;
use App\Models\Reminder;
use App\Models\Statement;
use App\Models\SupportTicket;
use App\Models\SupportTicketAttachment;
use App\Models\Tenant;
use App\Models\User;
use App\Policies\CollectionCaseAttachmentPolicy;
use App\Policies\CollectionCasePolicy;
use App\Policies\CustomerAttachmentPolicy;
use App\Policies\CustomerPolicy;
use App\Policies\DebtAttachmentPolicy;
use App\Policies\DebtPolicy;
use App\Policies\DemandLetterPolicy;
use App\Policies\InvoicePolicy;
use App\Policies\NotificationPolicy;
use App\Policies\ProfessionalCollectionRequestPolicy;
use App\Policies\ReceiptPolicy;
use App\Policies\ReminderPolicy;
use App\Policies\StatementPolicy;
use App\Policies\SupportTicketAttachmentPolicy;
use App\Policies\SupportTicketPolicy;
use App\Policies\TenantPolicy;
use App\Policies\UserPolicy;
use App\Services\SubscriptionService;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Version 1 authentication model (RBAC Architecture Amendment,
        // Product Owner Decision, 2026-07-30): exactly two account types
        // exist — Business Owner (role `admin`) and Platform
        // Administrator (role `deendoon_platform_administrator`,
        // tenant_id null). 'sales-finance-only' and 'customer-only' were
        // removed along with the 'sales_finance'/'customer' roles they
        // gated — neither role exists as an authentication concept.
        Gate::define('admin-only', fn (User $user): bool => $user->hasRole('admin'));

        // Module 9 — Reporting. Reports are a Business Owner capability.
        // Also reused, unmodified, by CalendarController and two
        // DocumentController endpoints (list/storage-usage) that are not
        // part of the Reporting module — deliberately NOT extended with
        // the analytics_enabled check below, see 'view-analytics'.
        Gate::define('view-reports', fn (User $user): bool => $user->hasRole('admin'));

        // Backend Completion Roadmap, Phase 4.4 — Feature & Read-Only
        // Enforcement, Product Owner Decision (2026-08-06): "analytics_enabled
        // represents access to reporting and analytics as a whole... Apply
        // Feature Enforcement to the Reporting module (all reports/*
        // endpoints and their exports). Do not gate unrelated dashboard or
        // operational endpoints." A dedicated Gate, not an extension of
        // 'view-reports' above — 'view-reports' is also reused by
        // CalendarController and two DocumentController endpoints that are
        // NOT part of the Reporting module and must stay unrestricted by
        // plan; extending 'view-reports' itself would have collaterally
        // gated those too. app(SubscriptionService::class) resolves lazily
        // at Gate-check time (this closure runs long after boot()),
        // matching the existing pattern of every other Gate defined here.
        // Used only by ReportController's endpoints — Product Owner
        // clarification (2026-08-06): Business Health, dashboard KPIs,
        // Today's Overview, and Recent Cases are explicitly NOT gated by
        // this (they remain available on every plan, including Free) —
        // see DashboardController's methods, none of which use this Gate.
        Gate::define('view-analytics', fn (User $user): bool => $user->hasRole('admin')
            && app(SubscriptionService::class)->analyticsEnabled($user->tenant));

        // FR-053 explicitly names "system-wide" as a role-dependent
        // Dashboard variant — the only report in this module with that
        // property — so the Deendoon Platform Administrator (Module 7's
        // existing, bounded cross-tenant actor) is additionally granted
        // Dashboard access only, not the other report endpoints.
        Gate::define('view-dashboard', fn (User $user): bool => $user->hasRole('admin')
            || ($user->tenant_id === null && $user->hasRole('deendoon_platform_administrator')));

        // Subscription Approval + Storage Add-on Approval (Product
        // Owner-approved decision record): the approve/reject/
        // approval-center endpoints are exclusively the Deendoon Platform
        // Administrator's — the mirror of 'admin-only' rather than an
        // extension of it, matching User::isPlatformAdmin()'s own
        // definition.
        Gate::define('platform-admin-only', fn (User $user): bool => $user->isPlatformAdmin());

        Gate::policy(Customer::class, CustomerPolicy::class);
        Gate::policy(Debt::class, DebtPolicy::class);
        Gate::policy(CollectionCase::class, CollectionCasePolicy::class);
        Gate::policy(ProfessionalCollectionRequest::class, ProfessionalCollectionRequestPolicy::class);
        Gate::policy(Receipt::class, ReceiptPolicy::class);
        Gate::policy(DemandLetter::class, DemandLetterPolicy::class);
        Gate::policy(Statement::class, StatementPolicy::class);
        Gate::policy(Notification::class, NotificationPolicy::class);
        Gate::policy(User::class, UserPolicy::class);
        Gate::policy(Reminder::class, ReminderPolicy::class);
        Gate::policy(Invoice::class, InvoicePolicy::class);
        Gate::policy(Tenant::class, TenantPolicy::class);
        Gate::policy(SupportTicket::class, SupportTicketPolicy::class);
        Gate::policy(CustomerAttachment::class, CustomerAttachmentPolicy::class);
        Gate::policy(DebtAttachment::class, DebtAttachmentPolicy::class);
        Gate::policy(CollectionCaseAttachment::class, CollectionCaseAttachmentPolicy::class);
        Gate::policy(SupportTicketAttachment::class, SupportTicketAttachmentPolicy::class);

        RateLimiter::for('login', function (Request $request) {
            $key = Str::lower(trim((string) $request->input('email'))).'|'.$request->ip();

            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('register', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        // Mobile Fix #22 — Google Login. Keyed by IP only, matching
        // 'register' — there's no email field to key by until after the
        // token is verified, and the id_token itself changes every
        // attempt so it isn't a useful key either.
        RateLimiter::for('google-login', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        // Sprint 1.1 — Password Recovery. 08_Security_and_RBAC.md §8:
        // rate limiting "applied at minimum to... POST /auth/forgot-password
        // (reset-token exhaustion)". Same shape as 'login' (keyed by
        // email+IP, so one abusive requester can't lock out a shared IP's
        // other legitimate users' attempts against the same email).
        RateLimiter::for('forgot-password', function (Request $request) {
            $key = Str::lower(trim((string) $request->input('email'))).'|'.$request->ip();

            return Limit::perMinute(5)->by($key);
        });

        // Defense-in-depth against token-guessing, not a load-bearing
        // control — the token itself is a 64-character CSPRNG string, so
        // brute force is computationally infeasible regardless.
        RateLimiter::for('reset-password', function (Request $request) {
            $key = Str::lower(trim((string) $request->input('email'))).'|'.$request->ip();

            return Limit::perMinute(5)->by($key);
        });

        // Phase 14 — Production Readiness. Every RegisterRequest/CreateUserRequest/
        // UpdateUserRequest already validates against Password::defaults();
        // without this, that resolves to Laravel's stock min:8, not 08's
        // approved policy (§10: "minimum 12 characters, no mandatory
        // composition rules... current OWASP/NIST guidance favors length
        // over arbitrary complexity"). No new validation rule is added to
        // any Request — this only corrects what the existing rule resolves to.
        Password::defaults(fn () => Password::min(12));

        // Phase 14 — Production Readiness. `bootstrap/app.php`'s empty
        // withMiddleware() callback left the `api` middleware group with no
        // rate limiter at all (Laravel only applies one if throttleApi() is
        // explicitly called) — every endpoint except login/register had zero
        // abuse protection. 08 §8 recommends a general rate-limiting
        // mechanism without fixing a threshold ("exact thresholds remain
        // undefined... that is 09's concern"); the limit is env-configurable
        // rather than hardcoded, consistent with 08 Principle 6 and 09 §7's
        // "environment-based configuration, never hardcoded."
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute((int) env('API_RATE_LIMIT_PER_MINUTE', 60))
                ->by($request->user()?->id ?? $request->ip());
        });
    }
}
