<?php

namespace App\Filament\Resources\Students\RelationManagers;

use App\Exceptions\Payment\DuitkuException;
use App\Services\Payment\DuitkuService;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class VirtualAccountsRelationManager extends RelationManager
{
    protected static string $relationship = 'virtualAccounts';

    protected static ?string $title = 'Virtual Account Top Up';

    public function form(Schema $schema): Schema
    {
        return $schema->components([
            Select::make('payment_code')
                ->label('Bank')
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
                ->default(50000)
                ->required()
                ->prefix('Rp'),
        ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('account_number')
            ->columns([
                TextColumn::make('bank_name')
                    ->label('Bank'),

                TextColumn::make('account_number')
                    ->label('Nomor VA')
                    ->copyable()
                    ->fontFamily('mono'),

                TextColumn::make('amount')
                    ->label('Nominal')
                    ->money('IDR'),

                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'paid' => 'success',
                        'pending' => 'warning',
                        'failed' => 'danger',
                        'expired' => 'gray',
                        default => 'gray',
                    }),

                TextColumn::make('expires_at')
                    ->label('Berlaku Hingga')
                    ->dateTime('d M Y, H:i')
                    ->since(),

                TextColumn::make('paid_at')
                    ->label('Dibayar')
                    ->dateTime('d M Y, H:i')
                    ->placeholder('-'),
            ])
            ->defaultSort('created_at', 'desc')
            ->headerActions([
                Action::make('create_va')
                    ->label('Buat VA Baru')
                    ->icon('heroicon-o-plus')
                    ->form([
                        Select::make('payment_code')
                            ->label('Bank')
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
                            ->default(50000)
                            ->required()
                            ->prefix('Rp'),
                    ])
                    ->action(function (array $data): void {
                        $student = $this->getOwnerRecord();

                        try {
                            /** @var DuitkuService $duitku */
                            $duitku = app(DuitkuService::class);

                            $va = $duitku->createVirtualAccount(
                                student: $student,
                                amount: (float) $data['amount'],
                                paymentMethod: $data['payment_code'],
                            );

                            Notification::make()
                                ->title('VA berhasil dibuat')
                                ->body("Nomor VA: {$va->account_number} ({$va->bank_name})")
                                ->success()
                                ->send();
                        } catch (DuitkuException $e) {
                            Notification::make()
                                ->title('Gagal membuat VA')
                                ->body($e->getMessage())
                                ->danger()
                                ->send();
                        }
                    }),
            ])
            ->recordActions([
                Action::make('simulate_payment')
                    ->label('Simulasi Bayar')
                    ->icon('heroicon-o-banknotes')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Simulasi Bayar VA (Sandbox)')
                    ->modalDescription(fn ($record): string => "Kirim simulasi pembayaran untuk {$record->bank_name} - {$record->account_number}.")
                    ->form([
                        TextInput::make('amount')
                            ->label('Nominal Pembayaran (Rp)')
                            ->numeric()
                            ->minValue(1000)
                            ->default(fn ($record): int => (int) ($record->amount > 0 ? $record->amount : 50000))
                            ->required()
                            ->prefix('Rp'),
                    ])
                    ->action(function ($record, array $data): void {
                        /** @var DuitkuService $duitku */
                        $duitku = app(DuitkuService::class);
                        $httpKernel = app(Kernel::class);

                        $amount = (string) (int) $data['amount'];
                        $merchantCode = $duitku->merchantCode();
                        $apiKey = $duitku->apiKey();
                        $orderId = $record->merchant_order_id;
                        $sig = hash_hmac('sha256', $merchantCode.$amount.$orderId, $apiKey);
                        $ref = 'SIMULASI-RM-'.Str::upper(Str::random(8));

                        $payload = [
                            'merchantCode' => $merchantCode,
                            'amount' => $amount,
                            'merchantOrderId' => $orderId,
                            'resultCode' => '00',
                            'reference' => $ref,
                            'vaNumber' => $record->account_number,
                            'signature' => $sig,
                        ];

                        $req = Request::create('/api/v1/payments/duitku/callback', 'POST', $payload);
                        $res = $httpKernel->handle($req);

                        if ($res->getStatusCode() === 200) {
                            $student = $record->student?->fresh();
                            Notification::make()
                                ->title('Simulasi Berhasil!')
                                ->body('Pembayaran Rp '.number_format((float) $amount, 0, ',', '.')." berhasil diproses. Saldo {$student?->name}: Rp ".number_format($student?->balance ?? 0, 0, ',', '.'))
                                ->success()
                                ->send();
                        } else {
                            Notification::make()
                                ->title('Simulasi Gagal')
                                ->body($res->getContent())
                                ->danger()
                                ->send();
                        }
                    }),
            ])
            ->toolbarActions([]);
    }
}
