<?php

namespace App\Exceptions;

use App\Services\AppFiles;
use RuntimeException;

/**
 * Thrown by {@see AppFiles} when the configured file disk cannot store, read
 * or inspect a file. Local-disk writes fail silently by default (`throw =>
 * false` makes Storage::put() return false), so without this a database row
 * would be saved for a file that was never written. Rendered as a 503 JSON
 * response on API routes by bootstrap/app.php, and as a redirect-back error
 * by the admin upload actions; the underlying driver exception is kept as
 * `$previous` for the log and never shown to a caller.
 */
class FileStorageException extends RuntimeException
{
    /**
     * The only text a caller ever sees for a storage failure: no paths,
     * bucket names, endpoints or driver messages.
     */
    public const USER_MESSAGE = 'File storage is temporarily unavailable. Please try again.';
}
