<?php

namespace App\Filament\Resources\Transactions\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class TransactionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')
                    ->label('ID')
                    ->searchable(),
                TextColumn::make('idempotency_key')
                    ->searchable(),
                TextColumn::make('type')
                    ->searchable(),
                TextColumn::make('student.nis')
                    ->label('NIS')
                    ->searchable(),
                TextColumn::make('outlet.name')
                    ->searchable(),
                TextColumn::make('cashier_shift_id')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('merchant.name')
                    ->searchable(),
                TextColumn::make('amount')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('balance_after')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('reference_type')
                    ->searchable(),
                TextColumn::make('reference_id')
                    ->searchable(),
                TextColumn::make('actor_user_id')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('status')
                    ->searchable(),
                TextColumn::make('reversed_by')
                    ->searchable(),
                TextColumn::make('note')
                    ->searchable(),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
