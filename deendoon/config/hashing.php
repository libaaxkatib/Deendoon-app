<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Hash Driver
    |--------------------------------------------------------------------------
    |
    | Argon2id is the sole default per the approved Security & RBAC
    | specification (08_Security_and_RBAC.md). Bcrypt is retained below only
    | as a compatibility fallback, not as a co-equal option.
    |
    | Project-specific Argon2id configuration.
    | Review periodically as Laravel and PHP recommendations evolve.
    |
    */

    'driver' => 'argon2id',

    'bcrypt' => [
        'rounds' => env('BCRYPT_ROUNDS', 12),
        'verify' => true,
    ],

    'argon2id' => [
        'memory' => 65536,
        'threads' => 1,
        'time' => 4,
        'verify' => true,
    ],

    'rehash_on_login' => true,

];
