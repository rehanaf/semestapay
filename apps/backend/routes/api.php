<?php

use App\Http\Controllers\Api\v1\AuthController;
use App\Http\Controllers\Api\v1\BillController;
use App\Http\Controllers\Api\v1\CardController;
use App\Http\Controllers\Api\v1\ItemController;
use App\Http\Controllers\Api\v1\MerchantController;
use App\Http\Controllers\Api\v1\PaymentController;
use App\Http\Controllers\Api\v1\StudentController;
use App\Http\Controllers\Api\v1\TopupController;
use App\Http\Controllers\Api\v1\TransactionController;
use App\Http\Controllers\Api\v1\WalletController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/login', [AuthController::class, 'login'])
        ->middleware('throttle:10,1');
    Route::post('/auth/send-otp', [AuthController::class, 'sendOtp'])
        ->middleware('throttle:5,1');
    Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp'])
        ->middleware('throttle:10,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::get('/card/read/{uid}', [CardController::class, 'read']);

        Route::get('/wallet/{student}', [WalletController::class, 'show']);
        Route::get('/wallet/{student}/mutations', [WalletController::class, 'mutations']);

        Route::post('/topups', [TopupController::class, 'store']);

        Route::post('/payments/tap', [PaymentController::class, 'tap']);
        Route::post('/payments/{transaction}/reverse', [PaymentController::class, 'reverse']);

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
        Route::post('/merchants', [MerchantController::class, 'store']);

        Route::get('/transactions', [TransactionController::class, 'index']);
    });
});
