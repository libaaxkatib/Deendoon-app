<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

class RoleSeeder extends Seeder
{
    /**
     * Seeds the application's roles. firstOrCreate keeps this idempotent
     * across repeated runs.
     *
     * Version 1 authentication model (RBAC Architecture Amendment, Product
     * Owner Decision, 2026-07-30): exactly two account types exist —
     * Business Owner (Customer Mobile App, this role) and Platform
     * Administrator (Super Admin Web Dashboard, tenant_id null). The
     * former interim `sales_finance`/`customer` roles and the
     * `collection_officer` role (never an authentication role — it is an
     * internal Deendoon operational responsibility exercised only after a
     * Professional Collection Request is accepted) are retired; see
     * `2026_08_10_090000_retire_obsolete_roles.php` for the migration that
     * reassigns any existing holders of those roles before they're removed.
     */
    public function run(): void
    {
        foreach (['admin', 'deendoon_platform_administrator'] as $role) {
            Role::firstOrCreate(['name' => $role, 'guard_name' => 'web']);
        }
    }
}
