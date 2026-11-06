<?php

namespace App\Filament\Resources\Students\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class StudentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('nis')
                    ->required()
                    ->unique(ignoreRecord: true),
                TextInput::make('username')
                    ->maxLength(60)
                    ->unique(ignoreRecord: true)
                    ->helperText('Otomatis memakai NIS bila dikosongkan.'),
                TextInput::make('name')
                    ->required(),
                TextInput::make('email')
                    ->email()
                    ->unique(ignoreRecord: true),
                Select::make('class_id')
                    ->relationship('klass', 'name')
                    ->searchable()
                    ->preload(),
                TextInput::make('phone_parent')
                    ->tel(),
                TextInput::make('nik')
                    ->maxLength(32),
                Select::make('gender')
                    ->options([
                        'male' => 'Laki-laki',
                        'female' => 'Perempuan',
                    ]),
                DatePicker::make('birth_date'),
                Textarea::make('address')
                    ->columnSpanFull(),
                TextInput::make('parent_name'),
                TextInput::make('parent_email')
                    ->email(),
                Select::make('status')
                    ->required()
                    ->options([
                        'active' => 'Active',
                        'inactive' => 'Inactive',
                    ])
                    ->default('active'),
                TextInput::make('card_uid')
                    ->unique(ignoreRecord: true),
                Select::make('card_status')
                    ->options([
                        'active' => 'Active',
                        'blocked' => 'Blocked',
                        'lost' => 'Lost',
                    ])
                    ->default('active'),
                DateTimePicker::make('card_assigned_at'),
                TextInput::make('balance')
                    ->numeric()
                    ->default(0),
                Select::make('wallet_status')
                    ->required()
                    ->options([
                        'active' => 'Active',
                        'frozen' => 'Frozen',
                        'closed' => 'Closed',
                    ])
                    ->default('active'),
                TextInput::make('daily_limit')
                    ->numeric()
                    ->default(0),
                DateTimePicker::make('balance_updated_at'),
                TextInput::make('avatar_path')
                    ->label('Path Foto Profil')
                    ->maxLength(255),
            ]);
    }
}
