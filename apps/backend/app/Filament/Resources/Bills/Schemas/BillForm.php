<?php

namespace App\Filament\Resources\Bills\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class BillForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('student_id')
                    ->relationship('student', 'name')
                    ->required(),
                TextInput::make('type')
                    ->required(),
                TextInput::make('period'),
                TextInput::make('description'),
                TextInput::make('amount')
                    ->required()
                    ->numeric(),
                TextInput::make('paid_amount')
                    ->required()
                    ->numeric()
                    ->default(0.0),
                DatePicker::make('due_date'),
                TextInput::make('status')
                    ->required()
                    ->default('unpaid'),
            ]);
    }
}
