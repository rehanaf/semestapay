<?php

namespace App\Enums;

enum TransactionType: string
{
    case Topup = 'topup';
    case Payment = 'payment';
    case BillPayment = 'bill_payment';
    case CashOut = 'cash_out';
    case TransferOut = 'transfer_out';
    case TransferIn = 'transfer_in';
    case Reversal = 'reversal';
    case Adjustment = 'adjustment';

    /** Apakah transaksi menambah saldo wallet. */
    public function isCredit(): bool
    {
        return in_array($this, [
            self::Topup,
            self::TransferIn,
            self::Reversal,
            self::Adjustment,
            self::CashOut,
        ], true);
    }
}
