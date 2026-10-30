<?php

namespace App\Enums;

enum TransactionType: string
{
    case Topup = 'topup';
    case Payment = 'payment';
    case BillPayment = 'bill_payment';
    case Reversal = 'reversal';
    case Adjustment = 'adjustment';

    /** Apakah transaksi menambah saldo wallet. */
    public function isCredit(): bool
    {
        return in_array($this, [self::Topup, self::Reversal, self::Adjustment], true);
    }
}
