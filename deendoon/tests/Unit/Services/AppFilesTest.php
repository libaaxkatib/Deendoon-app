<?php

namespace Tests\Unit\Services;

use App\Exceptions\FileStorageException;
use App\Http\Requests\StoreProfessionalCollectionTimelineEventRequest;
use App\Http\Requests\UpdateCompanyProfileRequest;
use App\Http\Requests\UploadCollectionCaseAttachmentRequest;
use App\Http\Requests\UploadCustomerAttachmentRequest;
use App\Http\Requests\UploadDebtAttachmentRequest;
use App\Http\Requests\UploadProfessionalCollectionAttachmentRequest;
use App\Http\Requests\UploadSupportTicketAttachmentRequest;
use App\Services\AppFiles;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Exceptions;
use Illuminate\Support\Facades\Storage;
use InvalidArgumentException;
use Mockery;
use Mockery\MockInterface;
use ReflectionMethod;
use RuntimeException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Tests\TestCase;

/**
 * Direct coverage of {@see AppFiles}: the single resolver every tenant-file
 * read/write/delete/health-check goes through. Real disks are faked; the
 * "object store" health branch and the failing-write branches use a mocked
 * disk, so nothing here ever contacts Cloudflare R2.
 */
class AppFilesTest extends TestCase
{
    use RefreshDatabase;

    private function mockDisk(string $name): MockInterface
    {
        $disk = Mockery::mock(FilesystemAdapter::class);
        Storage::set($name, $disk);

        return $disk;
    }

    // --- Disk selection ---

    public function test_the_local_disk_is_used_when_nothing_is_configured(): void
    {
        config(['filesystems.app_files_disk' => null]);

        $this->assertSame('local', AppFiles::diskName());

        config(['filesystems.app_files_disk' => '']);

        $this->assertSame('local', AppFiles::diskName());
    }

    public function test_the_configured_disk_is_used(): void
    {
        config(['filesystems.app_files_disk' => 'r2']);

        $this->assertSame('r2', AppFiles::diskName());
    }

    public function test_an_undefined_disk_is_rejected_loudly(): void
    {
        config(['filesystems.app_files_disk' => 'does-not-exist']);

        $this->expectException(InvalidArgumentException::class);

        AppFiles::diskName();
    }

    public function test_the_r2_disk_is_defined_and_fails_loudly(): void
    {
        $r2 = config('filesystems.disks.r2');

        $this->assertSame('s3', $r2['driver']);
        $this->assertTrue($r2['throw']);
        $this->assertSame('private', $r2['visibility']);
        $this->assertSame('when_required', $r2['request_checksum_calculation']);
        $this->assertSame('when_required', $r2['response_checksum_validation']);
    }

    public function test_writes_go_only_to_the_selected_disk(): void
    {
        Storage::fake('local');
        Storage::fake('r2');

        config(['filesystems.app_files_disk' => 'r2']);
        AppFiles::put('documents/t1/x/a.txt', 'to r2');

        Storage::disk('r2')->assertExists('documents/t1/x/a.txt');
        Storage::disk('local')->assertMissing('documents/t1/x/a.txt');

        config(['filesystems.app_files_disk' => 'local']);
        AppFiles::put('documents/t1/x/b.txt', 'to local');

        Storage::disk('local')->assertExists('documents/t1/x/b.txt');
        Storage::disk('r2')->assertMissing('documents/t1/x/b.txt');
    }

    // --- Failed writes ---

    public function test_a_write_that_returns_false_throws_instead_of_passing_silently(): void
    {
        $disk = $this->mockDisk('local');
        $disk->shouldReceive('fileExists')->andReturn(false);
        $disk->shouldReceive('put')->once()->andReturn(false);

        $this->expectException(FileStorageException::class);

        AppFiles::put('documents/t1/x/a.txt', 'data');
    }

    public function test_a_driver_exception_is_wrapped_and_keeps_the_cause(): void
    {
        config(['filesystems.app_files_disk' => 'r2']);
        $disk = $this->mockDisk('r2');
        $disk->shouldReceive('fileExists')->andReturn(false);
        $disk->shouldReceive('put')->andThrow(new RuntimeException('bucket unreachable'));

        try {
            AppFiles::put('documents/t1/x/a.txt', 'data');
            $this->fail('Expected a FileStorageException.');
        } catch (FileStorageException $e) {
            $this->assertSame('bucket unreachable', $e->getPrevious()?->getMessage());
        }
    }

    // --- Transaction rollback cleanup ---

    public function test_a_new_object_is_removed_when_the_transaction_rolls_back(): void
    {
        Storage::fake('local');

        try {
            DB::transaction(function () {
                AppFiles::put('documents/t1/x/new.txt', 'data');
                Storage::disk('local')->assertExists('documents/t1/x/new.txt');

                throw new RuntimeException('database write failed');
            });
        } catch (RuntimeException) {
            // expected
        }

        Storage::disk('local')->assertMissing('documents/t1/x/new.txt');
    }

    public function test_a_new_object_is_removed_when_an_outer_transaction_rolls_back_after_an_inner_one_committed(): void
    {
        Storage::fake('r2');
        config(['filesystems.app_files_disk' => 'r2']);

        try {
            DB::transaction(function () {
                DB::transaction(fn () => AppFiles::put('documents/t1/x/inner.txt', 'data'));

                throw new RuntimeException('outer failure');
            });
        } catch (RuntimeException) {
            // expected
        }

        Storage::disk('r2')->assertMissing('documents/t1/x/inner.txt');
    }

    public function test_a_new_object_is_kept_when_the_transaction_commits(): void
    {
        Storage::fake('local');

        DB::transaction(fn () => AppFiles::put('documents/t1/x/kept.txt', 'data'));

        Storage::disk('local')->assertExists('documents/t1/x/kept.txt');
    }

    public function test_an_object_that_already_existed_is_not_deleted_by_a_rollback(): void
    {
        Storage::fake('local');
        Storage::disk('local')->put('branding/t1/logo.png', 'old logo');

        try {
            DB::transaction(function () {
                AppFiles::put('branding/t1/logo.png', 'new logo');

                throw new RuntimeException('database write failed');
            });
        } catch (RuntimeException) {
            // expected
        }

        $this->assertSame('new logo', Storage::disk('local')->get('branding/t1/logo.png'));
    }

    // --- Delete ---

    public function test_delete_removes_the_file_from_the_selected_disk(): void
    {
        Storage::fake('r2');
        Storage::disk('r2')->put('documents/t1/x/a.txt', 'data');
        config(['filesystems.app_files_disk' => 'r2']);

        AppFiles::delete('documents/t1/x/a.txt');

        Storage::disk('r2')->assertMissing('documents/t1/x/a.txt');
    }

    public function test_a_failing_delete_is_reported_but_does_not_raise(): void
    {
        Exceptions::fake();
        $disk = $this->mockDisk('local');
        $disk->shouldReceive('delete')->once()->andThrow(new RuntimeException('bucket unreachable'));

        AppFiles::delete('documents/t1/x/a.txt');

        Exceptions::assertReported(fn (RuntimeException $e) => $e->getMessage() === 'bucket unreachable');
    }

    // --- Missing files and downloads ---

    public function test_a_missing_file_is_a_404(): void
    {
        Storage::fake('local');

        $this->expectException(NotFoundHttpException::class);

        AppFiles::abortIfMissing('documents/t1/x/gone.pdf');
    }

    public function test_an_unreachable_disk_is_not_reported_as_a_missing_file(): void
    {
        $disk = $this->mockDisk('local');
        $disk->shouldReceive('fileExists')->andThrow(new RuntimeException('bucket unreachable'));

        $this->expectException(FileStorageException::class);

        AppFiles::abortIfMissing('documents/t1/x/a.pdf');
    }

    public function test_download_streams_an_existing_file_with_the_given_name(): void
    {
        Storage::fake('r2');
        Storage::disk('r2')->put('documents/t1/x/a.pdf', 'pdf bytes');
        config(['filesystems.app_files_disk' => 'r2']);

        $response = AppFiles::download('documents/t1/x/a.pdf', 'RCT-000001.pdf');

        $this->assertStringContainsString('RCT-000001.pdf', (string) $response->headers->get('content-disposition'));
    }

    public function test_download_of_a_missing_file_is_a_404(): void
    {
        Storage::fake('r2');
        config(['filesystems.app_files_disk' => 'r2']);

        $this->expectException(NotFoundHttpException::class);

        AppFiles::download('documents/t1/x/gone.pdf', 'gone.pdf');
    }

    // --- Health check ---

    public function test_a_local_disk_is_healthy_when_its_root_exists(): void
    {
        Storage::fake('local');

        $this->assertTrue(AppFiles::isHealthy());
    }

    public function test_a_local_disk_is_unhealthy_when_it_cannot_be_checked(): void
    {
        $disk = $this->mockDisk('local');
        $disk->shouldReceive('exists')->with('')->andReturn(false);

        $this->assertFalse(AppFiles::isHealthy());
    }

    public function test_an_object_store_is_healthy_when_it_answers_even_for_an_absent_object(): void
    {
        config(['filesystems.app_files_disk' => 'r2']);
        $disk = $this->mockDisk('r2');
        $disk->shouldReceive('fileExists')->once()->with('.deendoon-health-probe')->andReturn(false);

        $this->assertTrue(AppFiles::isHealthy());
    }

    public function test_an_object_store_is_unhealthy_when_it_cannot_be_reached(): void
    {
        config(['filesystems.app_files_disk' => 'r2']);
        $disk = $this->mockDisk('r2');
        $disk->shouldReceive('fileExists')->andThrow(new RuntimeException('403 Forbidden'));

        $this->assertFalse(AppFiles::isHealthy());
    }

    public function test_a_misconfigured_disk_is_unhealthy_rather_than_an_error(): void
    {
        config(['filesystems.app_files_disk' => 'does-not-exist']);

        $this->assertFalse(AppFiles::isHealthy());
    }

    // --- Single-request existence checks (no bucket LIST) ---

    public function test_a_write_checks_for_an_existing_object_with_one_head_style_call_only(): void
    {
        config(['filesystems.app_files_disk' => 'r2']);
        $disk = $this->mockDisk('r2');
        $disk->shouldReceive('fileExists')->once()->with('documents/t1/x/a.txt')->andReturn(false);
        $disk->shouldNotReceive('exists');
        $disk->shouldNotReceive('directoryExists');
        $disk->shouldReceive('put')->once()->andReturn(true);

        AppFiles::put('documents/t1/x/a.txt', 'data');
    }

    public function test_the_missing_file_check_uses_one_head_style_call_only(): void
    {
        config(['filesystems.app_files_disk' => 'r2']);
        $disk = $this->mockDisk('r2');
        $disk->shouldReceive('fileExists')->once()->with('documents/t1/x/a.pdf')->andReturn(true);
        $disk->shouldNotReceive('exists');
        $disk->shouldNotReceive('directoryExists');

        AppFiles::abortIfMissing('documents/t1/x/a.pdf');

        $this->addToAssertionCount(1);
    }

    public function test_the_object_store_health_probe_uses_one_head_style_call_only(): void
    {
        config(['filesystems.app_files_disk' => 'r2']);
        $disk = $this->mockDisk('r2');
        $disk->shouldReceive('fileExists')->once()->with('.deendoon-health-probe')->andReturn(false);
        $disk->shouldNotReceive('exists');
        $disk->shouldNotReceive('directoryExists');

        $this->assertTrue(AppFiles::isHealthy());
    }

    public function test_a_directory_is_not_a_downloadable_file(): void
    {
        Storage::fake('local');
        Storage::disk('local')->put('documents/t1/x/a.pdf', 'pdf');

        $this->expectException(NotFoundHttpException::class);

        AppFiles::abortIfMissing('documents/t1/x');
    }

    public function test_the_local_disk_behaves_as_before_for_files_and_health(): void
    {
        Storage::fake('local');

        AppFiles::put('documents/t1/x/a.pdf', 'pdf');
        AppFiles::abortIfMissing('documents/t1/x/a.pdf');

        Storage::disk('local')->assertExists('documents/t1/x/a.pdf');
        $this->assertTrue(AppFiles::isHealthy());
    }

    // --- Reading an uploaded file ---

    public function test_the_contents_of_a_readable_upload_are_returned(): void
    {
        $file = UploadedFile::fake()->createWithContent('note.pdf', 'hello bytes');

        $this->assertSame('hello bytes', AppFiles::contentsOf($file));
    }

    public function test_an_unreadable_upload_throws_instead_of_yielding_an_empty_string(): void
    {
        $unreadable = new UploadedFile('/nonexistent/dir/missing.pdf', 'missing.pdf', 'application/pdf', UPLOAD_ERR_NO_TMP_DIR, true);

        $this->expectException(FileStorageException::class);

        AppFiles::contentsOf($unreadable);
    }

    public function test_a_false_return_from_the_read_is_rejected_when_warnings_are_not_converted(): void
    {
        // Under Laravel's error handler a failed read raises an exception;
        // with warnings swallowed (another handler, or a CLI/queue context)
        // file_get_contents() returns false instead, which must not be
        // coerced to an empty string and stored.
        $unreadable = Mockery::mock(UploadedFile::class);
        $unreadable->shouldReceive('getRealPath')->andReturn('Z:/definitely/not/here/missing.pdf');

        set_error_handler(fn () => true);

        try {
            AppFiles::contentsOf($unreadable);
            $this->fail('Expected a FileStorageException.');
        } catch (FileStorageException $e) {
            $this->assertNull($e->getPrevious(), 'This case is the false return, not a converted warning.');
        } finally {
            restore_error_handler();
        }
    }

    // --- R2 client timeouts ---

    public function test_the_r2_timeouts_leave_headroom_for_the_largest_accepted_file_and_downloads_stay_buffered(): void
    {
        // Largest file any upload rule accepts, in KB, read from the real
        // validation rules so raising a limit later fails this test.
        $largestKb = 0;
        foreach ([
            [UploadCollectionCaseAttachmentRequest::class, 'file'],
            [UploadCustomerAttachmentRequest::class, 'file'],
            [UploadDebtAttachmentRequest::class, 'file'],
            [UploadProfessionalCollectionAttachmentRequest::class, 'file'],
            [UploadSupportTicketAttachmentRequest::class, 'file'],
            [StoreProfessionalCollectionTimelineEventRequest::class, 'attachments.*'],
            [UpdateCompanyProfileRequest::class, 'logo'],
        ] as [$request, $field]) {
            foreach ((new $request)->rules()[$field] as $rule) {
                if (is_string($rule) && str_starts_with($rule, 'max:')) {
                    $largestKb = max($largestKb, (int) substr($rule, 4));
                }
            }
        }

        $this->assertGreaterThan(0, $largestKb, 'Could not derive the largest accepted upload.');

        $http = config('filesystems.disks.r2.http');
        $largestBytes = $largestKb * 1024;

        // Connection set-up is tightly bounded (Guzzle's default is 300 s).
        $this->assertGreaterThanOrEqual(1, $http['connect_timeout']);
        $this->assertLessThanOrEqual(10, $http['connect_timeout']);

        // The total is bounded, but the largest file must fit with at least
        // 3x headroom over a 1 MiB/s link: a slow-but-working transfer is
        // not cut off, a hung one still is.
        $this->assertGreaterThan($http['connect_timeout'], $http['timeout']);
        $this->assertLessThanOrEqual(120, $http['timeout']);
        $this->assertLessThanOrEqual(
            1024 * 1024,
            $largestBytes / $http['timeout'],
            "A {$largestKb} KB file cannot be moved within {$http['timeout']} s at 1 MiB/s; raise the R2 timeout."
        );

        // Downloads are fetched in full before the client receives a byte,
        // which is what makes `timeout` a bound on R2 -> app time only.
        $this->assertNull(config('filesystems.disks.r2.stream_reads'), 'Enabling stream_reads changes what the timeout measures; revisit it.');
    }

    public function test_the_r2_disk_sets_http_timeouts_and_laravel_passes_them_to_the_s3_client_config(): void
    {
        $r2 = config('filesystems.disks.r2');

        $this->assertSame(['connect_timeout' => 5, 'timeout' => 30], $r2['http']);

        // createS3Driver() hands this array, unchanged apart from the
        // credentials, to `new S3Client(...)`; `http` is the SDK's
        // documented per-request option array (Guzzle options).
        $format = new ReflectionMethod(app('filesystem'), 'formatS3Config');
        $clientConfig = $format->invoke(app('filesystem'), $r2);

        $this->assertSame(['connect_timeout' => 5, 'timeout' => 30], $clientConfig['http']);
        $this->assertSame('when_required', $clientConfig['request_checksum_calculation']);
        $this->assertSame('private', $clientConfig['visibility']);
    }
}
