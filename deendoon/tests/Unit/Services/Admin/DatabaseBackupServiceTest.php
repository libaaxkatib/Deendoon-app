<?php

namespace Tests\Unit\Services\Admin;

use App\Services\Admin\DatabaseBackupService;
use Illuminate\Process\PendingProcess;
use Illuminate\Support\Facades\Process;
use RuntimeException;
use Tests\TestCase;

/**
 * Deliberately does NOT use RefreshDatabase — this service makes no
 * Eloquent/DB:: calls at all (only config() reads, Process, and the
 * filesystem), and overriding `database.default` to 'pgsql' to exercise
 * the real driver-detection branch would otherwise conflict with
 * RefreshDatabase's own transaction bookkeeping on the test suite's real
 * (sqlite) default connection. Restoring `database.default` in a
 * finally-block keeps this test from leaking config state into whichever
 * test runs next in the same process.
 */
class DatabaseBackupServiceTest extends TestCase
{
    private function withPgsqlDefault(callable $callback): mixed
    {
        $original = config('database.default');
        config(['database.default' => 'pgsql']);

        try {
            return $callback();
        } finally {
            config(['database.default' => $original]);
        }
    }

    public function test_creates_a_real_dump_file_via_pg_dump_and_returns_its_path(): void
    {
        $this->withPgsqlDefault(function () {
            Process::fake(function (PendingProcess $process) {
                foreach ((array) $process->command as $argument) {
                    if (is_string($argument) && str_starts_with($argument, '--file=')) {
                        file_put_contents(substr($argument, 7), "-- fake pg_dump output\n");
                    }
                }

                return Process::result(output: 'dump complete', exitCode: 0);
            });

            $result = (new DatabaseBackupService)->createDump();

            $this->assertFileExists($result['path']);
            $this->assertStringStartsWith('deendoon-backup-', $result['filename']);
            $this->assertStringEndsWith('.sql', $result['filename']);

            @unlink($result['path']);
        });
    }

    public function test_passes_the_password_via_environment_not_the_command_line(): void
    {
        $this->withPgsqlDefault(function () {
            config(['database.connections.pgsql.password' => 'super-secret-password']);

            Process::fake(function (PendingProcess $process) {
                foreach ((array) $process->command as $argument) {
                    $this->assertIsString($argument);
                    $this->assertStringNotContainsString('super-secret-password', $argument);

                    if (str_starts_with($argument, '--file=')) {
                        file_put_contents(substr($argument, 7), "-- fake\n");
                    }
                }

                return Process::result(output: '', exitCode: 0);
            });

            $result = (new DatabaseBackupService)->createDump();
            @unlink($result['path']);
        });
    }

    public function test_throws_when_pg_dump_exits_non_zero_and_removes_any_partial_file(): void
    {
        $this->withPgsqlDefault(function () {
            Process::fake(function (PendingProcess $process) {
                foreach ((array) $process->command as $argument) {
                    if (is_string($argument) && str_starts_with($argument, '--file=')) {
                        // Simulates a partial/corrupt file left behind by a failed run.
                        file_put_contents(substr($argument, 7), 'partial');
                    }
                }

                return Process::result(output: '', errorOutput: 'pg_dump: error: connection to server failed', exitCode: 1);
            });

            $this->expectException(RuntimeException::class);
            $this->expectExceptionMessage('exited with status 1');

            try {
                (new DatabaseBackupService)->createDump();
            } catch (RuntimeException $e) {
                // Confirm cleanup happened before re-throwing the assertion.
                $directory = storage_path('app/private/backups');
                $leftoverFiles = is_dir($directory) ? glob($directory.'/*partial*') : [];
                $this->assertEmpty($leftoverFiles ?: []);

                throw $e;
            }
        });
    }

    public function test_throws_when_the_active_connection_is_not_postgresql(): void
    {
        // The test suite's real default connection is sqlite — no config
        // override needed, this is the genuine current state.
        $this->assertNotSame('pgsql', config('database.default'));

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('only supported for the PostgreSQL driver');

        (new DatabaseBackupService)->createDump();
    }
}
