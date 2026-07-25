<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Needed so the React + TypeScript Super Admin Web Dashboard (a separate
    | origin) can call this API from the browser. The Flutter mobile app is
    | not subject to browser CORS and is unaffected by this file.
    |
    | Bearer tokens are sent via the Authorization header, not cookies, so
    | supports_credentials stays false.
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_filter(explode(',', env('CORS_ALLOWED_ORIGINS', ''))),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
