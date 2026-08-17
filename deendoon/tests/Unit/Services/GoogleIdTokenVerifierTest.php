<?php

namespace Tests\Unit\Services;

use App\Exceptions\InvalidGoogleTokenException;
use App\Services\GoogleIdTokenVerifier;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Http;
use OpenSSLAsymmetricKey;
use Tests\TestCase;

/**
 * Mobile Fix #22 — Google Login. Tests the actual verification logic
 * (signature/expiry/issuer/audience) against a fixed, checked-in RSA test
 * keypair standing in for Google's own — {@see Http::fake()} serves the
 * test JWKS instead of really calling Google, and every token here is
 * signed with this test-only private key, never a real Google credential.
 *
 * The keypair is a static fixture (not generated at test time) so this
 * test has no runtime dependency on the environment's OpenSSL
 * configuration (`openssl_pkey_new()` needs a resolvable `openssl.cnf`,
 * which isn't reliably set up on every machine/CI runner) — only
 * `openssl_pkey_get_private()`/`get_details()` are used, which parse an
 * already-generated key and don't have that requirement.
 */
class GoogleIdTokenVerifierTest extends TestCase
{
    // Test-only fixture, never used for anything but signing tokens this
    // test itself verifies — not a real credential of any kind.
    private const TEST_PRIVATE_KEY_PEM = <<<'PEM'
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCatQmwt07nITMf
    kjclw0+HMAgkA26NmoZeee2FmLeWD4vO9Kx+uak56Sa3zZmUNh07pyNG6HEzRXx9
    L0IrXhaK2o+sJdZ72vQD6edhmPYQ9CXq6NecqCvoBNqL+8kqhEP2ZPAj1LxETQTI
    VTQXOmNBEVUWqKprY5gxUoVtKXGIj+EtC2WS977gE00j30e7CDYP4cVWdIvmEH5S
    GRKBQKHj85eg6astqMGNuBSx2fq9OJnJPSZKgpIrv8C5gB00rVK3JtcCgc7XbzK3
    J3cX5be0P6527OZdEwcxIdxVdebYOs9xtdzXVPIpePMDnmx8VXOSTX5pUauGqqAt
    dRp6u8YjAgMBAAECggEADXwnRpSL16CwtJlJnkyKc5Wvt/fmnIgyGy0Uk5cOtZFQ
    Ve9E09z6D7avbckJkH4xCSCV9hnPuDDf24eRhHc0jtDjQhWgPvaEW4z5YqvzEuI9
    Jd864AhWn2hA5n/BdqfFxsXgmrbx3CA8gPvQSRAJU8QffxSfmjG5s97mC3BX2ZfS
    TI2YQh4V5tXLN0hYcT4oNnjfs06xdLH0KsaPu7Ms3UqsTd/vR/Pb6DcqgmAg204g
    o46krudsxJ/PPO5kmhogYrbeSimUAD7UyM9IAjS+wDaDfSyVNo7909581S1Xij6E
    FKMHrw/0gwYHNv4d/eGokGORwa8EUrnjfZUb8h1JDQKBgQDLfN+ks4y+2dDKxSwz
    I8XrfY4Fv7HhkW4+6HRc+iIxj4i84HiWXDTc5laborcbOJ1MhkyCZiDyLKvK/bPD
    I2obFXFIA4S0d8KGPX65znXwiAH2HDeNz/e5J+GGRzoqFmeFrO8IcpB8cxKAF3wM
    mtWx+svfZJG2y04ACSNSScWnhwKBgQDCoYs89ARaTkogFuHg6pYM+A0RqFrMDuKE
    ZL+Y24e59ezmg2TzwCA1ladOMVK5XKIdtJ7YB/V1a7+ajHgCqG6v/KAdaeBCBQX2
    3DPCtb2fM1rLna4AX5EDj78VYbEM+GgC43JoejRm4UkQChPbAeSRWPCkLuhVRdPd
    rDxhzbubhQKBgBkdo5j3lGKmDdBJP+hb/PzQ9WueOn1l7t6S4HHtabUGS1FMv3WH
    kfrF72CsV79jYH7mgKEDrANYIige4kYuo9UN83p4/LMtqPPauT6DzijPELboyq6V
    QbU3x+1D81johQSJ0MMRKOZDacAnpecEYWXjV7COADI4q7rzZcmtU1kXAoGATNZb
    0u9+/GvmBa8i85mJLYuMFUmCtwa1VJE1ttIMTlURdpuu8jAKRz1StKLyRq2UbufM
    wfq6Y+Xq2cfU5S+7qwyv5YzT9Rxok2GxqY/4UW6DzNjuRcV0yZQpWvabYER9Q46p
    ryd3opoULxnbZt3jb6JONnMyU9/iWaRSnkYLZ8UCgYEAp2pGpxMt5dQcGekewBB8
    sewTRfkB7jBe10CXfh3flVWp1FCKCtxJKN0cU74KhBm2ApwlgFm9R3CxEmNHzBN1
    UYPKdIB2F9S4I/6QQoa+So0kaEtsuWnE80GaqxkVvVAT3szLcIA37eodNB0S3I0O
    HdhpJqlUzJzlh/mAFdAJs4c=
    -----END PRIVATE KEY-----
    PEM;

    private OpenSSLAsymmetricKey $privateKey;

    private array $jwk;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.google.client_id' => 'test-client-id.apps.googleusercontent.com']);

        $this->privateKey = openssl_pkey_get_private(self::TEST_PRIVATE_KEY_PEM);
        $details = openssl_pkey_get_details($this->privateKey);

        $this->jwk = [
            'kty' => 'RSA',
            'alg' => 'RS256',
            'use' => 'sig',
            'kid' => 'test-key-1',
            'n' => rtrim(strtr(base64_encode($details['rsa']['n']), '+/', '-_'), '='),
            'e' => rtrim(strtr(base64_encode($details['rsa']['e']), '+/', '-_'), '='),
        ];

        Http::fake([
            'https://www.googleapis.com/oauth2/v3/certs' => Http::response(['keys' => [$this->jwk]]),
        ]);
    }

    private function signToken(array $claims): string
    {
        return JWT::encode($claims, $this->privateKey, 'RS256', 'test-key-1');
    }

    private function validClaims(array $overrides = []): array
    {
        return array_merge([
            'iss' => 'https://accounts.google.com',
            'aud' => 'test-client-id.apps.googleusercontent.com',
            'sub' => '1234567890',
            'email' => 'Asad@Example.com',
            'email_verified' => true,
            'name' => 'Asad Mohamed',
            'iat' => time(),
            'exp' => time() + 3600,
        ], $overrides);
    }

    public function test_accepts_a_validly_signed_token_and_returns_lowercased_email(): void
    {
        $identity = (new GoogleIdTokenVerifier)->verify($this->signToken($this->validClaims()));

        $this->assertSame('1234567890', $identity['sub']);
        $this->assertSame('asad@example.com', $identity['email']);
        $this->assertTrue($identity['email_verified']);
        $this->assertSame('Asad Mohamed', $identity['name']);
    }

    public function test_rejects_an_expired_token(): void
    {
        $this->expectException(InvalidGoogleTokenException::class);

        (new GoogleIdTokenVerifier)->verify($this->signToken($this->validClaims([
            'iat' => time() - 7200,
            'exp' => time() - 3600,
        ])));
    }

    public function test_rejects_the_wrong_issuer(): void
    {
        $this->expectException(InvalidGoogleTokenException::class);

        (new GoogleIdTokenVerifier)->verify($this->signToken($this->validClaims([
            'iss' => 'https://evil.example.com',
        ])));
    }

    public function test_rejects_the_wrong_audience(): void
    {
        $this->expectException(InvalidGoogleTokenException::class);

        (new GoogleIdTokenVerifier)->verify($this->signToken($this->validClaims([
            'aud' => 'someone-elses-client-id.apps.googleusercontent.com',
        ])));
    }

    public function test_rejects_a_malformed_token(): void
    {
        $this->expectException(InvalidGoogleTokenException::class);

        (new GoogleIdTokenVerifier)->verify('not-a-real-jwt');
    }

    public function test_rejects_when_the_client_id_is_not_configured(): void
    {
        config(['services.google.client_id' => null]);

        $this->expectException(InvalidGoogleTokenException::class);

        (new GoogleIdTokenVerifier)->verify($this->signToken($this->validClaims()));
    }
}
