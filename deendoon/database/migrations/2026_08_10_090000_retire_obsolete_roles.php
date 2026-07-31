<?php

use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Role;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): retires the interim `sales_finance` and
 * `customer` roles and the `collection_officer` role (never truly an
 * authentication role — it is an internal Deendoon operational
 * responsibility exercised only after a Professional Collection Request
 * is accepted, not a tenant-side login role) now that Version 1 has
 * exactly two account types: Business Owner (`admin`) and Platform
 * Administrator (`deendoon_platform_administrator`).
 *
 * Data migration, not a schema change to any project table. Reassigns
 * every existing holder of a retired role to `admin` before removing the
 * role itself, so no user is left with zero roles and no
 * model_has_roles row is left orphaned (that table's role_id already
 * cascades on delete of its role, per the spatie/laravel-permission
 * migration — deleting the retired Role rows is sufficient cleanup on
 * its own once every affected user already holds `admin`).
 */
return new class extends Migration
{
    private const RETIRED_ROLES = ['sales_finance', 'customer', 'collection_officer'];

    public function up(): void
    {
        Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);

        $retiredRoles = Role::whereIn('name', self::RETIRED_ROLES)->get();

        if ($retiredRoles->isEmpty()) {
            return;
        }

        User::role($retiredRoles->pluck('name'))->get()->each(
            fn (User $user) => $user->syncRoles(['admin'])
        );

        $retiredRoles->each->delete();
    }

    public function down(): void
    {
        // Deliberately irreversible: recreating the retired roles would not
        // restore which specific users previously held them (that mapping
        // was destructively collapsed onto `admin` in up()), so a down()
        // that merely recreates the role rows would misrepresent this as a
        // safe rollback. Reversing this decision requires a new Product
        // Owner decision, not a migration rollback.
        throw new RuntimeException(
            'This migration is not reversible — retiring these roles was a Product Owner decision, not a mechanical schema change. See docs/RBAC_Architecture_Amendment_Proposal.md.'
        );
    }
};
