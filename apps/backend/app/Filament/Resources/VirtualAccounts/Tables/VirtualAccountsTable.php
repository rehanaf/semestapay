<?php

namespace App\Filament\Resources\VirtualAccounts\Tables;

use App\Models\VirtualAccount;
use App\Services\Payment\DuitkuService;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class VirtualAccountsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('student.name')
                    ->label('Santri')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('student.nis')
                    ->label('NIS')
                    ->searchable(),

                TextColumn::make('bank_name')
                    ->label('Bank')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('account_number')
                    ->label('Nomor VA')
                    ->searchable()
                    ->copyable()
                    ->fontFamily('mono'),

                TextColumn::make('amount')
                    ->label('Nominal')
                    ->money('IDR')
                    ->sortable(),

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
                    ->sortable()
                    ->since()
                    ->toggleable(),

                TextColumn::make('paid_at')
                    ->label('Dibayar')
                    ->dateTime('d M Y, H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('merchant_order_id')
                    ->label('Order ID')
                    ->searchable()
                    ->copyable()
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d M Y, H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                SelectFilter::make('status')
                    ->label('Status')
                    ->options([
                        'pending' => 'Menunggu',
                        'paid' => 'Lunas',
                        'failed' => 'Gagal',
                        'expired' => 'Kedaluarsa',
                    ]),

                SelectFilter::make('payment_code')
                    ->label('Bank')
                    ->options([
                        'BC' => 'BCA Virtual Account',
                        'M2' => 'Mandiri Virtual Account',
                        'I1' => 'BNI Virtual Account',
                        'BR' => 'BRIVA (BRI)',
                        'BT' => 'Permata Bank VA',
                    ]),
            ])
            ->recordActions([
                Action::make('simulate_payment')
                    ->label('Simulasi Bayar')
                    ->icon('heroicon-o-banknotes')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Simulasi Bayar VA (Sandbox)')
                    ->modalDescription(fn (VirtualAccount $record): string => "Kirim simulasi pembayaran untuk {$record->student?->name} ({$record->bank_name} - {$record->account_number}). Saldo santri akan langsung terisi.")
                    ->form([
                        TextInput::make('amount')
                            ->label('Nominal Pembayaran (Rp)')
                            ->numeric()
                            ->minValue(1000)
                            ->default(fn (VirtualAccount $record): int => (int) ($record->amount > 0 ? $record->amount : 50000))
                            ->required()
                            ->prefix('Rp'),
                    ])
                    ->action(function (VirtualAccount $record, array $data): void {
                        /** @var DuitkuService $duitku */
                        $duitku = app(DuitkuService::class);
                        $httpKernel = app(Kernel::class);

                        $amount = (string) (int) $data['amount'];
                        $merchantCode = $duitku->merchantCode();
                        $apiKey = $duitku->apiKey();
                        $orderId = $record->merchant_order_id;
                        $sig = hash_hmac('sha256', $merchantCode.$amount.$orderId, $apiKey);
                        $ref = 'SIMULASI-UI-'.Str::upper(Str::random(8));

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

                Action::make('view')
                    ->label('Detail')
                    ->icon('heroicon-o-eye')
                    ->url(fn ($record) => route('filament.admin.resources.virtual-accounts.edit', $record)),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
