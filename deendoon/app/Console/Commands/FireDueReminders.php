<?php

namespace App\Console\Commands;

use App\Enums\NotificationType;
use App\Enums\ReminderDeliveryMethod;
use App\Models\Reminder;
use App\Services\NotificationService;
use App\Services\SmartReminderEngine;
use Illuminate\Console\Command;

/**
 * docs\Backend_v2.1_UI_Mapping.md §8 — the Reminder Scheduler, the one
 * background process this project's approved architecture requires (see
 * docs/Backend_v2.1_Database_Alignment.md §13 for why every other
 * candidate job was explicitly excluded).
 *
 * NOT registered against Illuminate\Console\Scheduling — this project has
 * an existing, explicit Product Owner decision (docs/Performance_Architecture.md:
 * "No queue, no Redis, no Horizon, no background worker, no scheduled
 * task will be introduced as a general architectural change") that this
 * sprint is not authorized to reopen. This command exists, is fully
 * functional, and is covered by tests — an operator (or a future,
 * explicitly-approved cron entry) can invoke it directly:
 * `php artisan reminders:fire-due`.
 *
 * Scope: fires the In-App Notification delivery method only. WhatsApp,
 * SMS, and Push firing on an unattended schedule would each require a
 * decision this sprint is not authorized to make on its own — WhatsApp/
 * SMS need a default template selected with no human present to use
 * WhatsApp/SMS Preview's "Use Template" picker (no such default is
 * specified anywhere in the approved documents), and Push has no
 * provider at all yet, per the External Integrations Policy. In-App has
 * neither problem: it reuses the existing, already-approved Notification
 * mechanism with no template or provider involved.
 */
class FireDueReminders extends Command
{
    protected $signature = 'reminders:fire-due';

    protected $description = 'Fire the In-App Notification delivery method for every reminder whose timing rule is due.';

    public function __construct(
        private readonly SmartReminderEngine $engine,
        private readonly NotificationService $notifications,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $pending = Reminder::query()
            ->whereNull('completed_at')
            ->doesntHave('sentMessages')
            ->get();

        $fired = 0;

        foreach ($pending as $reminder) {
            if (! $this->engine->isDueForDelivery($reminder)) {
                continue;
            }

            $deliveryMethods = $reminder->delivery_methods ?? [];

            if (! in_array(ReminderDeliveryMethod::InApp->value, $deliveryMethods, true)) {
                continue;
            }

            // notifyOnce, not notify: this command may run more than once
            // after a reminder's fire time has passed (no scheduler
            // infrastructure guarantees exactly-once invocation), and
            // firing has no SentMessage to check against for the in-app
            // method — notifyOnce's existing duplicate guard is what
            // prevents the same reminder from notifying repeatedly.
            $created = $this->notifications->notifyOnce(
                $reminder->tenant_id,
                $reminder->created_by_user_id,
                NotificationType::ReminderSent,
                'reminder',
                $reminder->id,
            );

            if ($created !== null) {
                $fired++;
            }
        }

        $this->info("Fired {$fired} due reminder(s) via In-App Notification.");

        return self::SUCCESS;
    }
}
