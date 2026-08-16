<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SecurityEvent;
use App\Models\User;
use App\Services\Admin\AdminDashboardService;
use App\Services\Admin\DatabaseBackupService;
use App\Services\SecurityEventLogger;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\View\View;
use RuntimeException;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * Admin Panel — System Management (Module 8): System Health, Security
 * Events, Database Backup, Scheduler/Automated Jobs. All 4 sub-pages sit
 * under one Platform-Administrator-only route group
 * (`can:platform-admin-only`, matching every other Admin controller) —
 * no per-action authorization beyond that is needed since nothing here is
 * per-resource (unlike e.g. SupportTicket's bimodal visibility).
 *
 * Deliberately does NOT become a general Settings page (explicit scope
 * lock) and does NOT duplicate the separate, still-placeholder Audit Logs
 * module — Security Events is a distinct, smaller event set (4 types,
 * security-relevant only) persisted by {@see SecurityEventLogger},
 * not the general-purpose `audit_log` table AuditLogService already
 * writes for business events.
 */
class AdminSystemController extends Controller
{
    public const EVENT_TYPE_LABELS = [
        'login_failed' => 'Login Failed',
        'password_reset_requested' => 'Password Reset Requested',
        'token_revoked_idle' => 'Token Revoked (Idle)',
        'permission_denied' => 'Permission Denied',
    ];

    public function __construct(
        private readonly AdminDashboardService $dashboard,
        private readonly DatabaseBackupService $backups,
    ) {}

    public function health(): View
    {
        return view('admin.system.health', [
            'title' => 'System Management',
            'pageTitle' => 'System Health',
            'checks' => $this->dashboard->systemHealth(),
            'realChecks' => ['Database', 'File Storage'],
            'info' => $this->environmentInfo(),
        ]);
    }

    /**
     * @return array<string, string>
     */
    private function environmentInfo(): array
    {
        return [
            'Laravel Version' => app()->version(),
            'PHP Version' => PHP_VERSION,
            'Database Driver' => (string) config('database.default'),
            'Cache Driver' => (string) config('cache.default'),
            'Queue Connection' => (string) config('queue.default'),
            'Storage Disk' => (string) config('filesystems.default'),
            'Environment' => (string) config('app.env'),
        ];
    }

    public function platformAdministrators(): View
    {
        $administrators = User::role('deendoon_platform_administrator')
            ->orderBy('created_at')
            ->get(['id', 'name', 'email', 'created_at']);

        return view('admin.system.platform-administrators', [
            'title' => 'System Management',
            'pageTitle' => 'Platform Administrator',
            'administrators' => $administrators,
        ]);
    }

    public function securityEvents(Request $request): View
    {
        $events = SecurityEvent::query()
            ->when($request->filled('event_type'), fn ($q) => $q->where('event_type', $request->string('event_type')))
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%'.mb_strtolower((string) $request->string('search')).'%';
                $q->where(function ($q2) use ($term) {
                    $q2->whereRaw('LOWER(email) LIKE ?', [$term])
                        ->orWhereRaw('LOWER(ip_address) LIKE ?', [$term])
                        ->orWhereRaw('LOWER(path) LIKE ?', [$term]);
                });
            })
            ->when($request->filled('date_from'), fn ($q) => $q->whereDate('occurred_at', '>=', $request->string('date_from')))
            ->when($request->filled('date_to'), fn ($q) => $q->whereDate('occurred_at', '<=', $request->string('date_to')))
            ->orderByDesc('occurred_at')
            ->paginate(25)
            ->withQueryString();

        return view('admin.system.security-events', [
            'title' => 'System Management',
            'pageTitle' => 'Security Events',
            'events' => $events,
            'eventTypes' => self::EVENT_TYPE_LABELS,
        ]);
    }

    public function backup(): View
    {
        return view('admin.system.backup', [
            'title' => 'System Management',
            'pageTitle' => 'Database Backup',
        ]);
    }

    public function createBackup(): BinaryFileResponse|RedirectResponse
    {
        try {
            $dump = $this->backups->createDump();
        } catch (RuntimeException $e) {
            return back()->withErrors(['backup' => $e->getMessage()]);
        }

        return response()->download($dump['path'], $dump['filename'], [
            'Content-Type' => 'application/sql',
        ])->deleteFileAfterSend(true);
    }

    /**
     * `Schedule` is deliberately NOT type-hinted as a route-injected
     * parameter here — resolving it that way happens before this method's
     * body runs, which would be too early: `ApplicationBuilder::withSchedule()`
     * only wires bootstrap/app.php's closure via `Artisan::starting(...)`,
     * which fires when the console Artisan application actually boots —
     * never during a normal HTTP request. `Artisan::call()` forces that
     * boot as a side effect; only then does resolving `Schedule::class`
     * (the same bound singleton `Artisan::call()` itself just populated)
     * return every registered event instead of an empty schedule.
     */
    public function scheduler(): View
    {
        Artisan::call('schedule:list');
        $schedule = app(Schedule::class);

        $events = collect($schedule->events())
            ->map(fn ($event) => [
                'command' => $this->commandName($event->command),
                'expression' => $event->expression,
                'description' => $event->description,
            ])
            ->values()
            ->all();

        return view('admin.system.scheduler', [
            'title' => 'System Management',
            'pageTitle' => 'Scheduler / Automated Jobs',
            'events' => $events,
        ]);
    }

    /**
     * Schedule\Event::$command is the full shell command (PHP binary path
     * + artisan + signature) — trims it down to just the artisan
     * signature for display, which is all an operator needs to see.
     */
    private function commandName(?string $command): string
    {
        if ($command === null) {
            return '—';
        }

        if (preg_match("/artisan['\"]?\\s+([^'\"]+)/", $command, $matches) === 1) {
            return trim($matches[1]);
        }

        return $command;
    }
}
