<?php

namespace Tests\Feature;

use App\Enums\VirtualAccountStatus;
use App\Models\Student;
use App\Models\VirtualAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StudentVirtualAccountHistoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_list_only_their_dynamic_virtual_accounts(): void
    {
        $student = Student::factory()->create();
        $otherStudent = Student::factory()->create();

        $ownDynamicVa = $this->createVirtualAccount($student, '7007000000000001');
        $this->createVirtualAccount($student, '7007000000000002', isStatic: true);
        $this->createVirtualAccount($otherStudent, '7007000000000003');

        $response = $this->actingAs($student, 'sanctum')
            ->getJson('/api/v1/student/topup/vas');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $ownDynamicVa->id)
            ->assertJsonPath('data.0.account_number', '7007000000000001')
            ->assertJsonPath('data.0.is_static', false);
    }

    private function createVirtualAccount(
        Student $student,
        string $accountNumber,
        bool $isStatic = false,
    ): VirtualAccount {
        return VirtualAccount::create([
            'student_id' => $student->id,
            'provider' => 'duitku',
            'payment_code' => 'BC',
            'bank_name' => 'BCA Virtual Account',
            'account_number' => $accountNumber,
            'merchant_order_id' => 'ORDER-'.$accountNumber,
            'provider_reference' => 'REF-'.$accountNumber,
            'amount' => 25000,
            'status' => VirtualAccountStatus::Pending->value,
            'is_static' => $isStatic,
            'expires_at' => now()->addDay(),
        ]);
    }
}
