<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Item;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ItemController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Item::with('merchant');

        if ($merchantId = $request->query('merchant_id')) {
            $query->where('merchant_id', $merchantId);
        }

        if ($search = $request->query('search')) {
            $query->where('name', 'like', "%{$search}%");
        }

        $items = $query->orderBy('name')->get();

        return response()->json([
            'data' => $items->map(fn (Item $item) => [
                'id' => $item->id,
                'merchant_id' => $item->merchant_id,
                'merchant_name' => $item->merchant?->name ?? 'Kantin Utama',
                'name' => $item->name,
                'price' => (float) $item->price,
                'status' => $item->status ?? 'active',
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:150',
            'price' => 'required|numeric|min:0',
            'merchant_id' => 'nullable|integer',
            'status' => 'nullable|string',
        ]);

        $item = Item::create([
            'merchant_id' => $validated['merchant_id'] ?? 1,
            'name' => $validated['name'],
            'price' => $validated['price'],
            'status' => $validated['status'] ?? 'active',
        ]);

        return response()->json([
            'message' => 'Menu berhasil ditambahkan.',
            'data' => $item,
        ], 201);
    }

    public function update(Request $request, Item $item): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:150',
            'price' => 'sometimes|numeric|min:0',
            'status' => 'sometimes|string',
        ]);

        $item->update($validated);

        return response()->json([
            'message' => 'Menu berhasil diperbarui.',
            'data' => $item,
        ]);
    }
}
