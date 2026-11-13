<?php

namespace App\Filament\Resources\VirtualAccounts\Pages;

use App\Filament\Resources\VirtualAccounts\VirtualAccountResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditVirtualAccount extends EditRecord
{
    protected static string $resource = VirtualAccountResource::class;

    protected static ?string $title = 'Detail Virtual Account';

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
