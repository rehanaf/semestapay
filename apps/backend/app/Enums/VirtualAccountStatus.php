<?php

namespace App\Enums;

enum VirtualAccountStatus: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Failed = 'failed';
    case Expired = 'expired';

    public function isPaid(): bool
    {
        return $this === self::Paid;
    }
}
