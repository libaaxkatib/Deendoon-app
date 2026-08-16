<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\View\View;

/**
 * Admin Panel — every sidebar module not yet built shows this honest
 * "coming soon" page instead of a broken link or a hidden nav item,
 * matching the same pattern the mobile app already uses for unbuilt
 * screens (`core/widgets/coming_soon.dart`). Each module is a real,
 * planned increment — not omitted, just not yet implemented.
 */
class AdminPlaceholderController extends Controller
{
    /**
     * @var array<string, string>
     */
    private const MODULE_TITLES = [
        'settings' => 'Settings',
    ];

    public function show(string $module): View
    {
        return view('admin.placeholder', [
            'title' => self::MODULE_TITLES[$module] ?? ucwords(str_replace('-', ' ', $module)),
        ]);
    }
}
