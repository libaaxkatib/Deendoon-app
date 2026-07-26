<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Sprint 1.2 — Security Hardening. Standard, low-risk response headers
 * with no effect on any existing endpoint's status code, body, or JSON
 * shape — purely additive headers.
 *
 * - `X-Content-Type-Options: nosniff` — prevents a browser from
 *   MIME-sniffing a response into executing as something other than its
 *   declared Content-Type (relevant even for a JSON API, since
 *   `DocumentController::download()` streams PDFs).
 * - `X-Frame-Options: DENY` / `Referrer-Policy: no-referrer` — standard,
 *   no-downside defaults for an API with no legitimate reason to be
 *   framed or to leak its URLs via the Referer header.
 * - `Cache-Control: no-store, private` on every authenticated response —
 *   every endpoint behind `auth:sanctum` returns tenant-scoped financial/
 *   PII data (08_Security_and_RBAC.md §12) that must never be cached by
 *   a shared/intermediate proxy or left in a browser's disk cache.
 *   Unauthenticated responses (register/login/forgot-password) are left
 *   alone — nothing in this project's approved API design calls for
 *   caching them either way, so this doesn't change their behavior.
 */
class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('Referrer-Policy', 'no-referrer');

        if ($request->user()) {
            $response->headers->set('Cache-Control', 'no-store, private');
        }

        return $response;
    }
}
