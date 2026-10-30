<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    public function test_super_admin_can_browse_items_resource(): void
    {
        Role::findOrCreate('super-admin', 'web');

        $admin = User::factory()->create(['email' => 'admin@example.com']);
        $admin->syncRoles(['super-admin']);

        $this->actingAs($admin, 'web')
            ->get('/admin/items')
            ->assertSuccessful()
            ->assertSee('Items');

        $this->actingAs($admin, 'web')
            ->get('/admin/items/create')
            ->assertSuccessful();
    }

    public function test_cashier_is_denied_from_admin_panel(): void
    {
        Role::findOrCreate('cashier', 'web');

        $cashier = User::factory()->create(['email' => 'kasir@example.com']);
        $cashier->syncRoles(['cashier']);

        $this->actingAs($cashier, 'web')
            ->get('/admin/items')
            ->assertForbidden();
    }

    public function test_guest_is_redirected_from_admin_panel(): void
    {
        $this->get('/admin/items')
            ->assertRedirect();
    }
}
