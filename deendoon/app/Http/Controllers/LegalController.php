<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

/**
 * Module — Mobile Play Store Readiness (Fix #3, Parts A & C). Public,
 * unauthenticated HTML pages for Google Play Console's required Privacy
 * Policy URL, a matching Terms & Conditions page, and an Account Deletion
 * page describing the in-app "Close Account" flow (Fix #3, Part B) — plain
 * content pages, no session/auth middleware, no tenant scoping. Privacy
 * Policy and Terms & Conditions content mirrors the mobile app's existing
 * in-app copy (`mobile/lib/features/account/domain/legal_content.dart`)
 * exactly — this is the same V1 draft, not independently authored, and
 * carries the same "not yet reviewed by legal counsel" status as that file.
 */
class LegalController extends Controller
{
    public function privacyPolicy(): View
    {
        return view('legal.privacy-policy', ['title' => 'Privacy Policy']);
    }

    public function termsConditions(): View
    {
        return view('legal.terms-conditions', ['title' => 'Terms & Conditions']);
    }

    public function accountDeletion(): View
    {
        return view('legal.account-deletion', ['title' => 'Account Deletion']);
    }
}
