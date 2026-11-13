<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\User;
use App\Services\AvatarService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ProfileController extends Controller
{
    public function __construct(private readonly AvatarService $avatars) {}

    public function student(Request $request): JsonResponse
    {
        $student = $this->authenticatedStudent($request);

        return response()->json([
            'student' => $this->studentPayload($student),
        ]);
    }

    public function updateStudent(Request $request): JsonResponse
    {
        $student = $this->authenticatedStudent($request);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:150',
            'username' => ['sometimes', 'nullable', 'string', 'max:60', Rule::unique('students', 'username')->ignore($student->id)],
            'email' => ['sometimes', 'nullable', 'email', 'max:150', Rule::unique('students', 'email')->ignore($student->id)],
            'phone_parent' => 'sometimes|nullable|string|max:20',
            'phone' => 'sometimes|nullable|string|max:20',
            'nik' => 'sometimes|nullable|string|max:32',
            'gender' => 'sometimes|nullable|string|max:20',
            'birth_date' => 'sometimes|nullable|date',
            'birth_place' => 'sometimes|nullable|string|max:100',
            'religion' => 'sometimes|nullable|string|max:50',
            'marital_status' => 'sometimes|nullable|string|max:20',
            'address' => 'sometimes|nullable|string',
            'parent_name' => 'sometimes|nullable|string|max:150',
            'parent_email' => 'sometimes|nullable|email|max:150',
            'password' => 'sometimes|nullable|string|min:6',
            'current_password' => 'sometimes|nullable|string',
            'pin' => 'sometimes|nullable|string|min:4',
            'current_pin' => 'sometimes|nullable|string',
            'avatar' => 'sometimes|nullable|string',
        ]);

        if (! empty($validated['password'])) {
            if (! $student->verifyPassword($validated['current_password'] ?? '')) {
                throw ValidationException::withMessages([
                    'current_password' => 'Kata sandi saat ini salah.',
                ]);
            }
            $validated['password_hash'] = Hash::make($validated['password']);
        }

        if (! empty($validated['pin'])) {
            if (! $student->verifyPin($validated['current_pin'] ?? '')) {
                throw ValidationException::withMessages([
                    'current_pin' => 'PIN saat ini salah.',
                ]);
            }
            $validated['pin_hash'] = Hash::make($validated['pin']);
        }

        if (! empty($validated['avatar'])) {
            $stored = $this->avatars->storeBase64($validated['avatar'], 'students');
            if ($stored !== null) {
                $this->avatars->delete($student->avatar_path);
                $validated['avatar_path'] = $stored;
            }
        }

        unset(
            $validated['password'],
            $validated['current_password'],
            $validated['pin'],
            $validated['current_pin'],
            $validated['avatar'],
        );

        $student->update($validated);

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'student' => $this->studentPayload($student->fresh('klass')),
        ]);
    }

    public function uploadStudentAvatar(Request $request): JsonResponse
    {
        $student = $this->authenticatedStudent($request);

        $validated = $request->validate([
            'avatar' => 'required|string',
        ]);

        $stored = $this->avatars->storeBase64($validated['avatar'], 'students');

        if ($stored === null) {
            throw ValidationException::withMessages([
                'avatar' => 'Foto tidak valid.',
            ]);
        }

        $this->avatars->delete($student->avatar_path);
        $student->update(['avatar_path' => $stored]);

        return response()->json([
            'message' => 'Foto profil berhasil diperbarui.',
            'avatar_url' => $student->avatarUrl(),
            'student' => $this->studentPayload($student->fresh('klass')),
        ]);
    }

    public function user(Request $request): JsonResponse
    {
        $user = $this->authenticatedUser($request);

        return response()->json([
            'user' => $this->userPayload($user),
            'merchant' => $user->merchant ? [
                'id' => $user->merchant->id,
                'name' => $user->merchant->name,
                'logo_url' => $user->merchant->logoUrl(),
            ] : null,
        ]);
    }

    public function updateUser(Request $request): JsonResponse
    {
        $user = $this->authenticatedUser($request);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:150',
            'username' => ['sometimes', 'nullable', 'string', 'max:60', Rule::unique('users', 'username')->ignore($user->id)],
            'email' => ['sometimes', 'nullable', 'email', 'max:150', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20', Rule::unique('users', 'phone')->ignore($user->id)],
            'password' => 'sometimes|nullable|string|min:6',
            'current_password' => 'sometimes|nullable|string',
            'avatar' => 'sometimes|nullable|string',
        ]);

        if (! empty($validated['password'])) {
            if (! $user->password || ! Hash::check($validated['current_password'] ?? '', $user->password)) {
                throw ValidationException::withMessages([
                    'current_password' => 'Kata sandi saat ini salah.',
                ]);
            }
            $validated['password'] = Hash::make($validated['password']);
        }

        if (! empty($validated['avatar'])) {
            $stored = $this->avatars->storeBase64($validated['avatar'], 'users');
            if ($stored !== null) {
                $this->avatars->delete($user->avatar_path);
                $validated['avatar_path'] = $stored;
            }
        }

        unset($validated['current_password'], $validated['avatar']);

        if (empty($validated['password'])) {
            unset($validated['password']);
        }

        $user->update($validated);

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'user' => $this->userPayload($user->fresh('merchant')),
        ]);
    }

    public function uploadUserAvatar(Request $request): JsonResponse
    {
        $user = $this->authenticatedUser($request);

        $validated = $request->validate([
            'avatar' => 'required|string',
        ]);

        $stored = $this->avatars->storeBase64($validated['avatar'], 'users');

        if ($stored === null) {
            throw ValidationException::withMessages([
                'avatar' => 'Foto tidak valid.',
            ]);
        }

        $this->avatars->delete($user->avatar_path);
        $user->update(['avatar_path' => $stored]);

        return response()->json([
            'message' => 'Foto profil berhasil diperbarui.',
            'avatar_url' => $user->avatarUrl(),
            'user' => $this->userPayload($user->fresh('merchant')),
        ]);
    }

    private function authenticatedStudent(Request $request): Student
    {
        $student = $request->user();

        if (! $student instanceof Student) {
            throw new AuthorizationException('Akses khusus aplikasi siswa.');
        }

        return $student;
    }

    private function authenticatedUser(Request $request): User
    {
        $user = $request->user();

        if (! $user instanceof User) {
            throw new AuthorizationException('Akses khusus akun pengguna.');
        }

        return $user;
    }

    /**
     * @return array<string, mixed>
     */
    private function studentPayload(Student $student): array
    {
        return [
            'id' => $student->id,
            'name' => $student->name,
            'nis' => $student->nis,
            'username' => $student->username,
            'email' => $student->email,
            'class' => $student->klass?->name,
            'class_id' => $student->class_id,
            'card_uid' => $student->card_uid,
            'card_status' => $student->card_status,
            'status' => $student->status,
            'balance' => (float) $student->balance,
            'daily_limit' => (float) $student->daily_limit,
            'currency' => $student->currency,
            'wallet_status' => $student->wallet_status,
            'avatar_url' => $student->avatarUrl(),
            'nik' => $student->nik,
            'gender' => $student->gender,
            'birth_date' => $student->birth_date?->toDateString(),
            'birth_place' => $student->birth_place,
            'religion' => $student->religion,
            'marital_status' => $student->marital_status,
            'address' => $student->address,
            'phone' => $student->phone,
            'phone_parent' => $student->phone_parent,
            'parent_name' => $student->parent_name,
            'parent_email' => $student->parent_email,
            'balance_updated_at' => $student->balance_updated_at,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_url' => $user->avatarUrl(),
            'merchant_id' => $user->merchant_id,
            'roles' => $user->getRoleNames(),
        ];
    }
}
