<?php

namespace App\Filament\Resources\VirtualAccounts\Tables;

use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

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
