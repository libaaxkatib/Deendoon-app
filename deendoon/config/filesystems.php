<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Filesystem Disk
    |--------------------------------------------------------------------------
    |
    | Here you may specify the default filesystem disk that should be used
    | by the framework. The "local" disk, as well as a variety of cloud
    | based disks are available to your application for file storage.
    |
    */

    'default' => env('FILESYSTEM_DISK', 'local'),

    /*
    |--------------------------------------------------------------------------
    | Tenant Files Disk
    |--------------------------------------------------------------------------
    |
    | The disk that holds every tenant file: generated PDFs, uploaded
    | attachments and company logos. Resolved in one place
    | (App\Services\AppFiles). "local" keeps them on the private local disk;
    | "r2" stores them in Cloudflare R2. Independent of FILESYSTEM_DISK so
    | the framework default is never changed by accident.
    |
    */

    'app_files_disk' => env('APP_FILES_DISK', 'local'),

    /*
    |--------------------------------------------------------------------------
    | Filesystem Disks
    |--------------------------------------------------------------------------
    |
    | Below you may configure as many filesystem disks as necessary, and you
    | may even configure multiple disks for the same driver. Examples for
    | most supported storage drivers are configured here for reference.
    |
    | Supported drivers: "local", "ftp", "sftp", "s3"
    |
    */

    'disks' => [

        'local' => [
            'driver' => 'local',
            'root' => storage_path('app/private'),
            'serve' => true,
            'throw' => false,
            'report' => false,
        ],

        'public' => [
            'driver' => 'local',
            'root' => storage_path('app/public'),
            'url' => rtrim(env('APP_URL', 'http://localhost'), '/').'/storage',
            'visibility' => 'public',
            'throw' => false,
            'report' => false,
        ],

        's3' => [
            'driver' => 's3',
            'key' => env('AWS_ACCESS_KEY_ID'),
            'secret' => env('AWS_SECRET_ACCESS_KEY'),
            'region' => env('AWS_DEFAULT_REGION'),
            'bucket' => env('AWS_BUCKET'),
            'url' => env('AWS_URL'),
            'endpoint' => env('AWS_ENDPOINT'),
            'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
            'throw' => false,
            'report' => false,
        ],

        // Cloudflare R2 (S3-compatible). Reads the standard AWS_* variable
        // names so the Railway variables need no renaming: AWS_DEFAULT_REGION
        // is "auto" and AWS_ENDPOINT is
        // https://<account-id>.r2.cloudflarestorage.com for R2.
        'r2' => [
            'driver' => 's3',
            'key' => env('AWS_ACCESS_KEY_ID'),
            'secret' => env('AWS_SECRET_ACCESS_KEY'),
            'region' => env('AWS_DEFAULT_REGION', 'auto'),
            'bucket' => env('AWS_BUCKET'),
            'endpoint' => env('AWS_ENDPOINT'),
            'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
            // The S3 adapter sends an explicit `x-amz-acl` header with every
            // write (PutObject and multipart uploads), derived from this
            // visibility; with none configured it falls back to "private".
            // Every tenant file is private, so it is stated explicitly rather
            // than left to that default. R2 documents the header as
            // unsupported but is reported to accept "private"; confirm
            // against a development bucket before enabling this disk.
            'visibility' => 'private',
            // Only compute/validate checksums where the S3 API requires
            // them: the AWS SDK's newer default (always) sends trailing
            // checksums that S3-compatible stores may not support.
            'request_checksum_calculation' => 'when_required',
            'response_checksum_validation' => 'when_required',
            // Seconds, passed through to the S3 client for every request.
            // Guzzle's own defaults are a 300 s connect wait and no total
            // limit, so one hung request would hold a PHP worker and, for
            // uploads, an open database transaction.
            //
            // `timeout` is the TOTAL time one request may take (cURL's
            // CURLOPT_TIMEOUT_MS). That cannot cut off a download early
            // because this disk deliberately leaves `stream_reads` unset
            // (Laravel then passes false): the object is fetched from R2 in
            // full before the first byte goes to the client, so the limit
            // covers only the R2 -> app transfer, never a slow phone link.
            // Uploads are capped at 10 MB by validation, so 30 s needs only
            // about 0.35 MB/s. Re-size this if that cap is ever raised; a
            // test ties the two together. (If streaming were ever enabled,
            // Guzzle switches to its stream handler and `timeout` becomes a
            // per-read idle limit instead, which is also safe here.)
            'http' => [
                'connect_timeout' => 5,
                'timeout' => 30,
            ],
            // A failed write must raise, not return false.
            'throw' => true,
            'report' => false,
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Symbolic Links
    |--------------------------------------------------------------------------
    |
    | Here you may configure the symbolic links that will be created when the
    | `storage:link` Artisan command is executed. The array keys should be
    | the locations of the links and the values should be their targets.
    |
    */

    'links' => [
        public_path('storage') => storage_path('app/public'),
    ],

];
