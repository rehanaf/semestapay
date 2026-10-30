<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\v1\SendOtpRequest;
use App\Http\Requests\Api\v1\VerifyOtpRequest;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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

        $user = User::where('email', $credentials['email'])
            ->orWhere('phone', $credentials['email'])
            ->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
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
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'roles' => $user->getRoleNames(),
            ],
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
            'children' => Student::where('phone_parent', $phone)
                ->get(['id', 'name', 'nis', 'status']),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'email' => $user->email,
                'roles' => $user->getRoleNames(),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out.']);
    }
}
