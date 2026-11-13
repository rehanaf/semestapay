<?php

namespace Database\Seeders;

use App\Enums\VirtualAccountStatus;
use App\Exceptions\Payment\DuitkuException;
use App\Models\Bill;
use App\Models\Cashier;
use App\Models\Item;
use App\Models\Merchant;
use App\Models\Outlet;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\User;
use App\Services\Payment\DuitkuService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ── Roles ──────────────────────────────────────────────────────────
        foreach (['super-admin', 'admin', 'finance', 'operator', 'cashier', 'parent'] as $role) {
            Role::findOrCreate($role);
        }

        // ── Admin Users ────────────────────────────────────────────────────
        $admin = User::firstOrCreate(
            ['email' => 'admin@cendana.sch.id'],
            [
                'name' => 'Admin Cendana',
                'username' => 'admin',
                'phone' => '081200000001',
                'password' => Hash::make('password'),
                'status' => 'active',
            ],
        );
        $admin->syncRoles(['super-admin']);

        // Guru / Pengajar sebagai operator
        $neneng = User::firstOrCreate(
            ['email' => 'neneng@cendana.sch.id'],
            [
                'name' => 'Miss Neneng',
                'username' => 'neneng',
                'phone' => '081200000010',
                'password' => Hash::make('password'),
                'status' => 'active',
            ],
        );
        $neneng->syncRoles(['operator']);

        $fuji = User::firstOrCreate(
            ['email' => 'fuji@cendana.sch.id'],
            [
                'name' => 'Ustadz Fuji',
                'username' => 'fuji',
                'phone' => '081200000011',
                'password' => Hash::make('password'),
                'status' => 'active',
            ],
        );
        $fuji->syncRoles(['operator']);

        // ── Kelas ──────────────────────────────────────────────────────────
        $kelas = SchoolClass::firstOrCreate(
            ['name' => 'Cendana A'],
            ['level' => '1'],
        );

        // ── Merchants ──────────────────────────────────────────────────────

        // 1. Koperasi Siswa
        $kopsis = Merchant::firstOrCreate(
            ['name' => 'Koperasi Siswa'],
            [
                'type' => 'cooperative',
                'owner_name' => 'Miss Neneng',
                'phone' => '081200000020',
                'email' => 'kopsis@cendana.sch.id',
                'address' => 'Jln. Cendana Raya No. 13 Bumi Arumsari - Talun - Cirebon',
                'description' => 'Koperasi siswa Cendana Smart Learning — buku, alat tulis, modul.',
                'status' => 'active',
            ],
        );
        $outletKopsis = $kopsis->outlets()->firstOrCreate(
            ['code' => 'KOPSIS-01'],
            ['name' => 'Koperasi Siswa', 'status' => 'active'],
        );

        $kopsisItems = [
            'Buku Tulis' => 5000,
            'Pensil' => 2000,
            'Penghapus' => 2000,
            'Penggaris' => 3000,
            'Modul Belajar' => 25000,
            'Spidol' => 5000,
        ];
        foreach ($kopsisItems as $nama => $harga) {
            Item::firstOrCreate(
                ['merchant_id' => $kopsis->id, 'name' => $nama],
                ['price' => $harga, 'status' => 'active'],
            );
        }

        // Kasir kopsis — pakai ustadz fuji
        $fuji->update(['merchant_id' => $kopsis->id]);
        Cashier::firstOrCreate(
            ['user_id' => $fuji->id, 'outlet_id' => $outletKopsis->id],
            ['status' => 'active'],
        );

        // 2. Kantin (limit harian Rp 20.000 per siswa per hari)
        $kantin = Merchant::firstOrCreate(
            ['name' => 'Kantin'],
            [
                'type' => 'canteen',
                'owner_name' => 'Miss Neneng',
                'phone' => '081200000021',
                'email' => 'kantin@cendana.sch.id',
                'address' => 'Jln. Cendana Raya No. 13 Bumi Arumsari - Talun - Cirebon',
                'description' => 'Kantin Cendana Smart Learning — batas belanja harian Rp 20.000.',
                'status' => 'active',
                'daily_limit' => 20000,
            ],
        );
        $outletKantin = $kantin->outlets()->firstOrCreate(
            ['code' => 'KANTIN-01'],
            ['name' => 'Kantin Utama', 'status' => 'active'],
        );

        $kantinItems = [
            'Nasi Goreng' => 10000,
            'Nasi Uduk' => 8000,
            'Indomie' => 7000,
            'Es Teh' => 3000,
            'Air Mineral' => 2000,
            'Gorengan' => 2000,
            'Bubur Ayam' => 9000,
        ];
        foreach ($kantinItems as $nama => $harga) {
            Item::firstOrCreate(
                ['merchant_id' => $kantin->id, 'name' => $nama],
                ['price' => $harga, 'status' => 'active'],
            );
        }

        // Kasir kantin — pakai miss neneng
        $neneng->update(['merchant_id' => $kantin->id]);
        Cashier::firstOrCreate(
            ['user_id' => $neneng->id, 'outlet_id' => $outletKantin->id],
            ['status' => 'active'],
        );

        // 3. TU — Tata Usaha (Pembayaran SPP)
        $tu = Merchant::firstOrCreate(
            ['name' => 'TU (Tata Usaha)'],
            [
                'type' => 'school',
                'owner_name' => 'Admin Cendana',
                'phone' => '081200000022',
                'email' => 'tu@cendana.sch.id',
                'address' => 'Jln. Cendana Raya No. 13 Bumi Arumsari - Talun - Cirebon',
                'description' => 'Tata Usaha Cendana Smart Learning — pembayaran SPP dan administrasi.',
                'status' => 'active',
            ],
        );
        $outletTu = $tu->outlets()->firstOrCreate(
            ['code' => 'TU-01'],
            ['name' => 'Loket TU', 'status' => 'active'],
        );

        $tuItems = [
            'SPP Bulanan' => 300000,
            'Biaya Ujian' => 100000,
            'Biaya Kegiatan' => 50000,
            'Seragam' => 150000,
        ];
        foreach ($tuItems as $nama => $harga) {
            Item::firstOrCreate(
                ['merchant_id' => $tu->id, 'name' => $nama],
                ['price' => $harga, 'status' => 'active'],
            );
        }

        Cashier::firstOrCreate(
            ['user_id' => $admin->id, 'outlet_id' => $outletTu->id],
            ['status' => 'active'],
        );

        // ── Siswa ──────────────────────────────────────────────────────────
        // daily_limit:
        //   kantin  = 20000 (catatan khusus)
        //   kopsis & TU = tidak dibatasi (0 = unlimited)
        // Di sini daily_limit adalah global, kita set 20000 sesuai aturan kantin.
        // Kopsis & TU tidak ada limit → diimplementasi di level merchant/outlet nanti.

        $siswaData = [
            ['nis' => 'CSL-2026-001', 'name' => 'Ajeng',    'gender' => 'female', 'card' => 'CSL-UID-001'],
            ['nis' => 'CSL-2026-002', 'name' => 'Citra',    'gender' => 'female', 'card' => 'CSL-UID-002'],
            ['nis' => 'CSL-2026-003', 'name' => 'Zikri',    'gender' => 'male',   'card' => 'CSL-UID-003'],
            ['nis' => 'CSL-2026-004', 'name' => 'Aiko',     'gender' => 'female', 'card' => 'CSL-UID-004'],
            ['nis' => 'CSL-2026-005', 'name' => 'Ralin',    'gender' => 'female', 'card' => 'CSL-UID-005'],
            ['nis' => 'CSL-2026-006', 'name' => 'Alya',     'gender' => 'female', 'card' => 'CSL-UID-006'],
            ['nis' => 'CSL-2026-007', 'name' => 'Zaenal',   'gender' => 'male',   'card' => 'CSL-UID-007'],
            ['nis' => 'CSL-2026-008', 'name' => 'Zaenab',   'gender' => 'female', 'card' => 'CSL-UID-008'],
            ['nis' => 'CSL-2026-009', 'name' => 'Gege',     'gender' => 'male',   'card' => 'CSL-UID-009'],
            ['nis' => 'CSL-2026-010', 'name' => 'Reinhard', 'gender' => 'male',   'card' => 'CSL-UID-010'],
            ['nis' => 'CSL-2026-011', 'name' => 'Hafidz',   'gender' => 'male',   'card' => 'CSL-UID-011'],
            ['nis' => 'CSL-2026-012', 'name' => 'Althaf',   'gender' => 'male',   'card' => 'CSL-UID-012'],
        ];

        $students = [];
        foreach ($siswaData as $i => $data) {
            $username = strtolower(str_replace(' ', '', $data['name']));
            $student = Student::firstOrCreate(
                ['nis' => $data['nis']],
                [
                    'name' => $data['name'],
                    'username' => $username,
                    'email' => $username.'@cendana.sch.id',
                    'gender' => $data['gender'],
                    'class_id' => $kelas->id,
                    'religion' => 'islam',
                    'marital_status' => 'single',
                    'address' => 'Jln. Cendana Raya No. 13 Bumi Arumsari - Talun - Cirebon',
                    'status' => 'active',
                    'card_uid' => $data['card'],
                    'card_status' => 'active',
                    'card_assigned_at' => now(),
                    'balance' => 100000, // saldo awal Rp 100.000
                    'currency' => 'IDR',
                    'wallet_status' => 'active',
                    'daily_limit' => 20000,  // batas harian kantin
                    'password_hash' => Hash::make('password'),
                    'pin_hash' => Hash::make('123456'),
                ],
            );
            $students[] = $student;
        }

        // ── VA Duitku per siswa ────────────────────────────────────────────
        $this->command?->info('Membuat Virtual Account Duitku untuk setiap siswa...');

        /** @var DuitkuService $duitku */
        $duitku = app(DuitkuService::class);

        // Bank rotation: BCA, Mandiri, BNI, BRI, kembali ke BCA dst.
        $bankPool = ['BC', 'M2', 'I1', 'BR', 'BT'];

        foreach ($students as $idx => $student) {
            // Skip jika sudah punya VA pending
            $existing = $student->virtualAccounts()
                ->where('status', VirtualAccountStatus::Pending->value)
                ->where('expires_at', '>', now())
                ->exists();

            if ($existing) {
                $this->command?->line("  ↷ {$student->name} sudah punya VA aktif, dilewati.");

                continue;
            }

            $method = $bankPool[$idx % count($bankPool)];

            try {
                $va = $duitku->createVirtualAccount(
                    student: $student,
                    amount: 50000, // nominal top up default Rp 50.000
                    paymentMethod: $method,
                );
                $this->command?->info("  ✓ {$student->name} → {$va->bank_name}: {$va->account_number}");
            } catch (DuitkuException $e) {
                $this->command?->warn("  ✗ {$student->name}: ".$e->getMessage());
            }

            // Jeda kecil agar tidak flood API Duitku
            usleep(300000); // 300ms
        }

        // ── Tagihan SPP per siswa ──────────────────────────────────────────
        $bulan = now()->format('Y-m');
        foreach ($students as $student) {
            Bill::firstOrCreate(
                ['student_id' => $student->id, 'type' => 'spp', 'period' => $bulan],
                [
                    'description' => 'SPP '.now()->isoFormat('MMMM YYYY'),
                    'amount' => 300000,
                    'due_date' => now()->endOfMonth(),
                    'status' => 'unpaid',
                ],
            );
        }

        $this->command?->info('');
        $this->command?->info('✓ Seed Cendana Smart Learning selesai!');
        $this->command?->info('  Siswa   : '.count($students));
        $this->command?->info('  Merchant: Koperasi Siswa, Kantin, TU');
        $this->command?->info('  Admin   : admin@cendana.sch.id / password');
        $this->command?->info('  Siswa   : [nama]@cendana.sch.id / password / PIN: 123456');
    }
}
