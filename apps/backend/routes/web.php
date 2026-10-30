<?php

use App\Http\Controllers\Pos\PosController;
use App\Http\Controllers\Pos\PosLoginController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('pos')->name('pos.')->group(function () {
    Route::get('/login', [PosLoginController::class, 'show'])
        ->middleware('guest')
        ->name('login');
    Route::post('/login', [PosLoginController::class, 'login'])
        ->middleware('guest')
        ->middleware('throttle:10,1')
        ->name('login.attempt');
    Route::post('/logout', [PosLoginController::class, 'logout'])
        ->middleware('auth')
        ->name('logout');
    Route::get('/', [PosController::class, 'index'])
        ->middleware('auth')
        ->name('index');
});
