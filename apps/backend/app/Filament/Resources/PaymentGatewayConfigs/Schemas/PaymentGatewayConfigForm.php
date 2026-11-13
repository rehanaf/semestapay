<?php

namespace App\Filament\Resources\PaymentGatewayConfigs\Schemas;

use App\Models\PaymentGatewayConfig;
use Filament\Forms\Components\KeyValue;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class PaymentGatewayConfigForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Gateway')
                    ->schema([
                        Select::make('provider')
                            ->options([
                                PaymentGatewayConfig::DUITKU => 'Duitku',
                            ])
                            ->required()
                            ->unique(ignoreRecord: true),
                        Toggle::make('is_active')
                            ->label('Aktif')
                            ->default(true)
                            ->required(),
                    ])
                    ->columns(2),
                Section::make('Konfigurasi')
                    ->description('Kredensial disimpan di database, bukan di .env.')
                    ->schema([
                        KeyValue::make('config')
                            ->keyLabel('Key')
                            ->valueLabel('Value')
                            ->addActionLabel('Tambah konfigurasi')
                            ->helperText('Key Duitku: api_key, merchant_code, base_url, payment_method, callback_url, return_url, expiry_period.')
                            ->required()
                            ->columnSpanFull(),
                    ]),
            ]);
    }
}
