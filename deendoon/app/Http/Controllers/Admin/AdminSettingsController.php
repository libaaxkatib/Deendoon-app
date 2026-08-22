<?php

namespace App\Http\Controllers\Admin;

use App\Enums\AuditAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSubscriptionPlanRequest;
use App\Http\Requests\UpdatePlatformPaymentDestinationRequest;
use App\Http\Requests\UpdateSubscriptionPlanRequest;
use App\Models\SubscriptionPlan;
use App\Services\AuditLogService;
use App\Services\PlatformPaymentSettingsService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * Admin Panel — Settings (Module 11): Platform-Administrator-only, gated
 * by the same `can:platform-admin-only` Gate as every other Admin
 * controller. V1 scope was originally exactly Subscription Plan
 * management (Product Owner Decision 1); the Manual Mobile-Money
 * Subscription Payment Flow (Product Owner decision) added the platform's
 * destination mobile-money number as a second, equally platform-level
 * setting on this same page rather than a new admin section, since both
 * are "one Platform-Administrator-editable value with no per-resource
 * concept." `SubscriptionPlan` is a global, non-tenant-scoped catalog
 * table (see its own docblock) that already had every field this needs in
 * its Fillable list but no admin write path — until now, changing a plan
 * required editing SubscriptionPlanSeeder directly.
 *
 * No Policy: nothing here is per-resource (same reasoning as
 * AdminSystemController), and neither SubscriptionPlan nor
 * PlatformPaymentSetting has a tenant to scope by.
 */
class AdminSettingsController extends Controller
{
    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly PlatformPaymentSettingsService $paymentSettings,
    ) {}

    public function index(): View
    {
        return view('admin.settings.index', [
            'title' => 'Settings',
            'pageTitle' => 'Subscription Plans',
            'plans' => SubscriptionPlan::orderBy('monthly_price')->orderBy('name')->get(),
            'paymentSettings' => $this->paymentSettings->current(),
        ]);
    }

    public function updatePaymentDestination(UpdatePlatformPaymentDestinationRequest $request): RedirectResponse
    {
        $this->paymentSettings->update($request->validated('destination_mobile_money_number'), $request->user());

        return redirect()->route('admin.settings.index')->with('status', 'Destination mobile-money number updated.');
    }

    public function create(): View
    {
        return view('admin.settings.create', [
            'title' => 'Settings',
            'pageTitle' => 'New Subscription Plan',
        ]);
    }

    public function store(StoreSubscriptionPlanRequest $request): RedirectResponse
    {
        $plan = SubscriptionPlan::create($this->planData($request));

        $this->auditLog->record(AuditAction::Created, 'subscription_plan', $plan->id, $request->user());

        return redirect()->route('admin.settings.index')->with('status', "Subscription plan \"{$plan->name}\" created.");
    }

    public function edit(SubscriptionPlan $subscriptionPlan): View
    {
        return view('admin.settings.edit', [
            'title' => 'Settings',
            'pageTitle' => 'Edit Subscription Plan',
            'plan' => $subscriptionPlan,
        ]);
    }

    public function update(UpdateSubscriptionPlanRequest $request, SubscriptionPlan $subscriptionPlan): RedirectResponse
    {
        $subscriptionPlan->update($this->planData($request));

        $this->auditLog->record(AuditAction::Edited, 'subscription_plan', $subscriptionPlan->id, $request->user());

        return redirect()->route('admin.settings.index')->with('status', "Subscription plan \"{$subscriptionPlan->name}\" updated.");
    }

    public function activate(Request $request, SubscriptionPlan $subscriptionPlan): RedirectResponse
    {
        $subscriptionPlan->update(['active' => true]);

        $this->auditLog->record(AuditAction::StatusChanged, 'subscription_plan', $subscriptionPlan->id, $request->user());

        return redirect()->route('admin.settings.index')->with('status', "\"{$subscriptionPlan->name}\" activated.");
    }

    public function deactivate(Request $request, SubscriptionPlan $subscriptionPlan): RedirectResponse
    {
        $subscriptionPlan->update(['active' => false]);

        $this->auditLog->record(AuditAction::StatusChanged, 'subscription_plan', $subscriptionPlan->id, $request->user());

        return redirect()->route('admin.settings.index')->with('status', "\"{$subscriptionPlan->name}\" deactivated.");
    }

    /**
     * @return array<string, mixed>
     */
    private function planData(StoreSubscriptionPlanRequest|UpdateSubscriptionPlanRequest $request): array
    {
        return [
            'name' => $request->validated('name'),
            'monthly_price' => $request->validated('monthly_price'),
            'customer_limit' => $request->filled('customer_limit') ? (int) $request->validated('customer_limit') : null,
            'storage_limit' => $request->validated('storage_limit'),
            'analytics_enabled' => $request->boolean('analytics_enabled'),
        ];
    }
}
