<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CreditRiskController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\CustomerImportController;
use App\Http\Controllers\DebtController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('register', [AuthController::class, 'register'])->middleware('throttle:register');
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:login');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);

        Route::get('customers', [CustomerController::class, 'index']);
        Route::post('customers', [CustomerController::class, 'store']);
        Route::post('customers/check-duplicate', [CustomerController::class, 'checkDuplicate']);
        Route::post('customers/import', [CustomerImportController::class, 'store']);
        Route::post('customers/import/{batch}/commit', [CustomerImportController::class, 'commit']);
        Route::post('customers/{customer}/restore', [CustomerController::class, 'restore'])->withTrashed();
        Route::get('customers/{customer}', [CustomerController::class, 'show']);
        Route::put('customers/{customer}', [CustomerController::class, 'update']);
        Route::post('customers/{customer}/archive', [CustomerController::class, 'archive']);
        Route::patch('customers/{customer}/status', [CustomerController::class, 'updateStatus']);
        Route::get('customers/{customer}/credit-profile', [CustomerController::class, 'creditProfile']);
        Route::patch('customers/{customer}/credit-limit', [CustomerController::class, 'updateCreditLimit']);
        Route::get('customers/{customer}/credit-score', [CreditRiskController::class, 'creditScore']);
        Route::patch('customers/{customer}/risk-level', [CreditRiskController::class, 'updateRiskLevel']);
        Route::post('customers/{customer}/debts', [DebtController::class, 'store']);

        Route::get('debts', [DebtController::class, 'index']);
        Route::get('debts/{debt}', [DebtController::class, 'show']);
        Route::put('debts/{debt}', [DebtController::class, 'update']);
        Route::patch('debts/{debt}/status', [DebtController::class, 'updateStatus']);
        Route::post('debts/{debt}/archive', [DebtController::class, 'archive']);
        Route::post('debts/{debt}/restore', [DebtController::class, 'restore'])->withTrashed();
        Route::get('debts/{debt}/timeline', [DebtController::class, 'timeline']);
        Route::patch('debts/{debt}/recovery-stage', [DebtController::class, 'updateRecoveryStage']);
    });
});
