<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

class RoleSeeder extends Seeder
{
    /**
     * Seeds the application's roles. firstOrCreate keeps this idempotent
     * across repeated runs.
     */
    public function run(): void
    {
        foreach (['admin', 'sales_finance', 'customer'] as $role) {
            Role::firstOrCreate(['name' => $role, 'guard_name' => 'web']);
        }
    }
}
