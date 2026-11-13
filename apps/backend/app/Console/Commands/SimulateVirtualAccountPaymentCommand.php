<?php

namespace App\Console\Commands;

use App\Models\VirtualAccount;
use App\Services\Payment\DuitkuService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

#[Signature('va:pay {identifier? : Nomor VA, NIS Santri, atau Nama Santri} {amount? : Nominal pembayaran (contoh: 50000)}')]
#[Description('Simulasikan pembayaran Virtual Account Duitku pada mode Sandbox')]
class SimulateVirtualAccountPaymentCommand extends Command
{
    /**
     * Execute the console command.
     */
    public function handle(DuitkuService $duitku, Kernel $httpKernel): int
    {
        $identifier = $this->argument('identifier');
        $amount = $this->argument('amount');

        $query = VirtualAccount::with('student');

        if (! empty($identifier)) {
            $va = (clone $query)->where('account_number', $identifier)
                ->orWhere('merchant_order_id', $identifier)
                ->orWhereHas('student', function ($q) use ($identifier) {
                    $q->where('nis', $identifier)
                        ->orWhere('name', 'like', "%{$identifier}%");
                })
                ->latest()
                ->first();

            if (! $va) {
                $this->error("Virtual Account atau Santri dengan pengenal '{$identifier}' tidak ditemukan.");

                return self::FAILURE;
            }
        } else {
            $vas = (clone $query)->latest()->take(15)->get();

            if ($vas->isEmpty()) {
                $this->warn('Belum ada Virtual Account yang dibuat.');

                return self::FAILURE;
            }

            $choices = $vas->mapWithKeys(function (VirtualAccount $v) {
                $studentName = $v->student?->name ?? 'Tanpa Nama';
                $nis = $v->student?->nis ?? '-';
                $label = "{$studentName} ({$nis}) | {$v->bank_name} - {$v->account_number} [{$v->status}]";

                return [$v->id => $label];
            })->all();

            $selectedId = $this->choice('Pilih Virtual Account yang ingin dibayar:', $choices);
            $va = $vas->firstWhere('id', array_search($selectedId, $choices, true));
        }

        if (! $va) {
            $this->error('Virtual account tidak valid.');

            return self::FAILURE;
        }

        if (empty($amount)) {
            $defaultAmount = (int) ($va->amount > 0 ? $va->amount : 50000);
            $amountInput = $this->ask('Masukkan nominal pembayaran (Rp):', (string) $defaultAmount);
            $amount = (float) $amountInput;
        } else {
            $amount = (float) $amount;
        }

        if ($amount <= 0) {
            $this->error('Nominal pembayaran harus lebih dari 0.');

            return self::FAILURE;
        }

        $merchantCode = $duitku->merchantCode();
        $apiKey = $duitku->apiKey();
        $merchantOrderId = $va->merchant_order_id;
        $amountFormatted = (string) (int) $amount;

        $signature = hash_hmac('sha256', $merchantCode.$amountFormatted.$merchantOrderId, $apiKey);
        $reference = 'SIMULASI-'.Str::upper(Str::random(10));

        $payload = [
            'merchantCode' => $merchantCode,
            'amount' => $amountFormatted,
            'merchantOrderId' => $merchantOrderId,
            'resultCode' => '00',
            'reference' => $reference,
            'vaNumber' => $va->account_number,
            'signature' => $signature,
        ];

        $this->info("Mengirim simulasi webhook callback Duitku untuk {$va->student?->name}...");

        $request = Request::create(
            '/api/v1/payments/duitku/callback',
            'POST',
            $payload
        );

        $response = $httpKernel->handle($request);

        if ($response->getStatusCode() !== 200) {
            $this->error('Gagal memproses simulasi: '.$response->getContent());

            return self::FAILURE;
        }

        $va->refresh();
        $student = $va->student?->fresh();

        $this->newLine();
        $this->info('=====================================================');
        $this->info('  SIMULASI PEMBAYARAN VA DUITKU BERHASIL DITERIMA!   ');
        $this->info('=====================================================');
        $this->line(" Santri        : <comment>{$student?->name} ({$student?->nis})</comment>");
        $this->line(" Bank & VA     : <comment>{$va->bank_name} - {$va->account_number}</comment>");
        $this->line(' Nominal Bayar : <info>Rp '.number_format($amount, 0, ',', '.').'</info>');
        $this->line(" Referensi     : <comment>{$reference}</comment>");
        $this->line(" Status VA     : <comment>{$va->status}</comment>");
        $this->line(' Saldo Santri  : <info>Rp '.number_format($student?->balance ?? 0, 0, ',', '.').'</info>');
        $this->info('=====================================================');
        $this->newLine();

        return self::SUCCESS;
    }
}
