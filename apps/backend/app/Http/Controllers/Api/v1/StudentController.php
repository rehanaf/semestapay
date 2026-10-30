<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\SchoolClass;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Student::with('klass');

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('nis', 'like', "%{$search}%")
                  ->orWhere('card_uid', 'like', "%{$search}%");
            });
        }

        if ($classId = $request->query('class_id')) {
            $query->where('class_id', $classId);
        }

        $students = $query->orderBy('nis')->get();

        return response()->json([
            'data' => $students->map(fn (Student $s) => [
                'id' => $s->id,
                'nis' => $s->nis,
                'name' => $s->name,
                'class_name' => $s->klass?->name ?? 'Tanpa Kelas',
                'class_id' => $s->class_id,
                'card_uid' => $s->card_uid,
                'card_status' => $s->card_status ?? 'active',
                'balance' => (float) $s->balance,
                'daily_limit' => (float) $s->daily_limit,
                'status' => $s->status ?? 'active',
                'phone_parent' => $s->phone_parent,
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nis' => 'required|string|unique:students,nis',
            'name' => 'required|string|max:150',
            'class_id' => 'nullable|integer',
            'card_uid' => 'nullable|string|unique:students,card_uid',
            'balance' => 'nullable|numeric|min:0',
            'daily_limit' => 'nullable|numeric|min:0',
            'phone_parent' => 'nullable|string',
        ]);

        $student = Student::create([
            'nis' => $validated['nis'],
            'name' => $validated['name'],
            'class_id' => $validated['class_id'] ?? 1,
            'card_uid' => $validated['card_uid'] ?? null,
            'balance' => $validated['balance'] ?? 0,
            'daily_limit' => $validated['daily_limit'] ?? 50000,
            'phone_parent' => $validated['phone_parent'] ?? null,
            'status' => 'active',
            'card_status' => !empty($validated['card_uid']) ? 'active' : 'unassigned',
            'currency' => 'IDR',
        ]);

        return response()->json([
            'message' => 'Santri berhasil didaftarkan.',
            'data' => $student->load('klass'),
        ], 201);
    }

    public function update(Request $request, Student $student): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:150',
            'class_id' => 'sometimes|nullable|integer',
            'card_uid' => 'sometimes|nullable|string',
            'daily_limit' => 'sometimes|numeric|min:0',
            'balance' => 'sometimes|numeric|min:0',
            'status' => 'sometimes|string',
            'card_status' => 'sometimes|string',
        ]);

        $student->update($validated);

        return response()->json([
            'message' => 'Data santri berhasil diperbarui.',
            'data' => $student->fresh('klass'),
        ]);
    }
}
