<?php

namespace App\Services;

use App\Enums\ShiftStatus;
use App\Enums\TransactionType;
use App\Exceptions\Domain\ShiftNotOpenException;
use App\Models\CashierShift;
use App\Models\Outlet;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class CashierShiftService
{
    /**
     * Buka shift di sebuah outlet. Hanya satu shift open per outlet.
     */
    public function open(Outlet $outlet, User $openedBy, float $openingCash = 0): CashierShift
    {
        return DB::transaction(function () use ($outlet, $openedBy, $openingCash) {
            if ($this->current($outlet) !== null) {
                throw new ShiftNotOpenException('Outlet sudah memiliki shift yang sedang terbuka.');
            }

            return CashierShift::create([
                'outlet_id' => $outlet->id,
                'opened_by' => $openedBy->id,
                'opened_at' => now(),
                'opening_cash' => $openingCash,
                'status' => ShiftStatus::Open->value,
            ]);
        });
    }

    /**
     * Shift yang sedang open di outlet (jika ada).
     */
    public function current(Outlet $outlet): ?CashierShift
    {
        return CashierShift::where('outlet_id', $outlet->id)
            ->where('status', ShiftStatus::Open->value)
            ->latest('opened_at')
            ->first();
    }

    /**
     * Tutup shift; menghitung expected_cash dari ringkasan transaksi shift.
     */
    public function close(CashierShift $shift, User $closedBy, ?float $closingCash = null): CashierShift
    {
        if ($shift->status !== ShiftStatus::Open->value) {
            throw new ShiftNotOpenException('Shift sudah ditutup.');
        }

        return DB::transaction(function () use ($shift, $closedBy, $closingCash) {
            $payments = (float) Transaction::where('cashier_shift_id', $shift->id)
                ->where('type', TransactionType::Payment->value)
                ->where('status', 'posted')
                ->sum('amount');

            $shift->expected_cash = (float) $shift->opening_cash + $payments;
            $shift->closing_cash = $closingCash;
            $shift->closed_by = $closedBy->id;
            $shift->closed_at = now();
            $shift->status = ShiftStatus::Closed->value;
            $shift->save();

            return $shift;
        });
    }
}
