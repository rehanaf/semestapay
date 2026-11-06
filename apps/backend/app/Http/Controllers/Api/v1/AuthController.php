<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\v1\SendOtpRequest;
use App\Http\Requests\Api\v1\VerifyOtpRequest;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    private const OTP_TTL_SECONDS = 300;

    /**
     * Autentikasi email/password untuk Web Dashboard (Admin, School, Merchant).
     */
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'string'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string'],
        ]);

        $identifier = $credentials['email'];
        $user = User::where('email', $identifier)
            ->orWhere('username', $identifier)
            ->orWhere('phone', $identifier)
            ->first();

        if (! $user || ! $user->password || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Kredensial yang diberikan tidak cocok dengan data kami.'],
            ]);
        }

        if ($user->status !== 'active') {
            throw ValidationException::withMessages([
                'email' => ['Akun Anda berstatus non-aktif. Silakan hubungi administrator.'],
            ]);
        }

        $deviceName = $credentials['device_name'] ?? 'web-dashboard';
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userPayload($user),
        ]);
    }

    /**
     * Login aplikasi siswa (SmPay Mobile) memakai username/email + kata sandi.
     * Login lama (NIS + PIN) tetap diterima untuk kompatibilitas perangkat.
     */
    public function studentLogin(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'username' => ['nullable', 'string'],
            'email' => ['nullable', 'string'],
            'password' => ['nullable', 'string'],
            'nis' => ['nullable', 'string'],
            'pin' => ['nullable', 'string'],
            'device_name' => ['nullable', 'string'],
        ]);

        $identifier = $credentials['username']
            ?? $credentials['email']
            ?? $credentials['nis']
            ?? null;
        $password = $credentials['password'] ?? null;
        $pin = $credentials['pin'] ?? null;

        if ($identifier === null || $identifier === '' || ($password === null && $pin === null)) {
            throw ValidationException::withMessages([
                'username' => ['Username/email dan kata sandi wajib diisi.'],
            ]);
        }

        $student = Student::with('klass')
            ->where(function ($query) use ($identifier) {
                $query->where('username', $identifier)
                    ->orWhere('email', $identifier)
                    ->orWhere('nis', $identifier);
            })
            ->first();

        if ($student === null || $student->status !== 'active') {
            throw ValidationException::withMessages([
                'username' => ['Akun santri tidak terdaftar atau tidak aktif.'],
            ]);
        }

        if ($password !== null) {
            if (! $student->verifyPassword($password)) {
                throw ValidationException::withMessages([
                    'password' => ['Kata sandi yang Anda masukkan salah.'],
                ]);
            }
        } elseif (! $student->verifyPin($pin)) {
            throw ValidationException::withMessages([
                'pin' => ['PIN yang Anda masukkan salah.'],
            ]);
        }

        $deviceName = $credentials['device_name'] ?? 'student-flutter-app';
        $token = $student->createToken($deviceName, ['student'])->plainTextToken;

        return response()->json([
            'token' => $token,
            'student' => $this->studentPayload($student),
        ]);
    }

    /**
     * Login cepat wali santri (SmPay Ortu) memakai nomor HP + NIS anak.
     */
    public function parentLogin(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'phone' => ['required', 'string'],
            'nis' => ['required', 'string'],
            'device_name' => ['nullable', 'string'],
        ]);

        $student = Student::where('nis', $credentials['nis'])
            ->where('phone_parent', $credentials['phone'])
            ->first();

        if ($student === null) {
            throw ValidationException::withMessages([
                'nis' => ['NIS anak tidak cocok dengan nomor HP wali yang terdaftar.'],
            ]);
        }

        $user = User::updateOrCreate(
            ['phone' => $credentials['phone']],
            ['name' => 'Wali '.$student->name],
        );

        $deviceName = $credentials['device_name'] ?? 'parent-flutter-app';
        $token = $user->createToken($deviceName, ['parent'])->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'email' => $user->email,
                'roles' => $user->getRoleNames(),
            ],
            'children' => $this->childrenForPhone($credentials['phone']),
        ]);
    }

    /**
     * Kirim OTP ke nomor HP yang terdaftar/baru.
     */
    public function sendOtp(SendOtpRequest $request): JsonResponse
    {
        $phone = $request->validated('phone');

        $attempts = (int) Cache::get("otp:attempts:{$phone}", 0);
        if ($attempts >= 3) {
            throw ValidationException::withMessages([
                'phone' => 'Terlalu banyak permintaan OTP. Coba lagi nanti.',
            ]);
        }

        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        Cache::put("otp:code:{$phone}", $otp, self::OTP_TTL_SECONDS);
        Cache::increment("otp:attempts:{$phone}", 1);

        Log::info("OTP untuk {$phone}: {$otp}");

        return response()->json([
            'message' => 'OTP terkirim.',
            'expires_in' => self::OTP_TTL_SECONDS,
        ], 202);
    }

    /**
     * Verifikasi OTP dan terbitkan token Sanctum.
     */
    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $phone = $request->validated('phone');
        $otp = $request->validated('otp');

        $stored = Cache::get("otp:code:{$phone}");

        if ($stored === null) {
            throw ValidationException::withMessages([
                'otp' => 'OTP sudah kedaluwarsa.',
            ]);
        }

        if (! hash_equals((string) $stored, $otp)) {
            throw ValidationException::withMessages([
                'otp' => 'OTP tidak valid.',
            ]);
        }

        Cache::forget("otp:code:{$phone}");
        Cache::forget("otp:attempts:{$phone}");

        $user = User::updateOrCreate(
            ['phone' => $phone],
            ['name' => $phone],
        );

        $token = $user->createToken('parent-app', ['parent'])->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'roles' => $user->getRoleNames(),
            ],
            'children' => $this->childrenForPhone($phone),
        ]);
    }

    /**
     * @return Collection<int, array{id: int, name: string, nis: string, status: string, class: string|null, balance: float, card_uid: string|null}>
     */
    private function childrenForPhone(string $phone)
    {
        return Student::with('klass')
            ->where('phone_parent', $phone)
            ->get()
            ->map(fn (Student $student) => [
                'id' => $student->id,
                'name' => $student->name,
                'nis' => $student->nis,
                'status' => $student->status,
                'class' => $student->klass?->name,
                'balance' => (float) $student->balance,
                'card_uid' => $student->card_uid,
            ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user instanceof Student) {
            $user->loadMissing('klass');

            return response()->json([
                'user' => $this->studentPayload($user),
                'student' => $this->studentPayload($user),
            ]);
        }

        $user->loadMissing('merchant');

        return response()->json([
            'user' => $this->userPayload($user),
        ]);
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
            'merchant_name' => $user->merchant?->name,
            'roles' => $user->getRoleNames(),
        ];
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
            'address' => $student->address,
            'phone_parent' => $student->phone_parent,
            'parent_name' => $student->parent_name,
            'parent_email' => $student->parent_email,
            'balance_updated_at' => $student->balance_updated_at,
        ];
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out.']);
    }
}
