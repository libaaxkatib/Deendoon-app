<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The company logo on generated PDFs. `tenants.logo_path` is a key on the
 * tenant-files disk (local or private R2), not a URL, so the letterhead
 * must be built from the bytes read through that disk. Run against both
 * disks with fakes; nothing public is involved.
 */
class DocumentLogoBrandingTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, array{0: string}>
     */
    public static function disks(): array
    {
        return ['local disk' => ['local'], 'r2 disk' => ['r2']];
    }

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
        Storage::fake('r2');
    }

    private function png(int $width, int $height): string
    {
        $image = imagecreatetruecolor($width, $height);
        // Noisy on purpose: a flat image compresses to almost nothing and
        // would not show whether the logo was scaled down.
        for ($i = 0; $i < 4000; $i++) {
            imagesetpixel($image, random_int(0, $width - 1), random_int(0, $height - 1), random_int(0, 0xFFFFFF));
        }
        ob_start();
        imagepng($image);

        return (string) ob_get_clean();
    }

    /**
     * Generates a demand letter for a tenant whose logo_path is $logoPath
     * and returns the stored PDF bytes.
     */
    private function generatePdf(string $disk, ?string $logoPath): string
    {
        config(['filesystems.app_files_disk' => $disk]);
        $tenant = Tenant::create(['business_name' => 'Acme Co', 'logo_path' => $logoPath]);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();

        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');
        Sanctum::actingAs($user, ['*']);

        $id = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(201)
            ->json('data.id');

        return Storage::disk($disk)->get(DemandLetter::findOrFail($id)->file_path);
    }

    #[DataProvider('disks')]
    public function test_the_logo_read_from_the_selected_disk_appears_in_the_pdf(string $disk): void
    {
        Storage::disk($disk)->put('branding/t1/logo.png', $this->png(300, 100));

        $pdf = $this->generatePdf($disk, 'branding/t1/logo.png');

        $this->assertStringContainsString('/Subtype /Image', $pdf);
    }

    #[DataProvider('disks')]
    public function test_a_tenant_without_a_logo_gets_no_image(string $disk): void
    {
        $pdf = $this->generatePdf($disk, null);

        $this->assertStringNotContainsString('/Subtype /Image', $pdf);
    }

    public function test_the_logo_is_not_taken_from_the_other_disk(): void
    {
        // Only the local disk holds it, but the files disk is r2.
        Storage::disk('local')->put('branding/t1/logo.png', $this->png(300, 100));
        Log::spy();

        $pdf = $this->generatePdf('r2', 'branding/t1/logo.png');

        $this->assertStringNotContainsString('/Subtype /Image', $pdf);
        Log::shouldHaveReceived('warning')->withArgs(fn ($message) => str_contains($message, 'logo'))->once();
    }

    #[DataProvider('disks')]
    public function test_a_missing_or_unusable_logo_does_not_break_document_generation(string $disk): void
    {
        Storage::disk($disk)->put('branding/t1/notes.png', 'this is not an image');

        $missing = $this->generatePdf($disk, 'branding/t1/gone.png');
        $this->assertStringStartsWith('%PDF', $missing);
        $this->assertStringNotContainsString('/Subtype /Image', $missing);

        $broken = $this->generatePdf($disk, 'branding/t1/notes.png');
        $this->assertStringStartsWith('%PDF', $broken);
        $this->assertStringNotContainsString('/Subtype /Image', $broken);
    }

    #[DataProvider('disks')]
    public function test_a_large_logo_is_scaled_down_so_the_pdf_stays_small(string $disk): void
    {
        $original = $this->png(2400, 1600);
        Storage::disk($disk)->put('branding/t1/logo.png', $original);

        $pdf = $this->generatePdf($disk, 'branding/t1/logo.png');

        $this->assertStringContainsString('/Subtype /Image', $pdf);
        $this->assertLessThan(strlen($original) / 4, strlen($pdf));
    }
}
