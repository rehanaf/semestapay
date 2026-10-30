<?php

namespace App\Filament\Resources\Transactions\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class TransactionForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('idempotency_key')
                    ->required(),
                TextInput::make('type')
                    ->required(),
                Select::make('student_id')
                    ->relationship('student', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                Select::make('outlet_id')
                    ->relationship('outlet', 'name'),
                TextInput::make('cashier_shift_id')
                    ->numeric(),
                Select::make('merchant_id')
                    ->relationship('merchant', 'name'),
                TextInput::make('amount')
                    ->required()
                    ->numeric(),
                TextInput::make('balance_after')
                    ->numeric(),
                TextInput::make('reference_type'),
                TextInput::make('reference_id'),
                TextInput::make('actor_user_id')
                    ->numeric(),
                TextInput::make('status')
                    ->required()
                    ->default('posted'),
                TextInput::make('reversed_by'),
                TextInput::make('note'),
            ]);
    }
}
