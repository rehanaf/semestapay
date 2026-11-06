<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StudentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Student::with('klass');

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('nis', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('card_uid', 'like', "%{$search}%");
            });
        }

        if ($classId = $request->query('class_id')) {
            $query->where('class_id', $classId);
        }

        $students = $query->orderBy('nis')->get();

        return response()->json([
            'data' => $students->map(fn (Student $s) => $this->payload($s)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nis' => 'required|string|unique:students,nis',
            'username' => 'nullable|string|max:60|unique:students,username',
            'name' => 'required|string|max:150',
            'class_id' => 'nullable|integer',
            'card_uid' => 'nullable|string|unique:students,card_uid',
            'balance' => 'nullable|numeric|min:0',
            'daily_limit' => 'nullable|numeric|min:0',
            'phone_parent' => 'nullable|string',
            'email' => 'nullable|email|max:150|unique:students,email',
            'password' => 'nullable|string|min:6',
            'pin' => 'nullable|string|min:4',
            'nik' => 'nullable|string|max:32',
            'gender' => 'nullable|string|max:20',
            'birth_date' => 'nullable|date',
            'address' => 'nullable|string',
            'parent_name' => 'nullable|string|max:150',
            'parent_email' => 'nullable|email|max:150',
        ]);

        $student = Student::create([
            'nis' => $validated['nis'],
            'username' => $validated['username'] ?? $validated['nis'],
            'name' => $validated['name'],
            'class_id' => $validated['class_id'] ?? 1,
            'card_uid' => $validated['card_uid'] ?? null,
            'balance' => $validated['balance'] ?? 0,
            'daily_limit' => $validated['daily_limit'] ?? 50000,
            'phone_parent' => $validated['phone_parent'] ?? null,
            'email' => $validated['email'] ?? null,
            'password_hash' => isset($validated['password']) ? Hash::make($validated['password']) : null,
            'pin_hash' => isset($validated['pin']) ? Hash::make($validated['pin']) : null,
            'nik' => $validated['nik'] ?? null,
            'gender' => $validated['gender'] ?? null,
            'birth_date' => $validated['birth_date'] ?? null,
            'address' => $validated['address'] ?? null,
            'parent_name' => $validated['parent_name'] ?? null,
            'parent_email' => $validated['parent_email'] ?? null,
            'status' => 'active',
            'card_status' => ! empty($validated['card_uid']) ? 'active' : 'unassigned',
            'currency' => 'IDR',
        ]);

        return response()->json([
            'message' => 'Santri berhasil didaftarkan.',
            'data' => $this->payload($student->load('klass')),
        ], 201);
    }

    public function update(Request $request, Student $student): JsonResponse
    {
        $validated = $request->validate([
            'nis' => ['sometimes', 'string', 'max:30', Rule::unique('students', 'nis')->ignore($student->id)],
            'username' => ['sometimes', 'nullable', 'string', 'max:60', Rule::unique('students', 'username')->ignore($student->id)],
            'name' => 'sometimes|string|max:150',
            'class_id' => 'sometimes|nullable|integer',
            'card_uid' => 'sometimes|nullable|string',
            'daily_limit' => 'sometimes|numeric|min:0',
            'balance' => 'sometimes|numeric|min:0',
            'status' => 'sometimes|string',
            'card_status' => 'sometimes|string',
            'email' => ['sometimes', 'nullable', 'email', 'max:150', Rule::unique('students', 'email')->ignore($student->id)],
            'password' => 'sometimes|nullable|string|min:6',
            'pin' => 'sometimes|nullable|string|min:4',
            'phone_parent' => 'sometimes|nullable|string',
            'nik' => 'sometimes|nullable|string|max:32',
            'gender' => 'sometimes|nullable|string|max:20',
            'birth_date' => 'sometimes|nullable|date',
            'address' => 'sometimes|nullable|string',
            'parent_name' => 'sometimes|nullable|string|max:150',
            'parent_email' => 'sometimes|nullable|email|max:150',
        ]);

        if (array_key_exists('password', $validated)) {
            $validated['password_hash'] = $validated['password'] ? Hash::make($validated['password']) : null;
            unset($validated['password']);
        }

        if (array_key_exists('pin', $validated)) {
            $validated['pin_hash'] = $validated['pin'] ? Hash::make($validated['pin']) : null;
            unset($validated['pin']);
        }

        $student->update($validated);

        return response()->json([
            'message' => 'Data santri berhasil diperbarui.',
            'data' => $this->payload($student->fresh('klass')),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(Student $student): array
    {
        return [
            'id' => $student->id,
            'nis' => $student->nis,
            'username' => $student->username,
            'name' => $student->name,
            'class_name' => $student->klass?->name ?? 'Tanpa Kelas',
            'class_id' => $student->class_id,
            'card_uid' => $student->card_uid,
            'card_status' => $student->card_status ?? 'active',
            'balance' => (float) $student->balance,
            'daily_limit' => (float) $student->daily_limit,
            'status' => $student->status ?? 'active',
            'phone_parent' => $student->phone_parent,
            'email' => $student->email,
            'avatar_url' => $student->avatarUrl(),
            'nik' => $student->nik,
            'gender' => $student->gender,
            'birth_date' => $student->birth_date?->toDateString(),
            'address' => $student->address,
            'parent_name' => $student->parent_name,
            'parent_email' => $student->parent_email,
        ];
    }
}
