<?php

namespace Database\Seeders;

use App\Models\Bill;
use App\Models\Cashier;
use App\Models\Item;
use App\Models\Merchant;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\User;
use App\Services\CashierShiftService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $roles = [
            'super-admin', 'admin', 'finance', 'operator', 'cashier', 'parent',
        ];

        foreach ($roles as $role) {
            Role::findOrCreate($role);
        }

        $admin = User::firstOrCreate(
            ['email' => 'admin@cashless.dev'],
            [
                'name' => 'Admin Cashless',
                'phone' => '081200000001',
                'password' => Hash::make('password'),
                'status' => 'active',
            ],
        );
        $admin->syncRoles(['super-admin']);

        $kasirUser = User::firstOrCreate(
            ['email' => 'kasir@cashless.dev'],
            [
                'name' => 'Kasir Kantin',
                'phone' => '081200000002',
                'password' => Hash::make('password'),
                'status' => 'active',
            ],
        );
        $kasirUser->syncRoles(['cashier']);

        $operator = User::firstOrCreate(
            ['email' => 'operator@cashless.dev'],
            [
                'name' => 'Operator',
                'phone' => '081200000003',
                'password' => Hash::make('password'),
                'status' => 'active',
            ],
        );
        $operator->syncRoles(['operator']);

        $classA = SchoolClass::firstOrCreate(['name' => 'Kelas 7A'], ['level' => '7']);
        $classB = SchoolClass::firstOrCreate(['name' => 'Kelas 7B'], ['level' => '7']);

        $students = [];
        $names = ['Ahmad Fauzi', 'Budi Santoso', 'Citra Lestari', 'Dewi Anggraini', 'Eka Prasetyo'];

        foreach ($names as $i => $name) {
            $student = Student::firstOrCreate(
                ['nis' => '2026-00'.($i + 1)],
                [
                    'name' => $name,
                    'class_id' => $i % 2 === 0 ? $classA->id : $classB->id,
                    'phone_parent' => '0813120000'.($i + 10),
                    'status' => 'active',
                    'card_uid' => 'DEMO-UID-000'.($i + 1),
                    'card_status' => 'active',
                    'card_assigned_at' => now(),
                    'balance' => random_int(50, 200) * 1000,
                    'currency' => 'IDR',
                    'wallet_status' => 'active',
                    'daily_limit' => 50000,
                    'pin_hash' => $i === 0 ? Hash::make('123456') : null,
                ],
            );

            $students[] = $student;
        }

        $kantin = Merchant::firstOrCreate(
            ['name' => 'Kantin Pesantren'],
            ['type' => 'canteen', 'status' => 'active'],
        );
        $outletKantin = $kantin->outlets()->firstOrCreate(
            ['code' => 'KANTIN-1'],
            ['name' => 'Kantin Utama'],
        );

        $kantinItems = [
            'Nasi Goreng' => 10000,
            'Nasi Uduk' => 8000,
            'Indomie Goreng' => 7000,
            'Es Teh' => 3000,
            'Air Mineral' => 2000,
        ];

        foreach ($kantinItems as $name => $price) {
            Item::firstOrCreate(
                ['merchant_id' => $kantin->id, 'name' => $name],
                ['price' => $price, 'status' => 'active'],
            );
        }

        $koperasi = Merchant::firstOrCreate(
            ['name' => 'Koperasi Pesantren'],
            ['type' => 'cooperative', 'status' => 'active'],
        );
        $koperasi->outlets()->firstOrCreate(
            ['code' => 'KOPERASI-1'],
            ['name' => 'Koperasi'],
        );

        $koperasiItems = ['Pensil' => 3000, 'Buku Tulis' => 5000, 'Penghapus' => 2000];

        foreach ($koperasiItems as $name => $price) {
            Item::firstOrCreate(
                ['merchant_id' => $koperasi->id, 'name' => $name],
                ['price' => $price, 'status' => 'active'],
            );
        }

        Cashier::firstOrCreate(
            ['user_id' => $kasirUser->id, 'outlet_id' => $outletKantin->id],
            ['status' => 'active'],
        );

        app(CashierShiftService::class)->open($outletKantin, $kasirUser);

        Bill::firstOrCreate(
            ['student_id' => $students[0]->id, 'type' => 'spp', 'period' => '2026-09'],
            [
                'description' => 'SPP bulan September',
                'amount' => 300000,
                'due_date' => now()->addDays(14),
                'status' => 'unpaid',
            ],
        );

        Bill::firstOrCreate(
            ['student_id' => $students[1]->id, 'type' => 'pondok', 'period' => '2026-09'],
            [
                'description' => 'Uang pondok',
                'amount' => 500000,
                'due_date' => now()->addDays(7),
                'status' => 'unpaid',
            ],
        );

        $this->command?->info('Seed selesai.');
    }
}
