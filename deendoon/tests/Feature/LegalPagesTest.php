<?php

namespace Tests\Feature;

use Tests\TestCase;

/**
 * Mobile Play Store Readiness (Fix #3, Part A) — public, unauthenticated
 * Privacy Policy / Terms & Conditions pages required for Google Play
 * Console's store listing.
 */
class LegalPagesTest extends TestCase
{
    public function test_privacy_policy_is_publicly_accessible_without_authentication(): void
    {
        $response = $this->get('/privacy-policy');

        $response->assertOk();
        $response->assertSee('Privacy Policy');
        $response->assertSee('Deendoon');
    }

    public function test_terms_and_conditions_is_publicly_accessible_without_authentication(): void
    {
        $response = $this->get('/terms-conditions');

        $response->assertOk();
        $response->assertSee('Terms & Conditions', false);
    }

    public function test_privacy_policy_contains_real_content_not_placeholder_text(): void
    {
        $response = $this->get('/privacy-policy');

        $response->assertSee('Deendoon');
        $response->assertSee('Professional Collection');
        $response->assertDontSee('Lorem ipsum');
        $response->assertDontSee('placeholder', false);
    }

    public function test_terms_and_conditions_contains_real_content_not_placeholder_text(): void
    {
        $response = $this->get('/terms-conditions');

        $response->assertSee('Subscription and Storage');
        $response->assertSee('Professional Collection');
        $response->assertDontSee('Lorem ipsum');
    }

    /**
     * The mobile app's in-app copy previously said "...once that channel
     * is available" — stale now that Contact Support (Support Tickets)
     * is a real, shipped feature. The public pages must not carry that
     * stale wording forward.
     */
    public function test_the_public_pages_do_not_contain_the_stale_contact_support_wording(): void
    {
        $this->get('/privacy-policy')->assertDontSee('once that channel is available');
        $this->get('/terms-conditions')->assertDontSee('once that channel is available');
    }
}
