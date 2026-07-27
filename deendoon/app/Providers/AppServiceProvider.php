<?php

namespace App\Providers;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Notification;
use App\Models\ProfessionalCollectionRequest;
use App\Models\Receipt;
use App\Models\Reminder;
use App\Models\Statement;
use App\Models\User;
use App\Policies\CollectionCasePolicy;
use App\Policies\CustomerPolicy;
use App\Policies\DebtPolicy;
use App\Policies\DemandLetterPolicy;
use App\Policies\NotificationPolicy;
use App\Policies\ProfessionalCollectionRequestPolicy;
use App\Policies\ReceiptPolicy;
use App\Policies\ReminderPolicy;
use App\Policies\StatementPolicy;
use App\Policies\UserPolicy;
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
        Gate::define('admin-only', fn (User $user): bool => $user->hasRole('admin'));
        Gate::define('sales-finance-only', fn (User $user): bool => $user->hasRole('sales_finance'));
        Gate::define('customer-only', fn (User $user): bool => $user->hasRole('customer'));

        // Module 9 — Reporting. No FR names a specific role for report
        // access (unlike FR-041's Collection Officer), so this follows the
        // same interim admin/sales_finance mapping used for every other
        // generic "authorized user" requirement in this project.
        Gate::define('view-reports', fn (User $user): bool => $user->hasAnyRole(['admin', 'sales_finance']));

        // FR-053 explicitly names "system-wide" as a role-dependent
        // Dashboard variant — the only report in this module with that
        // property — so the Deendoon Platform Administrator (Module 7's
        // existing, bounded cross-tenant actor) is additionally granted
        // Dashboard access only, not the other report endpoints.
        Gate::define('view-dashboard', fn (User $user): bool => $user->hasAnyRole(['admin', 'sales_finance'])
            || ($user->tenant_id === null && $user->hasRole('deendoon_platform_administrator')));

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

        RateLimiter::for('login', function (Request $request) {
            $key = Str::lower(trim((string) $request->input('email'))).'|'.$request->ip();

            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('register', function (Request $request) {
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
