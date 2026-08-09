<?php

use App\Http\Middleware\EnsureTokenIsNotIdle;
use App\Http\Middleware\SecurityHeaders;
use App\Services\SecurityEventLogger;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // This is an API-only backend (routes/web.php has no login page,
        // no `login` named route exists anywhere) but the framework's own
        // ApplicationBuilder::withMiddleware() unconditionally defaults
        // every guard's unauthenticated-redirect to
        // `redirectGuestsTo(fn () => route('login'))` before this closure
        // runs. Authenticate::unauthenticated() only skips calling that
        // callback when $request->expectsJson() is true, which depends on
        // the client sending an `Accept: application/json` header — not
        // guaranteed for every API consumer. When it's absent, redirectTo()
        // calls route('login'), which throws RouteNotFoundException before
        // AuthenticationException is even constructed, so it never reaches
        // the JSON-envelope render() callback registered below and
        // surfaces as an unhandled 500 instead of a clean 401. Overriding
        // it to null here means there is never a redirect target to
        // resolve, regardless of what the client sends.
        $middleware->redirectGuestsTo(fn () => null);

        // Product Owner Decision (Phase 14): Sanctum sliding idle timeout.
        // Prepended to the GLOBAL middleware stack — must run before
        // anything that can resolve $request->user() (not just
        // auth:sanctum), including the 'api' rate limiter registered just
        // below, which itself calls $request->user(). See
        // EnsureTokenIsNotIdle's docblock for why. No-ops for requests
        // without a Bearer token (register/login).
        $middleware->prepend(EnsureTokenIsNotIdle::class);

        // Phase 14 — Production Readiness. Registers the 'api' rate limiter
        // (defined in AppServiceProvider) against the `api` middleware group.
        // Previously empty, meaning no rate limit applied to any endpoint
        // except the explicit login/register throttles in routes/api.php.
        $middleware->throttleApi();

        // Sprint 1.2 — Security Hardening. Response headers only (see
        // SecurityHeaders' docblock) — no effect on status codes or bodies.
        $middleware->append(SecurityHeaders::class);

        // Sprint 1.2 — Security Hardening. TrustProxies is already part of
        // Laravel's default middleware stack but trusts no proxy unless
        // explicitly configured — meaning $request->ip() (used by every
        // IP-keyed rate limiter in this project) would return a load
        // balancer's IP for every request in a typical production
        // deployment, not the real client's, silently defeating those
        // limiters. Opt-in only: unset TRUSTED_PROXIES preserves today's
        // exact behavior (trust nothing) — the actual proxy IP/CIDR list
        // for a given deployment is an infrastructure detail this code has
        // no basis to assume, so nothing is trusted by default.
        if ($trustedProxies = env('TRUSTED_PROXIES')) {
            $middleware->trustProxies(
                at: $trustedProxies === '*' ? '*' : explode(',', $trustedProxies),
                headers: Request::HEADER_X_FORWARDED_FOR
                    | Request::HEADER_X_FORWARDED_HOST
                    | Request::HEADER_X_FORWARDED_PORT
                    | Request::HEADER_X_FORWARDED_PROTO,
            );
        }
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        // Keeps validation and authentication failures on the same
        // {success, message, data, errors, status_code} shape as every
        // other API response (App\Traits\ApiResponse), instead of
        // falling through to Laravel's default JSON error shape.
        $exceptions->render(function (ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => $e->getMessage(),
                    'data' => null,
                    'errors' => $e->errors(),
                ], 422);
            }
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated.',
                    'data' => null,
                    'errors' => null,
                ], 401);
            }
        });

        $exceptions->render(function (ThrottleRequestsException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Too many attempts. Please try again later.',
                    'data' => null,
                    'errors' => null,
                ], 429);
            }
        });

        // Sprint 1.2 — Security Hardening. Every $this->authorize()/
        // Gate::authorize() denial across every controller throws
        // Illuminate\Auth\Access\AuthorizationException, but Laravel's own
        // Handler::prepareException() converts it to this Symfony
        // exception BEFORE any render() callback runs (confirmed in
        // vendor/laravel/framework's Handler.php — prepareException() is
        // called ahead of renderViaCallbacks()) — a callback type-hinted
        // for AuthorizationException itself would never match. Previously
        // fell through to Laravel's default JSON shape (`{"message": "..."}`)
        // instead of this project's envelope — the one exception type
        // among those handled here that had been missed. Also the single
        // log point for every permission-denied response in the
        // application (08 §13's "periodic review... for anomalous
        // patterns" recommendation), rather than instrumenting every
        // individual controller action.
        $exceptions->render(function (AccessDeniedHttpException $e, Request $request) {
            if ($request->is('api/*')) {
                app(SecurityEventLogger::class)->permissionDenied($request->user(), $request->method(), $request->path());

                return response()->json([
                    'success' => false,
                    'message' => $e->getMessage() ?: 'This action is unauthorized.',
                    'data' => null,
                    'errors' => null,
                ], 403);
            }
        });
    })->create();
