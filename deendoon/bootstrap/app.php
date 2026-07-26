<?php

use App\Http\Middleware\EnsureTokenIsNotIdle;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
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
    })->create();
