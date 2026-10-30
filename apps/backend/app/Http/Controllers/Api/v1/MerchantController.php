<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Merchant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MerchantController extends Controller
{
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
