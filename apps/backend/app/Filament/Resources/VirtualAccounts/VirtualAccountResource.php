<?php

namespace App\Filament\Resources\VirtualAccounts;

use App\Filament\Resources\VirtualAccounts\Pages\CreateVirtualAccount;
use App\Filament\Resources\VirtualAccounts\Pages\EditVirtualAccount;
use App\Filament\Resources\VirtualAccounts\Pages\ListVirtualAccounts;
use App\Filament\Resources\VirtualAccounts\Schemas\VirtualAccountForm;
use App\Filament\Resources\VirtualAccounts\Tables\VirtualAccountsTable;
use App\Models\VirtualAccount;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class VirtualAccountResource extends Resource
{
    protected static ?string $model = VirtualAccount::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBanknotes;

    protected static ?string $navigationLabel = 'Virtual Account';

    protected static ?string $modelLabel = 'Virtual Account';

    protected static ?string $pluralModelLabel = 'Virtual Accounts';

    protected static ?int $navigationSort = 10;

    public static function form(Schema $schema): Schema
    {
        return VirtualAccountForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return VirtualAccountsTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index'  => ListVirtualAccounts::route('/'),
            'create' => CreateVirtualAccount::route('/create'),
            'edit'   => EditVirtualAccount::route('/{record}/edit'),
        ];
    }
}
