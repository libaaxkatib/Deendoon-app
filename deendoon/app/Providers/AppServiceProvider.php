<?php

namespace App\Providers;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\ProfessionalCollectionRequest;
use App\Models\Receipt;
use App\Models\Statement;
use App\Models\User;
use App\Policies\CollectionCasePolicy;
use App\Policies\CustomerPolicy;
use App\Policies\DebtPolicy;
use App\Policies\DemandLetterPolicy;
use App\Policies\ProfessionalCollectionRequestPolicy;
use App\Policies\ReceiptPolicy;
use App\Policies\StatementPolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

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

        Gate::policy(Customer::class, CustomerPolicy::class);
        Gate::policy(Debt::class, DebtPolicy::class);
        Gate::policy(CollectionCase::class, CollectionCasePolicy::class);
        Gate::policy(ProfessionalCollectionRequest::class, ProfessionalCollectionRequestPolicy::class);
        Gate::policy(Receipt::class, ReceiptPolicy::class);
        Gate::policy(DemandLetter::class, DemandLetterPolicy::class);
        Gate::policy(Statement::class, StatementPolicy::class);

        RateLimiter::for('login', function (Request $request) {
            $key = Str::lower(trim((string) $request->input('email'))).'|'.$request->ip();

            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('register', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });
    }
}
