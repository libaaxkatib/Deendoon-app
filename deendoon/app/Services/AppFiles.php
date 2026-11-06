<?php

namespace App\Services;

use App\Exceptions\FileStorageException;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use InvalidArgumentException;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Throwable;

/**
 * The single place that decides which filesystem disk holds tenant files
 * (generated PDFs, uploaded attachments, company logos) and how they are
 * written, read, deleted and health-checked.
 *
 * The disk comes from `filesystems.app_files_disk` (env `APP_FILES_DISK`),
 * which defaults to `local` — so with the variable unset every file still
 * lives on the same private local disk as before. Setting it to `r2` moves
 * all of them to the Cloudflare R2 disk without touching any caller: the
 * relative keys already stored in the database
 * (`documents/{tenant}/{folder}/{file}`, `branding/{tenant}/logo.{ext}`)
 * are valid keys on either disk.
 */
final class AppFiles
{
    private const DEFAULT_DISK = 'local';

    /**
     * An object that is never expected to exist. Asking an object store
     * whether this file exists answers false when the store is reachable and
     * the credentials are valid, and throws when either is not — a health
     * signal that works on an empty bucket and needs only the object-read
     * permission, because fileExists() is a single HEAD request. (exists()
     * would follow a miss with a bucket LIST, since it also looks for a
     * "directory" of that name: a second request and a second permission.)
     */
    private const HEALTH_PROBE_KEY = '.deendoon-health-probe';

    public static function diskName(): string
    {
        $name = config('filesystems.app_files_disk') ?: self::DEFAULT_DISK;

        if (! is_array(config("filesystems.disks.{$name}"))) {
            throw new InvalidArgumentException("APP_FILES_DISK refers to a filesystem disk that is not defined: [{$name}].");
        }

        return $name;
    }

    public static function disk(): FilesystemAdapter
    {
        return Storage::disk(self::diskName());
    }

    /**
     * Stores $contents at $path, or throws {@see FileStorageException} —
     * never returns after a failed write, so the caller's surrounding
     * transaction rolls back instead of saving a row for a missing file.
     *
     * If $path did not exist beforehand and this runs inside a database
     * transaction, the new object is deleted again should that transaction
     * roll back. A path that already existed (the company logo is rewritten
     * in place) is left alone: deleting it would destroy the previous file
     * the rolled-back row still points at.
     */
    public static function put(string $path, string $contents): void
    {
        $diskName = self::diskName();

        try {
            $disk = Storage::disk($diskName);
            $isNewObject = ! $disk->fileExists($path);
            $stored = $disk->put($path, $contents);
        } catch (Throwable $e) {
            throw new FileStorageException("Could not store file [{$path}] on disk [{$diskName}].", 0, $e);
        }

        if (! $stored) {
            throw new FileStorageException("Could not store file [{$path}] on disk [{$diskName}].");
        }

        if ($isNewObject) {
            self::deleteIfRolledBack($path, $diskName);
        }
    }

    /**
     * The bytes of an uploaded file, or {@see FileStorageException} when they
     * cannot be read. file_get_contents() reports failure as false or, under
     * Laravel's error handler, as an exception; a bare false would otherwise
     * be coerced to an empty string and stored as an empty object with a
     * database row pointing at it.
     */
    public static function contentsOf(UploadedFile $file): string
    {
        try {
            $contents = file_get_contents($file->getRealPath());
        } catch (Throwable $e) {
            throw new FileStorageException('Could not read the uploaded file.', 0, $e);
        }

        if ($contents === false) {
            throw new FileStorageException('Could not read the uploaded file.');
        }

        return $contents;
    }

    /**
     * 404 when the file is gone (for example an upload lost before storage
     * was persistent), 503 when the disk itself cannot be reached — a
     * missing file and a broken disk must not look the same.
     */
    public static function abortIfMissing(string $path): void
    {
        try {
            $exists = self::disk()->fileExists($path);
        } catch (Throwable $e) {
            throw new FileStorageException('Could not check file storage.', 0, $e);
        }

        abort_unless($exists, 404, 'File not found.');
    }

    public static function download(string $path, string $downloadName): StreamedResponse
    {
        self::abortIfMissing($path);

        return self::disk()->download($path, $downloadName);
    }

    /**
     * Best-effort delete for use after the database change has committed:
     * the row is already gone, so a failing delete must not turn a
     * successful request into an error. The failure is reported instead.
     */
    public static function delete(string $path, ?string $diskName = null): void
    {
        try {
            Storage::disk($diskName ?? self::diskName())->delete($path);
        } catch (Throwable $e) {
            report($e);
        }
    }

    /**
     * Whether the configured disk is usable, for the admin dashboard. A
     * local disk is healthy when its root exists (unchanged from before); an
     * object store is healthy when it can be asked about an object.
     */
    public static function isHealthy(): bool
    {
        try {
            $name = self::diskName();
            $disk = Storage::disk($name);

            // The one place exists() is still right: a local disk's root is
            // a directory, which fileExists() would report as absent.
            if (config("filesystems.disks.{$name}.driver") === 'local') {
                return (bool) $disk->exists('');
            }

            $disk->fileExists(self::HEALTH_PROBE_KEY);

            return true;
        } catch (Throwable) {
            return false;
        }
    }

    private static function deleteIfRolledBack(string $path, string $diskName): void
    {
        try {
            DB::afterRollBack(fn () => self::delete($path, $diskName));
        } catch (Throwable $e) {
            report($e);
        }
    }
}
