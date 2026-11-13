<?php

namespace App\Filament\Resources\PaymentGatewayConfigs\Pages;

use App\Filament\Resources\PaymentGatewayConfigs\PaymentGatewayConfigResource;
use Filament\Resources\Pages\EditRecord;

class EditPaymentGatewayConfig extends EditRecord
{
    protected static string $resource = PaymentGatewayConfigResource::class;
}
