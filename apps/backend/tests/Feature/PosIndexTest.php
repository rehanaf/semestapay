<?php

namespace Tests\Feature;

use App\Enums\ShiftStatus;
use App\Enums\TransactionStatus;
use App\Enums\TransactionType;
use App\Livewire\PosIndex;
use App\Models\Cashier;
use App\Models\Item;
use App\Models\Merchant;
use App\Models\Outlet;
use App\Models\Student;
use App\Models\User;
use App\Services\CashierShiftService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class PosIndexTest extends TestCase
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

        $this->merchant = Merchant::factory()->create(['name' => 'Kantin Uji']);
        $this->outlet = Outlet::factory()->create([
            'merchant_id' => $this->merchant->id,
            'name' => 'Kantin Utama',
        ]);
        $this->kasir = User::factory()->create(['email' => 'kasir@example.com']);

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
        Item::factory()->create([
            'merchant_id' => $this->merchant->id,
            'name' => 'Rahasia',
            'price' => 5000,
            'status' => 'inactive',
        ]);
    }

    public function test_guest_is_redirected_to_pos_login(): void
    {
        $this->get('/pos')
            ->assertRedirect(route('pos.login'));
    }

    public function test_component_renders_outlet_name_and_menu_items(): void
    {
        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->assertSet('outletId', $this->outlet->id)
            ->assertSet('merchantId', $this->merchant->id)
            ->assertSet('shiftOpen', true)
            ->assertSee('Kantin Uji')
            ->assertSee('Nasi Goreng')
            ->assertSee('Es Teh')
            ->assertDontSee('Rahasia');
    }

    public function test_scanning_known_card_sets_student_with_pin_prompt(): void
    {
        $student = $this->makeStudent(['pin_hash' => bcrypt('123456')]);

        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->set('cardUid', $student->card_uid)
            ->call('scanCard')
            ->assertSet('studentId', $student->id)
            ->assertSet('cardUid', '')
            ->assertSet('error', null)
            ->assertSee($student->name);
    }

    public function test_scanning_unknown_card_shows_error(): void
    {
        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->set('cardUid', 'UID-TIDAK-ADA')
            ->call('scanCard')
            ->assertSet('studentId', null)
            ->assertSet('error', 'Kartu tidak dikenal.');
    }

    public function test_scanning_without_card_does_not_reset_current_student(): void
    {
        $student = $this->makeStudent();

        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->set('cardUid', $student->card_uid)
            ->call('scanCard')
            ->call('scanCard')
            ->assertSet('studentId', $student->id);
    }

    public function test_pay_with_pin_deducts_balance_creates_transaction_and_attaches_items(): void
    {
        $student = $this->makeStudent([
            'balance' => 50000,
            'daily_limit' => 50000,
            'pin_hash' => bcrypt('123456'),
        ]);

        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->set('cardUid', $student->card_uid)
            ->call('scanCard')
            ->set('pin', '123456')
            ->call('addItem', $this->nasiGoreng->id)
            ->call('addItem', $this->esTeh->id)
            ->call('pay')
            ->assertSet('error', null)
            ->assertSet('lastBalanceAfter', 37000)
            ->assertHasNoErrors();

        $txId = $this->assertTransactionCreated($student);

        $this->assertDatabaseHas('item_transaction', [
            'transaction_id' => $txId,
            'item_id' => $this->nasiGoreng->id,
            'quantity' => 1,
            'price' => 10000,
        ]);
        $this->assertDatabaseHas('item_transaction', [
            'transaction_id' => $txId,
            'item_id' => $this->esTeh->id,
            'quantity' => 1,
            'price' => 3000,
        ]);
    }

    public function test_pay_with_wrong_pin_is_rejected_and_balance_unchanged(): void
    {
        $student = $this->makeStudent([
            'balance' => 50000,
            'pin_hash' => bcrypt('123456'),
        ]);

        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->set('cardUid', $student->card_uid)
            ->call('scanCard')
            ->set('pin', '000000')
            ->call('addItem', $this->nasiGoreng->id)
            ->call('pay')
            ->assertSet('error', 'PIN salah.')
            ->assertSet('lastTransactionId', null);

        $this->assertSame(50000, (int) $student->fresh()->balance);
    }

    public function test_pay_manually_without_pin_still_succeeds(): void
    {
        $student = $this->makeStudent(['balance' => 20000]);

        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->set('cardUid', $student->card_uid)
            ->call('scanCard')
            ->set('manualAmount', 5000)
            ->call('pay')
            ->assertSet('error', null)
            ->assertSet('lastBalanceAfter', 15000);

        $this->assertTransactionCreated($student, amount: 5000, balanceAfter: 15000);
        $this->assertSame(15000, (int) $student->fresh()->balance);
    }

    public function test_pay_rejects_zero_total(): void
    {
        $student = $this->makeStudent(['balance' => 20000]);

        Livewire::actingAs($this->kasir)
            ->test(PosIndex::class)
            ->set('cardUid', $student->card_uid)
            ->call('scanCard')
            ->call('pay')
            ->assertSet('error', 'Nominal harus lebih dari 0.')
            ->assertSet('lastTransactionId', null);
    }

    public function test_pay_requires_open_shift(): void
    {
        $noShiftKasir = User::factory()->create();
        $outlet = Outlet::factory()->create(['merchant_id' => $this->merchant->id]);

        Cashier::create([
            'user_id' => $noShiftKasir->id,
            'outlet_id' => $outlet->id,
            'status' => 'active',
        ]);

        $student = $this->makeStudent(['balance' => 20000]);

        Livewire::actingAs($noShiftKasir)
            ->test(PosIndex::class)
            ->set('cardUid', $student->card_uid)
            ->call('scanCard')
            ->call('addItem', $this->nasiGoreng->id)
            ->call('pay')
            ->assertSet('error', 'Shift belum dibuka.')
            ->assertSet('lastTransactionId', null);
    }

    private function makeStudent(array $overrides = []): Student
    {
        $student = Student::factory()->create(array_merge([
            'card_uid' => 'UID-'.fake()->unique()->numerify('########'),
            'balance' => 20000,
            'daily_limit' => 100000,
        ], $overrides));

        return $student;
    }

    private function assertTransactionCreated(Student $student, int $amount = 13000, int $balanceAfter = 37000): string
    {
        $this->assertDatabaseHas('transactions', [
            'student_id' => $student->id,
            'type' => TransactionType::Payment->value,
            'status' => TransactionStatus::Posted->value,
            'outlet_id' => $this->outlet->id,
            'merchant_id' => $this->merchant->id,
        ]);

        $tx = $student->transactions()
            ->where('type', TransactionType::Payment->value)
            ->where('status', TransactionStatus::Posted->value)
            ->latest('id')
            ->firstOrFail();

        $this->assertSame($amount, (int) $tx->amount);
        $this->assertSame($balanceAfter, (int) $tx->balance_after);
        $this->assertNotNull($tx->cashier_shift_id);
        $this->assertSame(ShiftStatus::Open->value, $tx->shift?->status);

        return $tx->id;
    }
}
