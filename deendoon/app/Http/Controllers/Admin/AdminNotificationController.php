<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\SendAnnouncementRequest;
use App\Models\Announcement;
use App\Models\Tenant;
use App\Models\User;
use App\Services\Admin\AnnouncementService;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

/**
 * Admin Panel — Notifications (Module 9): Platform-Administrator-only,
 * gated by the same `can:platform-admin-only` Gate as every other Admin
 * controller. Composing/sending an Announcement is delegated entirely to
 * AnnouncementService, which reuses the existing NotificationService
 * write path. Announcement History (follow-up) reads from the separate
 * Announcement table — see that model's docblock for why.
 */
class AdminNotificationController extends Controller
{
    public function __construct(private readonly AnnouncementService $announcements) {}

    public function index(): View
    {
        return view('admin.notifications.index', [
            'title' => 'Notifications',
            'pageTitle' => 'Send System Notice',
            'tenants' => Tenant::orderBy('business_name')->get(['id', 'business_name', 'status']),
        ]);
    }

    public function history(): View
    {
        $announcements = Announcement::orderBy('sent_at', 'desc')->paginate(20);

        $senderIds = $announcements->getCollection()->pluck('sent_by_user_id')->filter()->unique();
        $senderNames = User::whereIn('id', $senderIds)->get()->keyBy(fn (User $user) => (string) $user->id)->map->name;

        return view('admin.notifications.history', [
            'title' => 'Notifications',
            'pageTitle' => 'System Notice History',
            'announcements' => $announcements,
            'senderNames' => $senderNames,
        ]);
    }

    public function store(SendAnnouncementRequest $request): RedirectResponse
    {
        $count = $this->announcements->send(
            $request->validated('scope'),
            $request->validated('tenant_ids') ?? [],
            $request->validated('title'),
            $request->validated('message'),
            $request->user(),
        );

        return redirect()->route('admin.notifications.index')
            ->with('status', "System Notice sent to {$count} business owner(s).");
    }
}
