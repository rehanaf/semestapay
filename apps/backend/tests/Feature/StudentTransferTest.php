<?php

namespace Tests\Feature;

use App\Enums\TransactionType;
use App\Models\Student;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class StudentTransferTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_search_other_active_students_by_name_or_nis(): void
    {
        $sender = Student::factory()->create(['name' => 'Alya Pengirim']);
        $recipient = Student::factory()->create([
            'name' => 'Budi Penerima',
            'nis' => 'NIS-TRANSFER-01',
        ]);
        Student::factory()->create([
            'name' => 'Budi Nonaktif',
            'status' => 'inactive',
        ]);

        $this->actingAs($sender, 'sanctum')
            ->getJson('/api/v1/student/transfer/recipients?q=NIS-TRANSFER')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $recipient->id)
            ->assertJsonPath('data.0.name', 'Budi Penerima')
            ->assertJsonPath('data.0.nis', 'NIS-TRANSFER-01');
    }

    public function test_student_transfer_moves_both_wallets_once_and_is_idempotent(): void
    {
        $sender = Student::factory()->create(['balance' => 100000]);
        $recipient = Student::factory()->create(['balance' => 12000]);
        $idempotencyKey = (string) Str::uuid();
        $payload = [
            'recipient_id' => $recipient->id,
            'amount' => 25000,
            'note' => 'Uang buku',
            'idempotency_key' => $idempotencyKey,
        ];

        $firstResponse = $this->actingAs($sender, 'sanctum')
            ->postJson('/api/v1/student/transfers', $payload);

        $firstResponse->assertOk()
            ->assertJsonPath('transfer.amount', 25000)
            ->assertJsonPath('transfer.balance_after', 75000)
            ->assertJsonPath('transfer.recipient_id', $recipient->id);

        $this->assertSame(75000.0, (float) $sender->fresh()->balance);
        $this->assertSame(37000.0, (float) $recipient->fresh()->balance);
        $this->assertDatabaseCount('transactions', 2);
        $this->assertDatabaseCount('ledger_entries', 4);
        $this->assertDatabaseHas('transactions', [
            'student_id' => $sender->id,
            'type' => TransactionType::TransferOut->value,
            'amount' => 25000,
        ]);
        $this->assertDatabaseHas('transactions', [
            'student_id' => $recipient->id,
            'type' => TransactionType::TransferIn->value,
            'amount' => 25000,
        ]);

        $secondResponse = $this->postJson('/api/v1/student/transfers', $payload);
        $secondResponse->assertOk()
            ->assertJsonPath(
                'transfer.transaction_id',
                $firstResponse->json('transfer.transaction_id'),
            );

        $this->assertSame(75000.0, (float) $sender->fresh()->balance);
        $this->assertSame(37000.0, (float) $recipient->fresh()->balance);
        $this->assertDatabaseCount('transactions', 2);
    }

    public function test_transfer_with_insufficient_balance_does_not_change_either_wallet(): void
    {
        $sender = Student::factory()->create(['balance' => 10000]);
        $recipient = Student::factory()->create(['balance' => 5000]);

        $this->actingAs($sender, 'sanctum')
            ->postJson('/api/v1/student/transfers', [
                'recipient_id' => $recipient->id,
                'amount' => 25000,
                'idempotency_key' => (string) Str::uuid(),
            ])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Saldo tidak mencukupi.');

        $this->assertSame(10000.0, (float) $sender->fresh()->balance);
        $this->assertSame(5000.0, (float) $recipient->fresh()->balance);
        $this->assertDatabaseCount('transactions', 0);
        $this->assertDatabaseCount('ledger_entries', 0);
    }
}
