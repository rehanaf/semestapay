<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AuthLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_with_valid_credentials(): void
    {
        Role::findOrCreate('admin', 'web');

        $user = User::factory()->create([
            'email' => 'operator@semestapay.id',
            'password' => Hash::make('secret123'),
            'status' => 'active',
        ]);
        $user->assignRole('admin');

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'operator@semestapay.id',
            'password' => 'secret123',
            'device_name' => 'test-device',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'token',
                'user' => [
                    'id',
                    'name',
                    'email',
                    'phone',
                    'roles',
                ],
            ]);

        $this->assertEquals($user->id, $response->json('user.id'));
    }

    public function test_user_cannot_login_with_invalid_password(): void
    {
        User::factory()->create([
            'email' => 'operator@semestapay.id',
            'password' => Hash::make('secret123'),
            'status' => 'active',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'operator@semestapay.id',
            'password' => 'wrong-password',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_inactive_user_cannot_login(): void
    {
        User::factory()->create([
            'email' => 'operator@semestapay.id',
            'password' => Hash::make('secret123'),
            'status' => 'inactive',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'operator@semestapay.id',
            'password' => 'secret123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }
}
