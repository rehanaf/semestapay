<?php

namespace App\Enums;

enum BillStatus: string
{
    case Unpaid = 'unpaid';
    case Partial = 'partial';
    case Paid = 'paid';
    case Void = 'void';

    public function isPaid(): bool
    {
        return $this === self::Paid;
    }
}
