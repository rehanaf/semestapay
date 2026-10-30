<?php

use App\Exceptions\Domain\CardNotUsableException;
use App\Exceptions\Domain\DailyLimitExceededException;
use App\Exceptions\Domain\IdempotencyConflictException;
use App\Exceptions\Domain\InsufficientBalanceException;
use App\Exceptions\Domain\ShiftNotOpenException;
use App\Exceptions\Domain\StudentNotActiveException;
use App\Exceptions\Domain\WalletNotActiveException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->trustProxies(at: [
            '127.0.0.1',
            '::1',
        ]);

        $middleware->redirectGuestsTo(fn () => route('pos.login'));
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (InsufficientBalanceException $e, Request $request) {
            return $request->is('api/*')
                ? response()->json(['message' => $e->getMessage(), 'code' => 'INSUFFICIENT_BALANCE'], 422)
                : null;
        });

        $exceptions->render(function (DailyLimitExceededException $e, Request $request) {
            return $request->is('api/*')
                ? response()->json(['message' => $e->getMessage(), 'code' => 'DAILY_LIMIT_EXCEEDED'], 409)
                : null;
        });

        $exceptions->render(function (ShiftNotOpenException $e, Request $request) {
            return $request->is('api/*')
                ? response()->json(['message' => $e->getMessage(), 'code' => 'SHIFT_NOT_OPEN'], 409)
                : null;
        });

        $exceptions->render(function (CardNotUsableException $e, Request $request) {
            return $request->is('api/*')
                ? response()->json(['message' => $e->getMessage(), 'code' => 'CARD_BLOCKED'], 403)
                : null;
        });

        $exceptions->render(function (WalletNotActiveException $e, Request $request) {
            return $request->is('api/*')
                ? response()->json(['message' => $e->getMessage(), 'code' => 'WALLET_FROZEN'], 403)
                : null;
        });

        $exceptions->render(function (StudentNotActiveException $e, Request $request) {
            return $request->is('api/*')
                ? response()->json(['message' => $e->getMessage(), 'code' => 'STUDENT_INACTIVE'], 403)
                : null;
        });

        $exceptions->render(function (IdempotencyConflictException $e, Request $request) {
            return $request->is('api/*')
                ? response()->json(['message' => $e->getMessage(), 'code' => 'DUPLICATE_REQUEST'], 409)
                : null;
        });
    })->create();
