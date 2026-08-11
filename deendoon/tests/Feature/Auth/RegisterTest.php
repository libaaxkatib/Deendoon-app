<?php

namespace Tests\Feature\Auth;

use App\Models\MessageTemplate;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): registration creates a new Tenant and its
 * single Business Owner account (role `admin`) together.
 */
class RegisterTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Backend Completion Roadmap (Phase 3.5): registration now
        // provisions a Trial TenantSubscription, which requires the
        // Trial SubscriptionPlan row to exist — every test in this class
        // goes through /register, so this is needed unconditionally, not
        // just for the tests that assert on it directly.
        $this->seed(SubscriptionPlanSeeder::class);
    }

    public function test_user_can_register_with_valid_data(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'phone' => '+252612345678',
            'email' => 'asad@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['user' => ['id', 'name', 'email', 'phone'], 'token'],
                'errors',
            ]);

        $this->assertDatabaseHas('users', ['email' => 'asad@example.com']);
        $this->assertDatabaseHas('tenants', ['business_name' => 'Asad Trading Co.']);

        $user = User::where('email', 'asad@example.com')->firstOrFail();
        $this->assertNotSame('Password123!', $user->password);
        $this->assertStringStartsWith('$argon2id$', $user->password);
        $this->assertTrue($user->hasRole('admin'));
        $this->assertSame(Tenant::where('business_name', 'Asad Trading Co.')->firstOrFail()->id, $user->tenant_id);
    }

    public function test_registration_provisions_a_trial_subscription(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'phone' => '+252612345678',
            'email' => 'asad@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201);

        $tenant = Tenant::where('business_name', 'Asad Trading Co.')->firstOrFail();
        $trialPlan = SubscriptionPlan::where('name', 'Trial')->firstOrFail();
        $subscription = TenantSubscription::where('tenant_id', $tenant->id)->firstOrFail();

        $this->assertSame($trialPlan->id, $subscription->plan_id);
        $this->assertSame('trialing', $subscription->status);
        $this->assertNotNull($subscription->started_at);
        $this->assertNotNull($subscription->trial_started_at);
        $this->assertNotNull($subscription->trial_ends_at);
        $this->assertNotNull($subscription->expires_at);
        $this->assertTrue($subscription->trial_ends_at->isFuture());
        $this->assertTrue($subscription->trial_ends_at->diffInDays(now()) <= 7);
    }

    public function test_registration_provisions_default_message_templates(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'phone' => '+252612345678',
            'email' => 'asad@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201);

        $tenant = Tenant::where('business_name', 'Asad Trading Co.')->firstOrFail();
        // 7 approved default templates x 2 channels (whatsapp + sms).
        $this->assertSame(14, MessageTemplate::where('tenant_id', $tenant->id)->count());
        $this->assertDatabaseHas('message_templates', [
            'tenant_id' => $tenant->id,
            'name' => 'First Reminder',
            'channel' => 'whatsapp',
        ]);
        $this->assertDatabaseHas('message_templates', [
            'tenant_id' => $tenant->id,
            'name' => 'Promise to Pay Confirmation',
            'channel' => 'sms',
        ]);
    }

    public function test_registration_normalizes_email_to_lowercase_and_trimmed(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'phone' => '+252612345678',
            'email' => '  Asad@Example.COM  ',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('users', ['email' => 'asad@example.com']);
        $this->assertDatabaseMissing('users', ['email' => '  Asad@Example.COM  ']);
    }

    public function test_registration_saves_and_returns_phone_number(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'phone' => '  +252612345678  ',
            'email' => 'asad@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.user.phone', '+252612345678');

        $this->assertDatabaseHas('users', [
            'email' => 'asad@example.com',
            'phone' => '+252612345678',
        ]);
    }

    public function test_registration_fails_without_phone(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Asad Trading Co.',
            'name' => 'Asad Mohamed',
            'email' => 'asad@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['phone']);
    }

    public function test_registration_is_rate_limited(): void
    {
        $payload = fn (int $i): array => [
            'business_name' => "Business {$i}",
            'name' => "User {$i}",
            'phone' => '+25261234567'.$i,
            'email' => "user{$i}@example.com",
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ];

        for ($i = 1; $i <= 5; $i++) {
            $this->postJson('/api/v1/register', $payload($i))->assertStatus(201);
        }

        $response = $this->postJson('/api/v1/register', $payload(6));

        $response->assertStatus(429)->assertJson(['success' => false]);
    }

    public function test_registration_fails_with_missing_fields(): void
    {
        $response = $this->postJson('/api/v1/register', []);

        $response->assertStatus(422)
            ->assertJson(['success' => false])
            ->assertJsonValidationErrors(['business_name', 'name', 'phone', 'email', 'password']);
    }

    public function test_registration_fails_with_duplicate_email(): void
    {
        User::factory()->create(['email' => 'duplicate@example.com']);

        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Another Business',
            'name' => 'Another User',
            'phone' => '+252612345678',
            'email' => 'duplicate@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['email']);
    }
}
