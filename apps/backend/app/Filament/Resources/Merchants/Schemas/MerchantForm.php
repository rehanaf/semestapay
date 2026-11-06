<?php

namespace App\Filament\Resources\Merchants\Schemas;

use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class MerchantForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->required(),
                TextInput::make('type'),
                TextInput::make('owner_name'),
                TextInput::make('phone')
                    ->tel(),
                TextInput::make('email')
                    ->email(),
                Textarea::make('address')
                    ->columnSpanFull(),
                Textarea::make('description')
                    ->columnSpanFull(),
                TextInput::make('status')
                    ->required()
                    ->default('active'),
                TextInput::make('balance')
                    ->numeric()
                    ->default(0),
            ]);
    }
}
