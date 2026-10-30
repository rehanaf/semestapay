<?php

namespace Tests\Feature;

use App\Enums\TransactionType;
use App\Models\Cashier;
use App\Models\Item;
use App\Models\Merchant;
use App\Models\Outlet;
use App\Models\Student;
use App\Models\User;
use App\Services\CashierShiftService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class PaymentsTapTest extends TestCase
{
    use RefreshDatabase;

    private Merchant $merchant;

    private Outlet $outlet;

    private User $kasir;

    private Item $nasiGoreng;

    private Item $esTeh;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('cashier', 'web');

        $this->merchant = Merchant::factory()->create(['name' => 'Kantin Uji']);
        $this->outlet = Outlet::factory()->create([
            'merchant_id' => $this->merchant->id,
            'code' => 'KANTIN-1',
        ]);

        $this->kasir = User::factory()->create();
        $this->kasir->syncRoles(['cashier']);

        Cashier::create([
            'user_id' => $this->kasir->id,
            'outlet_id' => $this->outlet->id,
            'status' => 'active',
        ]);

        app(CashierShiftService::class)->open($this->outlet, $this->kasir);

        $this->nasiGoreng = Item::factory()->create([
            'merchant_id' => $this->merchant->id,
            'name' => 'Nasi Goreng',
            'price' => 10000,
        ]);
        $this->esTeh = Item::factory()->create([
            'merchant_id' => $this->merchant->id,
            'name' => 'Es Teh',
            'price' => 3000,
        ]);
    }

    public function test_tap_with_items_and_correct_pin_succeeds_with_auto_note(): void
    {
        $student = Student::factory()->create([
            'card_uid' => 'UID-0001',
            'balance' => 50000,
            'daily_limit' => 100000,
            'pin_hash' => bcrypt('123456'),
        ]);

        $response = $this->actingAs($this->kasir, 'sanctum')
            ->postJson('/api/v1/payments/tap', [
                'card_uid' => 'UID-0001',
                'outlet_code' => 'KANTIN-1',
                'amount' => 13000,
                'pin' => '123456',
                'idempotency_key' => 'dc07e88b-8c9f-4b7a-9e45-1a2b3c4d5e6f',
                'items' => [
                    ['item_id' => $this->nasiGoreng->id, 'quantity' => 1],
                    ['item_id' => $this->esTeh->id, 'quantity' => 1],
                ],
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('amount', 13000)
            ->assertJsonPath('balance_after', 37000)
            ->assertJsonCount(2, 'items');

        $this->assertSame(37000, (int) $student->fresh()->balance);

        $tx = $student->transactions()->firstOrFail();
        $this->assertSame(TransactionType::Payment->value, $tx->type);
        $this->assertSame('Nasi Goreng, Es Teh', $tx->note);

        $this->assertDatabaseHas('item_transaction', [
            'transaction_id' => $tx->id,
            'item_id' => $this->nasiGoreng->id,
            'quantity' => 1,
            'price' => 10000,
        ]);
        $this->assertDatabaseHas('item_transaction', [
            'transaction_id' => $tx->id,
            'item_id' => $this->esTeh->id,
            'quantity' => 1,
            'price' => 3000,
        ]);
    }

    public function test_tap_requires_pin_when_student_has_one(): void
    {
        Student::factory()->create([
            'card_uid' => 'UID-0001',
            'balance' => 50000,
            'pin_hash' => bcrypt('123456'),
        ]);

        $this->actingAs($this->kasir, 'sanctum')
            ->postJson('/api/v1/payments/tap', [
                'card_uid' => 'UID-0001',
                'outlet_code' => 'KANTIN-1',
                'amount' => 10000,
                'idempotency_key' => 'dc07e88b-1111-4b7a-9e45-1a2b3c4d5e6f',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('pin');
    }

    public function test_tap_rejects_wrong_pin(): void
    {
        Student::factory()->create([
            'card_uid' => 'UID-0001',
            'balance' => 50000,
            'pin_hash' => bcrypt('123456'),
        ]);

        $this->actingAs($this->kasir, 'sanctum')
            ->postJson('/api/v1/payments/tap', [
                'card_uid' => 'UID-0001',
                'outlet_code' => 'KANTIN-1',
                'amount' => 10000,
                'pin' => '000000',
                'idempotency_key' => 'dc07e88b-2222-4b7a-9e45-1a2b3c4d5e6f',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('pin');
    }

    public function test_tap_rejects_amount_not_matching_items(): void
    {
        Student::factory()->create([
            'card_uid' => 'UID-0001',
            'balance' => 50000,
        ]);

        $this->actingAs($this->kasir, 'sanctum')
            ->postJson('/api/v1/payments/tap', [
                'card_uid' => 'UID-0001',
                'outlet_code' => 'KANTIN-1',
                'amount' => 5000,
                'idempotency_key' => 'dc07e88b-3333-4b7a-9e45-1a2b3c4d5e6f',
                'items' => [
                    ['item_id' => $this->nasiGoreng->id, 'quantity' => 1],
                ],
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('amount');
    }

    public function test_tap_without_pin_and_without_items_uses_amount_as_is(): void
    {
        Student::factory()->create([
            'card_uid' => 'UID-0001',
            'balance' => 50000,
        ]);

        $this->actingAs($this->kasir, 'sanctum')
            ->postJson('/api/v1/payments/tap', [
                'card_uid' => 'UID-0001',
                'outlet_code' => 'KANTIN-1',
                'amount' => 5000,
                'idempotency_key' => 'dc07e88b-4444-4b7a-9e45-1a2b3c4d5e6f',
            ])
            ->assertStatus(201)
            ->assertJsonCount(0, 'items')
            ->assertJsonPath('balance_after', 45000);
    }
}
