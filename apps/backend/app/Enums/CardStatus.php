<?php

namespace App\Enums;

enum CardStatus: string
{
    case Active = 'active';
    case Blocked = 'blocked';
    case Lost = 'lost';
    case Replaced = 'replaced';

    public function isUsable(): bool
    {
        return $this === self::Active;
    }
}
