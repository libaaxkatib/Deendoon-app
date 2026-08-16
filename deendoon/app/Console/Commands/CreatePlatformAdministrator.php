<?php

namespace App\Console\Commands;

use App\Http\Controllers\AuthController;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

use function Laravel\Prompts\confirm;
use function Laravel\Prompts\password;
use function Laravel\Prompts\text;

/**
 * Admin Panel bootstrap: there is no self-service signup for the Deendoon
 * Platform Administrator (registration only ever creates a tenant-scoped
 * Business Owner — {@see AuthController::register()}),
 * so the very first account, and any subsequent one, is created here.
 * `tenant_id` is deliberately left null — the defining trait of a Platform
 * Administrator per the Version 1 authentication model (RBAC Architecture
 * Amendment, Product Owner Decision, 2026-07-30) — and the role's
 * `guard_name` is `web` (seeded by {@see RoleSeeder}),
 * matching the Admin Panel's session-based `web` guard.
 */
class CreatePlatformAdministrator extends Command
{
    protected $signature = 'admin:create-platform-admin
        {--name= : Full name}
        {--email= : Login email}
        {--password= : Login password (omit to be prompted securely)}';

    protected $description = 'Create a Deendoon Platform Administrator account for the Super Admin Panel.';

    public function handle(): int
    {
        $name = $this->option('name') ?: text('Full name', required: true);
        $email = mb_strtolower(trim($this->option('email') ?: text('Email', required: true)));
        $plainPassword = $this->option('password') ?: password('Password', required: true);

        $validator = Validator::make(
            ['name' => $name, 'email' => $email, 'password' => $plainPassword],
            [
                'name' => ['required', 'string', 'max:255'],
                'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
                'password' => ['required', Password::defaults()],
            ]
        );

        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $message) {
                $this->error($message);
            }

            return self::FAILURE;
        }

        if (! $this->option('name') && ! $this->option('email') && ! $this->option('password')) {
            if (! confirm("Create Platform Administrator \"{$name}\" ({$email})?", default: true)) {
                $this->comment('Cancelled.');

                return self::SUCCESS;
            }
        }

        $admin = new User([
            'name' => $name,
            'email' => $email,
            'password' => $plainPassword,
        ]);
        $admin->save();
        $admin->assignRole('deendoon_platform_administrator');

        $this->info("Platform Administrator \"{$name}\" ({$email}) created.");

        return self::SUCCESS;
    }
}
