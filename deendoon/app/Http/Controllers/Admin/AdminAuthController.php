<?php

namespace App\Http\Controllers\Admin;

use App\Enums\AuditAction;
use App\Http\Controllers\Controller;
use App\Services\AuditLogService;
use App\Services\SecurityEventLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

/**
 * Admin Panel — Super Admin Panel session auth. Deliberately separate from
 * the API's Sanctum bearer-token login (AuthController::login) — this is a
 * session-cookie web login for the Blade panel, same `users` table and
 * `deendoon_platform_administrator` role, different transport. A
 * successful password check that resolves to a Business Owner account is
 * rejected with the exact same generic message as a wrong password, so
 * the login form never reveals whether an email belongs to a Business
 * Owner vs a non-existent account.
 */
class AdminAuthController extends Controller
{
    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly SecurityEventLogger $securityLog,
    ) {}

    public function show(): View
    {
        return view('admin.auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials, $request->boolean('remember'))) {
            $this->securityLog->loginFailed($credentials['email'], $request->ip());

            return back()->withErrors(['email' => 'These credentials do not match our records.'])->onlyInput('email');
        }

        $user = Auth::user();

        if (! $user->isPlatformAdmin()) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return back()->withErrors(['email' => 'These credentials do not match our records.'])->onlyInput('email');
        }

        $request->session()->regenerate();

        $this->auditLog->record(AuditAction::Login, 'user', (string) $user->id, $user);

        return redirect()->route('admin.dashboard');
    }

    public function logout(Request $request): RedirectResponse
    {
        $user = Auth::user();

        Auth::logout();

        if ($user) {
            $this->auditLog->record(AuditAction::Logout, 'user', (string) $user->id, $user);
        }

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }
}
