<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Size limits on the Customer/Debt/CollectionCase attachment uploads.
 *
 * Two different layers reject an oversized file and both must answer with
 * the API's JSON envelope: the 10MB Form Request rule (422), and PHP's
 * post_max_size, which the Dockerfile sets just above it and which Laravel
 * reports as 413 before any controller runs. A production QA run found the
 * second case answered `200 text/html` (PHP's own warning, printed because
 * display_errors was on), so the mobile app took it for a success.
 */
class AttachmentUploadSizeLimitTest extends TestCase
{
    use RefreshDatabase;

    private const MAX_KILOBYTES = 10240;

    /**
     * @return array<string, array{0: string}>
     */
    public static function entities(): array
    {
        return ['customer' => ['customer'], 'debt' => ['debt'], 'collection case' => ['case']];
    }

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
    }

    private function urlFor(string $entity): string
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();

        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');
        Sanctum::actingAs($user, ['*']);

        return match ($entity) {
            'customer' => "/api/v1/customers/{$customer->id}/attachments",
            'debt' => "/api/v1/debts/{$debt->id}/attachments",
            'case' => '/api/v1/collection-cases/'.CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create()->id.'/attachments',
        };
    }

    #[DataProvider('entities')]
    public function test_a_file_at_the_limit_is_accepted(string $entity): void
    {
        $url = $this->urlFor($entity);

        $this->post($url, [
            'file' => UploadedFile::fake()->create('scan.pdf', self::MAX_KILOBYTES, 'application/pdf'),
        ], ['Accept' => 'application/json'])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.file_size', self::MAX_KILOBYTES * 1024);
    }

    #[DataProvider('entities')]
    public function test_a_file_over_the_limit_is_rejected_with_a_field_error_and_nothing_is_stored(string $entity): void
    {
        $url = $this->urlFor($entity);

        $this->post($url, [
            'file' => UploadedFile::fake()->create('scan.pdf', self::MAX_KILOBYTES + 1, 'application/pdf'),
        ], ['Accept' => 'application/json'])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonValidationErrors('file');

        $this->assertSame([], Storage::disk('local')->allFiles());
        $this->assertDatabaseCount('customer_attachments', 0);
        $this->assertDatabaseCount('debt_attachments', 0);
        $this->assertDatabaseCount('collection_case_attachments', 0);
    }

    #[DataProvider('entities')]
    public function test_a_body_over_post_max_size_gets_the_json_envelope_not_a_bare_response(string $entity): void
    {
        $url = $this->urlFor($entity);

        // What PHP leaves behind for an oversized body: the declared
        // Content-Length is over post_max_size and the parsed body is empty.
        $response = $this->call('POST', $url, [], [], [], [
            'CONTENT_LENGTH' => 100 * 1024 * 1024 * 1024,
            'HTTP_ACCEPT' => 'application/json',
        ]);

        $response->assertStatus(413)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'The file is too large. Uploads must be 10 MB or smaller.')
            ->assertJsonPath('data', null)
            ->assertJsonPath('errors', null);
        $this->assertStringContainsString('application/json', (string) $response->headers->get('Content-Type'));
        $this->assertSame([], Storage::disk('local')->allFiles());
    }

    public function test_an_oversized_body_is_refused_even_without_authentication(): void
    {
        $this->call('POST', '/api/v1/debts/01ABC/attachments', [], [], [], [
            'CONTENT_LENGTH' => 100 * 1024 * 1024 * 1024,
            'HTTP_ACCEPT' => 'application/json',
        ])->assertStatus(413)->assertJsonPath('success', false);
    }

    public function test_the_php_ini_shipped_with_the_image_never_displays_errors(): void
    {
        $dockerfile = (string) file_get_contents(base_path('Dockerfile'));

        // Guards the root cause of the production 200: without these, PHP's
        // startup warning for an oversized body is printed into the response.
        $this->assertStringContainsString("echo 'display_errors=Off'", $dockerfile);
        $this->assertStringContainsString("echo 'html_errors=Off'", $dockerfile);
        $this->assertStringContainsString("echo 'log_errors=On'", $dockerfile);
        $this->assertStringContainsString("echo 'post_max_size=13M'", $dockerfile);
    }
}
