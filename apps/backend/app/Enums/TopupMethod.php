<?php

namespace App\Enums;

enum TopupMethod: string
{
    case Cash = 'cash';
    case Transfer = 'transfer';
    case Va = 'va';
    case Adjustment = 'adjustment';
}
