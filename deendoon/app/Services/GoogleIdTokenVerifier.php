<?php

namespace App\Services;

use App\Exceptions\InvalidGoogleTokenException;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Firebase\JWT\SignatureInvalidException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use UnexpectedValueException;

/**
 * Mobile Fix #22 — Google Login. Verifies a Google-issued ID token
 * entirely server-side, against Google's own published signing keys —
 * never trusts a client-supplied email/name as identity (08_Security_and_
 * RBAC.md's "never trust client input" principle applied to this new
 * credential type). Checks, in order: JWT signature (via Google's current
 * JWKS), expiry/not-before (both enforced by firebase/php-jwt itself),
 * issuer, and audience (this app's own OAuth Client ID, `services.google.
 * client_id` — never the client *secret*, since there is no
 * authorization-code exchange in this native on-device flow).
 *
 * Every failure mode collapses to the same {@see InvalidGoogleTokenException}
 * — the caller (AuthController::googleLogin()) turns that into a generic
 * 401, the same enumeration-safe posture as every other auth failure in
 * this codebase. Never logs the raw token itself (SecurityEventLogger's
 * own documented "never logs... credential value" convention extended
 * here).
 */
class GoogleIdTokenVerifier
{
    private const CERTS_URL = 'https://www.googleapis.com/oauth2/v3/certs';

    private const CERTS_CACHE_KEY = 'google_id_token_certs';

    /** Google rotates signing keys infrequently; a short TTL keeps this
     *  responsive to rotation without hitting Google on every login. */
    private const CERTS_CACHE_MINUTES = 60;

    private const ALLOWED_ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

    /**
     * @return array{sub: string, email: string, email_verified: bool, name: ?string}
     *
     * @throws InvalidGoogleTokenException
     */
    public function verify(string $idToken): array
    {
        $clientId = config('services.google.client_id');

        if (! $clientId) {
            // Configuration gap, not a token problem — surfaced distinctly
            // so it isn't confused with a user-facing "invalid token" in
            // logs, but still a generic 401 to the caller either way.
            throw new InvalidGoogleTokenException('GOOGLE_CLIENT_ID is not configured.');
        }

        try {
            $keys = JWK::parseKeySet($this->fetchGoogleCerts());
            $claims = JWT::decode($idToken, $keys);
        } catch (SignatureInvalidException|ExpiredException|UnexpectedValueException $e) {
            throw new InvalidGoogleTokenException('Signature/expiry check failed: '.$e->getMessage());
        }

        if (! in_array($claims->iss ?? null, self::ALLOWED_ISSUERS, true)) {
            throw new InvalidGoogleTokenException('Unexpected issuer.');
        }

        if (($claims->aud ?? null) !== $clientId) {
            throw new InvalidGoogleTokenException('Unexpected audience.');
        }

        if (empty($claims->sub) || empty($claims->email)) {
            throw new InvalidGoogleTokenException('Missing required claims.');
        }

        return [
            'sub' => $claims->sub,
            'email' => strtolower($claims->email),
            'email_verified' => (bool) ($claims->email_verified ?? false),
            'name' => $claims->name ?? null,
        ];
    }

    /** @return array<string, mixed> */
    private function fetchGoogleCerts(): array
    {
        return Cache::remember(self::CERTS_CACHE_KEY, now()->addMinutes(self::CERTS_CACHE_MINUTES), function () {
            $response = Http::timeout(10)->get(self::CERTS_URL);

            if (! $response->successful()) {
                throw new InvalidGoogleTokenException('Could not fetch Google signing keys.');
            }

            return $response->json();
        });
    }
}
