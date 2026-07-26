<?php

namespace App\Http\Middleware;

use App\Services\SecurityEventLogger;
use Closure;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Symfony\Component\HttpFoundation\Response;

/**
 * Product Owner Decision (Phase 14): Sanctum idle timeout, 60 minutes,
 * sliding — 08_Security_and_RBAC.md §3/§9's "expires after the configured
 * idle window" requirement, previously unimplemented (`config('sanctum.
 * expiration')` is a fixed TTL from token creation, not an idle/sliding
 * window, and was left `null` regardless).
 *
 * Must run before ANYTHING that can resolve `$request->user()` — not just
 * `auth:sanctum` itself. Sanctum's guard overwrites `last_used_at` to
 * `now()` as a side effect of resolving a token into a user, and that
 * resolution can be triggered by other middleware too: the general `api`
 * rate limiter (AppServiceProvider) calls `$request->user()?->id` inside
 * the `api` group's `throttle:api`, which runs before any route-specific
 * middleware group. Registering this only within the authenticated route
 * group (after `throttle:api`) let that limiter's `$request->user()` call
 * silently refresh `last_used_at` first, making every token look freshly
 * used regardless of its actual age — caught by
 * `test_a_token_idle_for_over_sixty_minutes_is_rejected_and_deleted`.
 * Prepended to the global middleware stack (`bootstrap/app.php`) instead,
 * so it always runs first. Reading `last_used_at` before anything can
 * touch it is what makes this "sliding": every authenticated request that
 * passes extends the window by letting Sanctum's own existing, unmodified
 * update happen afterward — this middleware tracks no expiry timestamp of
 * its own.
 *
 * No authentication redesign: Sanctum's bearer-token mechanism, guard, and
 * `PersonalAccessToken` model are unchanged — this only adds a rejection
 * check ahead of Sanctum's normal resolution, using its own public
 * `findToken()` API.
 */
class EnsureTokenIsNotIdle
{
    public function __construct(private readonly SecurityEventLogger $securityLog) {}

    public function handle(Request $request, Closure $next): Response
    {
        $bearerToken = $request->bearerToken();

        if ($bearerToken) {
            $accessToken = PersonalAccessToken::findToken($bearerToken);

            if ($accessToken && $accessToken->last_used_at) {
                $idleMinutes = (int) env('SANCTUM_IDLE_TIMEOUT', 60);

                if ($accessToken->last_used_at->lt(now()->subMinutes($idleMinutes))) {
                    $this->securityLog->tokenRevokedForIdle((string) $accessToken->id, $accessToken->tokenable_id);

                    $accessToken->delete();

                    return response()->json([
                        'success' => false,
                        'message' => 'Unauthenticated.',
                        'data' => null,
                        'errors' => null,
                    ], 401);
                }
            }
        }

        return $next($request);
    }
}
