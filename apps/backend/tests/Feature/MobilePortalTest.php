<?php

namespace Tests\Feature;

use App\Models\Cashier;
use App\Models\Merchant;
use App\Models\Outlet;
use App\Models\Student;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class MobilePortalTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_login_and_read_dashboard(): void
    {
        $student = Student::factory()->create([
            'nis' => '2026-001',
            'pin_hash' => Hash::make('123456'),
            'balance' => 75000,
            'daily_limit' => 50000,
        ]);

        $login = $this->postJson('/api/v1/auth/student-login', [
            'nis' => '2026-001',
            'pin' => '123456',
            'device_name' => 'test-student',
        ]);

        $login->assertOk()
            ->assertJsonStructure([
                'token',
                'student' => ['id', 'name', 'nis', 'balance', 'daily_limit'],
            ]);

        $this->withToken($login->json('token'))
            ->getJson('/api/v1/student/dashboard')
            ->assertOk()
            ->assertJsonPath('student.id', $student->id)
            ->assertJsonPath('student.balance', 75000);
    }

    public function test_student_login_rejects_wrong_pin(): void
    {
        Student::factory()->create([
            'nis' => '2026-002',
            'pin_hash' => Hash::make('123456'),
        ]);

        $this->postJson('/api/v1/auth/student-login', [
            'nis' => '2026-002',
            'pin' => '000000',
        ])->assertStatus(422)->assertJsonValidationErrors(['pin']);
    }

    public function test_parent_can_login_with_registered_phone_and_child_nis(): void
    {
        $student = Student::factory()->create([
            'nis' => '2026-003',
            'phone_parent' => '081312000010',
            'balance' => 25000,
        ]);

        $response = $this->postJson('/api/v1/auth/parent-login', [
            'phone' => '081312000010',
            'nis' => '2026-003',
            'device_name' => 'test-parent',
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'token',
                'user' => ['id', 'name', 'phone'],
                'children' => [['id', 'name', 'nis', 'balance']],
            ])
            ->assertJsonPath('children.0.id', $student->id);
    }

    public function test_merchant_summary_returns_balance_for_current_cashier(): void
    {
        $user = User::factory()->create(['status' => 'active']);
        $merchant = Merchant::factory()->create();
        $outlet = Outlet::factory()->create(['merchant_id' => $merchant->id]);
        Cashier::create([
            'user_id' => $user->id,
            'outlet_id' => $outlet->id,
            'status' => 'active',
        ]);
        $student = Student::factory()->create();

        Transaction::create([
            'idempotency_key' => (string) Str::uuid(),
            'type' => 'payment',
            'student_id' => $student->id,
            'merchant_id' => $merchant->id,
            'outlet_id' => $outlet->id,
            'amount' => 15000,
            'status' => 'posted',
        ]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/merchant/summary')
            ->assertOk()
            ->assertJsonPath('merchant.id', $merchant->id)
            ->assertJsonPath('merchant.code', 'MRC-'.str_pad((string) $merchant->id, 4, '0', STR_PAD_LEFT))
            ->assertJsonPath('merchant.balance', 15000);
    }
}
