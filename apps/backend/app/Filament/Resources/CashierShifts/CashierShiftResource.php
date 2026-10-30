<?php

namespace App\Filament\Resources\CashierShifts;

use App\Filament\Resources\CashierShifts\Pages\CreateCashierShift;
use App\Filament\Resources\CashierShifts\Pages\EditCashierShift;
use App\Filament\Resources\CashierShifts\Pages\ListCashierShifts;
use App\Filament\Resources\CashierShifts\Schemas\CashierShiftForm;
use App\Filament\Resources\CashierShifts\Tables\CashierShiftsTable;
use App\Models\CashierShift;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class CashierShiftResource extends Resource
{
    protected static ?string $model = CashierShift::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    public static function form(Schema $schema): Schema
    {
        return CashierShiftForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return CashierShiftsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListCashierShifts::route('/'),
            'create' => CreateCashierShift::route('/create'),
            'edit' => EditCashierShift::route('/{record}/edit'),
        ];
    }
}
