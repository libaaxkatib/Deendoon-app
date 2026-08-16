<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Admin\AdminDashboardService;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AdminDashboardController extends Controller
{
    public function __construct(private readonly AdminDashboardService $dashboard) {}

    public function index(Request $request): View
    {
        $admin = $request->user();

        return view('admin.dashboard', [
            'businessAndRecovery' => $this->dashboard->businessAndRecovery($admin),
            'systemAndPlatform' => $this->dashboard->systemAndPlatform(),
        ]);
    }
}
