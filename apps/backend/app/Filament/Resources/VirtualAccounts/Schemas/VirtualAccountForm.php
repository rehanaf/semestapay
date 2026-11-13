<?php

namespace App\Filament\Resources\VirtualAccounts\Schemas;

use App\Services\Payment\DuitkuService;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class VirtualAccountForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('student_id')
                    ->label('Santri')
                    ->relationship('student', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),

                Select::make('payment_code')
                    ->label('Bank / Metode Pembayaran')
                    ->options([
                        'BC' => 'BCA Virtual Account',
                        'M2' => 'Mandiri Virtual Account',
                        'I1' => 'BNI Virtual Account',
                        'BR' => 'BRIVA (BRI)',
                        'BT' => 'Permata Bank VA',
                    ])
                    ->default('BC')
                    ->required(),

                TextInput::make('amount')
                    ->label('Nominal (Rp)')
                    ->numeric()
                    ->minValue(10000)
                    ->maxValue(10000000)
                    ->required()
                    ->prefix('Rp'),

                TextInput::make('provider')
                    ->label('Provider')
                    ->default(DuitkuService::PROVIDER)
                    ->disabled()
                    ->dehydrated(),

                TextInput::make('bank_name')
                    ->label('Nama Bank')
                    ->disabled()
                    ->dehydrated(),

                TextInput::make('account_number')
                    ->label('Nomor VA')
                    ->disabled()
                    ->copyable()
                    ->dehydrated(),

                TextInput::make('merchant_order_id')
                    ->label('Order ID')
                    ->disabled()
                    ->copyable()
                    ->dehydrated(),

                Select::make('status')
                    ->label('Status')
                    ->options([
                        'pending' => 'Menunggu',
                        'paid'    => 'Lunas',
                        'failed'  => 'Gagal',
                        'expired' => 'Kedaluarsa',
                    ])
                    ->disabled()
                    ->dehydrated(),

                DateTimePicker::make('expires_at')
                    ->label('Berlaku Hingga')
                    ->disabled()
                    ->dehydrated(),

                DateTimePicker::make('paid_at')
                    ->label('Tanggal Bayar')
                    ->disabled()
                    ->dehydrated(),
            ]);
    }
}
