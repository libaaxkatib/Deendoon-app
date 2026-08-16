<?php

namespace App\Services\Admin;

use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Process;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Module 8 — System Management, on-demand local database backup only —
 * no cloud/off-site storage, no new package (shells out to the `pg_dump`
 * binary via Laravel's own Process facade, already part of the framework).
 *
 * This project's dev/prod database is PostgreSQL (deendoon/CLAUDE.md).
 * The test suite's sqlite connection is never dumped by this service —
 * tests fake the Process call instead (Process::fake()), matching how
 * every other "shell out to a real binary" concern in this codebase is
 * tested. If invoked against a non-pgsql connection, this fails loudly
 * rather than silently producing an empty/wrong file.
 *
 * Credentials are read from the framework's own resolved config (never
 * hardcoded, never placed in a command-line argument where they'd be
 * visible via a process listing) and passed to `pg_dump` exclusively via
 * the `PGPASSWORD` environment variable, the same mechanism `pg_dump`
 * itself documents for non-interactive password passing.
 */
class DatabaseBackupService
{
    /**
     * A private subdirectory of the 'local' disk (storage/app/private),
     * never web-served — deliberately separate from 'documents/', where
     * tenant-uploaded files live, so a backup can never collide with or
     * expose an existing upload.
     */
    private const BACKUP_SUBDIR = 'backups';

    private const DUMP_TIMEOUT_SECONDS = 300;

    /**
     * @return array{path: string, filename: string}
     */
    public function createDump(): array
    {
        $connectionName = config('database.default');
        $connection = config("database.connections.{$connectionName}");

        if (! is_array($connection) || ($connection['driver'] ?? null) !== 'pgsql') {
            throw new RuntimeException(
                "Database backup is only supported for the PostgreSQL driver; the active connection ('{$connectionName}') is not PostgreSQL."
            );
        }

        $directory = storage_path('app/private/'.self::BACKUP_SUBDIR);
        File::ensureDirectoryExists($directory);

        // Server-generated only — never derived from any request input, so
        // there is no path-traversal/arbitrary-filename surface at all.
        $filename = sprintf('deendoon-backup-%s-%s.sql', now()->format('Y-m-d_His'), Str::random(8));
        $path = $directory.DIRECTORY_SEPARATOR.$filename;

        $binary = env('PG_DUMP_BINARY', 'pg_dump');

        // quietly() (Symfony's disableOutput()) is deliberate, not just an
        // optimization: Symfony Process's Windows pipe handling otherwise
        // buffers the child's stdout/stderr through temp files resolved
        // via THIS (parent) PHP process's sys_get_temp_dir() — observed
        // to resolve to an unwritable system path under `php artisan
        // serve` on Windows regardless of TMP/TEMP/TMPDIR env or ini
        // overrides. pg_dump's actual output already goes straight to
        // --file=$path, not stdout, so nothing meaningful is lost;
        // success/failure is still determined honestly via the real exit
        // code, never assumed.
        $result = Process::timeout(self::DUMP_TIMEOUT_SECONDS)
            ->env(['PGPASSWORD' => (string) ($connection['password'] ?? '')])
            ->quietly()
            ->run([
                $binary,
                '--host='.$connection['host'],
                '--port='.(string) $connection['port'],
                '--username='.$connection['username'],
                '--format=plain',
                '--no-password',
                '--file='.$path,
                $connection['database'],
            ]);

        if ($result->failed()) {
            if (is_file($path)) {
                @unlink($path);
            }

            throw new RuntimeException("Database backup failed: pg_dump exited with status {$result->exitCode()}.");
        }

        if (! is_file($path) || filesize($path) === 0) {
            throw new RuntimeException('Database backup failed: pg_dump reported success but produced no output file.');
        }

        return ['path' => $path, 'filename' => $filename];
    }
}
