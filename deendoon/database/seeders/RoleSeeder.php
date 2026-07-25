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
        // 'collection_officer' and 'deendoon_platform_administrator' are the
        // two additional roles Module 7 (Professional Collection) requires:
        // FR-041 E2 explicitly names Collection Officer by role (08 §5: "the
        // one place an FR names a specific role by name, not just
        // 'authorized user'"), and FR-072–076 require the Deendoon Platform
        // Administrator, a distinct (tenant_id = NULL) actor per 08 §5 —
        // neither is substitutable by the interim admin/sales_finance
        // simplification the way every other generic "authorized user"
        // requirement has been throughout this project.
        foreach (['admin', 'sales_finance', 'customer', 'collection_officer', 'deendoon_platform_administrator'] as $role) {
            Role::firstOrCreate(['name' => $role, 'guard_name' => 'web']);
        }
    }
}
