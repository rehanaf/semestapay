<?php

use App\Http\Controllers\Api\v1\AdminController;
use App\Http\Controllers\Api\v1\AuthController;
use App\Http\Controllers\Api\v1\BillController;
use App\Http\Controllers\Api\v1\CardController;
use App\Http\Controllers\Api\v1\ItemController;
use App\Http\Controllers\Api\v1\MerchantController;
use App\Http\Controllers\Api\v1\Payment\DuitkuController;
use App\Http\Controllers\Api\v1\PaymentController;
use App\Http\Controllers\Api\v1\ProfileController;
use App\Http\Controllers\Api\v1\StudentController;
use App\Http\Controllers\Api\v1\StudentPortalController;
use App\Http\Controllers\Api\v1\StudentTransferController;
use App\Http\Controllers\Api\v1\TopupController;
use App\Http\Controllers\Api\v1\TransactionController;
use App\Http\Controllers\Api\v1\WalletController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/login', [AuthController::class, 'login'])
        ->middleware('throttle:10,1');
    Route::post('/auth/student-login', [AuthController::class, 'studentLogin'])
        ->middleware('throttle:10,1');
    Route::post('/auth/parent-login', [AuthController::class, 'parentLogin'])
        ->middleware('throttle:10,1');
    Route::post('/auth/send-otp', [AuthController::class, 'sendOtp'])
        ->middleware('throttle:5,1');
    Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp'])
        ->middleware('throttle:10,1');

    // Callback dan Inquiry Duitku bersifat publik dan tidak memakai token.
    Route::post('/payments/duitku/callback', [DuitkuController::class, 'callback'])
        ->name('duitku.callback');
    Route::post('/payments/duitku/inquiry', [DuitkuController::class, 'inquiry'])
        ->name('duitku.inquiry');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::get('/profile/student', [ProfileController::class, 'student']);
        Route::put('/profile/student', [ProfileController::class, 'updateStudent']);
        Route::post('/profile/student/avatar', [ProfileController::class, 'uploadStudentAvatar']);
        Route::get('/profile/me', [ProfileController::class, 'user']);
        Route::put('/profile/me', [ProfileController::class, 'updateUser']);
        Route::post('/profile/me/avatar', [ProfileController::class, 'uploadUserAvatar']);

        Route::get('/card/read/{uid}', [CardController::class, 'read']);

        Route::get('/wallet/{student}', [WalletController::class, 'show']);
        Route::get('/wallet/{student}/mutations', [WalletController::class, 'mutations']);

        Route::post('/topups', [TopupController::class, 'store']);

        Route::post('/payments/tap', [PaymentController::class, 'tap']);
        Route::post('/payments/{transaction}/reverse', [PaymentController::class, 'reverse']);

        Route::get('/payments/duitku/methods', [DuitkuController::class, 'methods']);
        Route::post('/payments/duitku/va', [DuitkuController::class, 'store']);
        Route::get('/student/topup/va', [DuitkuController::class, 'studentVa']);
        Route::get('/student/topup/vas', [DuitkuController::class, 'studentVas']);

        Route::get('/bills', [BillController::class, 'index']);
        Route::post('/bills/{bill}/pay', [BillController::class, 'pay']);

        // Data CRUD
        Route::get('/students', [StudentController::class, 'index']);
        Route::post('/students', [StudentController::class, 'store']);
        Route::put('/students/{student}', [StudentController::class, 'update']);

        Route::get('/items', [ItemController::class, 'index']);
        Route::post('/items', [ItemController::class, 'store']);
        Route::put('/items/{item}', [ItemController::class, 'update']);

        Route::get('/merchants', [MerchantController::class, 'index']);
        Route::get('/merchant/summary', [MerchantController::class, 'summary']);
        Route::get('/merchant/profile', [MerchantController::class, 'profile']);
        Route::put('/merchant/profile', [MerchantController::class, 'updateProfile']);
        Route::get('/merchant/reports', [MerchantController::class, 'reports']);
        Route::post('/merchant/cash-out', [MerchantController::class, 'cashOut']);
        Route::post('/merchants', [MerchantController::class, 'store']);

        Route::prefix('admin')->group(function () {
            Route::get('/audit-logs', [AdminController::class, 'auditLogs']);
            Route::post('/students/{student}/balance', [AdminController::class, 'setStudentBalance']);
            Route::post('/merchants/{merchant}/balance', [AdminController::class, 'setMerchantBalance']);
        });

        Route::get('/student/dashboard', [StudentPortalController::class, 'dashboard']);
        Route::get('/student/mutations', [StudentPortalController::class, 'mutations']);
        Route::get('/student/bills', [StudentPortalController::class, 'bills']);
        Route::get('/student/transfer/recipients', [StudentTransferController::class, 'recipients']);
        Route::post('/student/transfers', [StudentTransferController::class, 'store']);

        Route::get('/transactions', [TransactionController::class, 'index']);
    });
});
