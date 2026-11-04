<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Merchant;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MerchantController extends Controller
{
    /**
     * Ringkasan merchant + saldo pendapatan untuk aplikasi SmPay Merchant.
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $merchant = null;

        if ($request->filled('merchant_id')) {
            $merchant = Merchant::with('outlets')->find($request->integer('merchant_id'));
        }

        if ($merchant === null && $user !== null) {
            $cashier = $user->cashiers()->with('outlet.merchant')->first();
            $merchant = $cashier?->outlet?->merchant;
        }

        $merchant ??= Merchant::with('outlets')->first();

        if ($merchant === null) {
            return response()->json([
                'message' => 'Merchant belum tersedia.',
                'code' => 'MERCHANT_NOT_FOUND',
            ], 404);
        }

        $merchant->loadMissing('outlets');

        $balance = (float) Transaction::where('merchant_id', $merchant->id)
            ->where('type', 'payment')
            ->where('status', 'posted')
            ->sum('amount');

        $todayIncome = (float) Transaction::where('merchant_id', $merchant->id)
            ->where('type', 'payment')
            ->where('status', 'posted')
            ->whereDate('created_at', today())
            ->sum('amount');

        $lastTransactionAt = Transaction::where('merchant_id', $merchant->id)
            ->where('type', 'payment')
            ->latest('created_at')
            ->value('created_at');

        return response()->json([
            'merchant' => [
                'id' => $merchant->id,
                'code' => 'MRC-'.str_pad((string) $merchant->id, 4, '0', STR_PAD_LEFT),
                'name' => $merchant->name,
                'type' => $merchant->type,
                'status' => $merchant->status,
                'balance' => $balance,
                'today_income' => $todayIncome,
                'transaction_count' => Transaction::where('merchant_id', $merchant->id)
                    ->where('type', 'payment')
                    ->where('status', 'posted')
                    ->count(),
                'last_transaction_at' => $lastTransactionAt,
                'outlets' => $merchant->outlets->map(fn ($outlet) => [
                    'id' => $outlet->id,
                    'code' => $outlet->code,
                    'name' => $outlet->name,
                    'status' => $outlet->status,
                ]),
            ],
        ]);
    }

    public function index(): JsonResponse
    {
        $merchants = Merchant::withCount(['items', 'outlets'])->get();

        return response()->json([
            'data' => $merchants->map(fn (Merchant $m) => [
                'id' => $m->id,
                'name' => $m->name,
                'type' => $m->type,
                'status' => $m->status,
                'items_count' => $m->items_count,
                'outlets_count' => $m->outlets_count,
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:150',
            'type' => 'nullable|string|max:50',
            'status' => 'nullable|string|max:20',
        ]);

        $merchant = Merchant::create([
            'name' => $validated['name'],
            'type' => $validated['type'] ?? 'canteen',
            'status' => $validated['status'] ?? 'active',
        ]);

        return response()->json([
            'message' => 'Merchant berhasil didaftarkan.',
            'data' => $merchant,
        ], 201);
    }
}
