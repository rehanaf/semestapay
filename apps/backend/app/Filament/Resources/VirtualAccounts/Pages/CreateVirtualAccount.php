<?php

namespace App\Filament\Resources\VirtualAccounts\Pages;

use App\Exceptions\Payment\DuitkuException;
use App\Filament\Resources\VirtualAccounts\VirtualAccountResource;
use App\Models\Student;
use App\Services\Payment\DuitkuService;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;

class CreateVirtualAccount extends CreateRecord
{
    protected static string $resource = VirtualAccountResource::class;

    protected static ?string $title = 'Buat Virtual Account';

    /**
     * Intercept create: panggil DuitkuService, bukan simpan form langsung.
     */
    protected function handleRecordCreation(array $data): Model
    {
        $student = Student::findOrFail($data['student_id']);

        try {
            /** @var DuitkuService $duitku */
            $duitku = app(DuitkuService::class);

            return $duitku->createVirtualAccount(
                student: $student,
                amount: (float) $data['amount'],
                paymentMethod: $data['payment_code'] ?? null,
            );
        } catch (DuitkuException $e) {
            Notification::make()
                ->title('Gagal membuat VA Duitku')
                ->body($e->getMessage())
                ->danger()
                ->send();

            $this->halt();
        }
    }
}
