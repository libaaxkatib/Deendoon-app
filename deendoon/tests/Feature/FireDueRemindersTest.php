<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Notification;
use App\Models\Reminder;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * docs/Backend_v2.1_UI_Mapping.md §8 — the Reminder Scheduler. Tested as
 * a directly-invoked Artisan command (`reminders:fire-due`); not wired
 * into Illuminate\Console\Scheduling this sprint (see the command's own
 * docblock for why).
 */
class FireDueRemindersTest extends TestCase
{
    use RefreshDatabase;

    private function makeDebt(Tenant $tenant): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
    }

    private function makeUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        return $user;
    }

    public function test_it_creates_an_in_app_notification_for_a_due_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $creator = $this->makeUser($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->overdue()->create([
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'created_by_user_id' => (string) $creator->id,
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $this->artisan('reminders:fire-due')->assertExitCode(0);

        $this->assertDatabaseHas('notifications', [
            'tenant_id' => $tenant->id,
            'recipient_user_id' => (string) $creator->id,
            'type' => 'reminder_sent',
            'related_entity_type' => 'reminder',
            'related_entity_id' => $reminder->id,
        ]);
    }

    public function test_it_does_not_refire_an_already_notified_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $creator = $this->makeUser($tenant);
        Reminder::factory()->for($tenant, 'tenant')->overdue()->create([
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'created_by_user_id' => (string) $creator->id,
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $this->artisan('reminders:fire-due');
        $this->artisan('reminders:fire-due');

        $this->assertSame(1, Notification::where('type', 'reminder_sent')->count());
    }

    public function test_it_ignores_a_completed_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $creator = $this->makeUser($tenant);
        Reminder::factory()->for($tenant, 'tenant')->overdue()->completed()->create([
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'created_by_user_id' => (string) $creator->id,
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $this->artisan('reminders:fire-due');

        $this->assertSame(0, Notification::count());
    }

    public function test_it_ignores_a_reminder_not_yet_due(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $creator = $this->makeUser($tenant);
        Reminder::factory()->for($tenant, 'tenant')->create([
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'created_by_user_id' => (string) $creator->id,
            'due_date' => now()->addWeek(),
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $this->artisan('reminders:fire-due');

        $this->assertSame(0, Notification::count());
    }

    public function test_it_ignores_a_reminder_that_does_not_request_in_app_delivery(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $creator = $this->makeUser($tenant);
        Reminder::factory()->for($tenant, 'tenant')->overdue()->create([
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'created_by_user_id' => (string) $creator->id,
            'timing_rule' => 'same_day',
            'delivery_methods' => ['whatsapp'],
        ]);

        $this->artisan('reminders:fire-due');

        $this->assertSame(0, Notification::count());
    }
}
