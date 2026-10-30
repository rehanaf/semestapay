<?php

namespace App\Http\Controllers\Api\v1;

use App\Enums\CardStatus;
use App\Enums\StudentStatus;
use App\Enums\WalletStatus;
use App\Exceptions\Domain\CardNotUsableException;
use App\Exceptions\Domain\StudentNotActiveException;
use App\Http\Controllers\Controller;
use App\Models\DailyUsage;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CardController extends Controller
{
    /**
     * Baca kartu + saldo dompet. Dipakai terminal POS saat kartu ditempel.
     */
    public function read(Request $request, string $uid): JsonResponse
    {
        $student = Student::with('klass')->where('card_uid', $uid)->first();

        if ($student === null) {
            return response()->json([
                'message' => 'Kartu tidak dikenal.',
                'code' => 'CARD_NOT_FOUND',
            ], 404);
        }

        if ($student->card_status !== CardStatus::Active->value) {
            throw new CardNotUsableException('Kartu tidak aktif.');
        }

        if ($student->status !== StudentStatus::Active->value) {
            throw new StudentNotActiveException('Santri tidak aktif.');
        }

        $dailyUsed = (float) (DailyUsage::where('student_id', $student->id)
            ->where('usage_date', today())
            ->value('total_used') ?? 0);

        return response()->json([
            'card' => [
                'uid' => $student->card_uid,
                'status' => $student->card_status,
            ],
            'student' => [
                'id' => $student->id,
                'name' => $student->name,
                'nis' => $student->nis,
                'status' => $student->status,
                'class' => $student->klass?->name,
            ],
            'wallet' => [
                'balance' => (float) $student->balance,
                'status' => $student->wallet_status ?? WalletStatus::Closed->value,
            ],
            'daily_used' => $dailyUsed,
            'daily_limit' => (float) $student->daily_limit,
        ]);
    }
}
