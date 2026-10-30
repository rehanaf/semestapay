<?php

namespace App\Filament\Resources\CashierShifts\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class CashierShiftsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('outlet.name')
                    ->searchable(),
                TextColumn::make('opened_by')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('closed_by')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('opened_at')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('closed_at')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('opening_cash')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('closing_cash')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('expected_cash')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('status')
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
