<?php

namespace App\Filament\Resources\CashierShifts\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class CashierShiftForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('outlet_id')
                    ->relationship('outlet', 'name')
                    ->required(),
                TextInput::make('opened_by')
                    ->required()
                    ->numeric(),
                TextInput::make('closed_by')
                    ->numeric(),
                DateTimePicker::make('opened_at')
                    ->required(),
                DateTimePicker::make('closed_at'),
                TextInput::make('opening_cash')
                    ->required()
                    ->numeric()
                    ->default(0.0),
                TextInput::make('closing_cash')
                    ->numeric(),
                TextInput::make('expected_cash')
                    ->numeric(),
                TextInput::make('status')
                    ->required()
                    ->default('open'),
            ]);
    }
}
