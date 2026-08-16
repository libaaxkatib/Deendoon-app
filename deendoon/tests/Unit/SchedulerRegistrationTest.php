<?php

namespace Tests\Unit;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

/**
 * Module 8 — System Management, Decision 4 (deliberate override of
 * docs/Performance_Architecture.md's standing "no scheduled task" decision,
 * for exactly these 3 commands). Confirms the registration in
 * bootstrap/app.php's withSchedule() closure actually takes effect —
 * without changing any of the 3 commands' own business logic/tests.
 *
 * ApplicationBuilder::withSchedule() only wires its closure via
 * `Artisan::starting(...)`, which fires when the console Kernel's Artisan
 * application first boots — NOT simply by resolving Schedule::class cold.
 * Running a real artisan command first (exactly what "verify scheduler
 * registration using the appropriate Laravel command" already asks for)
 * triggers that boot, so this is the one correct way to test it — resolving
 * Schedule::class without doing this first would always see zero events,
 * regardless of whether bootstrap/app.php is actually correct.
 */
class SchedulerRegistrationTest extends TestCase
{
    public function test_the_four_approved_commands_are_registered_on_the_scheduler(): void
    {
        Artisan::call('schedule:list');
        $output = Artisan::output();

        $this->assertStringContainsString('reminders:fire-due', $output);
        $this->assertStringContainsString('subscriptions:expire-trials', $output);
        $this->assertStringContainsString('subscriptions:expire', $output);
        $this->assertStringContainsString('notifications:prune-read', $output);
    }

    public function test_reminders_fire_due_runs_every_fifteen_minutes(): void
    {
        Artisan::call('schedule:list');
        $this->app->make(Schedule::class);

        $event = collect($this->app->make(Schedule::class)->events())
            ->first(fn ($e) => str_contains((string) $e->command, 'reminders:fire-due'));

        $this->assertNotNull($event);
        $this->assertSame('*/15 * * * *', $event->expression);
    }

    public function test_trial_and_subscription_expiry_run_daily_and_do_not_overlap(): void
    {
        Artisan::call('schedule:list');
        $events = collect($this->app->make(Schedule::class)->events());

        $trialEvent = $events->first(fn ($e) => str_contains((string) $e->command, 'subscriptions:expire-trials'));
        $subscriptionEvent = $events->first(
            fn ($e) => str_contains((string) $e->command, 'subscriptions:expire')
                && ! str_contains((string) $e->command, 'subscriptions:expire-trials')
        );

        $this->assertNotNull($trialEvent);
        $this->assertSame('0 1 * * *', $trialEvent->expression);
        $this->assertTrue($trialEvent->withoutOverlapping);

        $this->assertNotNull($subscriptionEvent);
        $this->assertSame('5 1 * * *', $subscriptionEvent->expression);
        $this->assertTrue($subscriptionEvent->withoutOverlapping);
    }

    public function test_notifications_prune_read_runs_daily_and_does_not_overlap(): void
    {
        Artisan::call('schedule:list');
        $event = collect($this->app->make(Schedule::class)->events())
            ->first(fn ($e) => str_contains((string) $e->command, 'notifications:prune-read'));

        $this->assertNotNull($event);
        $this->assertSame('0 2 * * *', $event->expression);
        $this->assertTrue($event->withoutOverlapping);
    }
}
