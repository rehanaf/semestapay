# SemestaPay — Monorepo Architecture

Proyek Monorepo SemestaPay terbagi atas 3 layer utama:
1. **Backend**: Laravel 13 + Filament 5 + REST API Sanctum
2. **Web Dashboards**: 3 aplikasi Next.js (App Router, Turbopack, Tailwind v4) menggunakan shared shadcn/ui package
3. **Mobile Apps**: 3 aplikasi Flutter (Merchant, Student, Parent) menggunakan shared Dart packages

---

## 📁 Struktur Monorepo

```plaintext
semestapay/
├── apps/
│   ├── backend/               # Laravel + Filament (API & Admin Master)
│   ├── web/
│   │   ├── admin/             # Dashboard Admin (Port: 3003) [Tema: Indigo Blue]
│   │   ├── school/            # Dashboard School/Pesantren (Port: 3001) [Tema: Emerald Green]
│   │   └── merchant/          # Dashboard Merchant/Kantin (Port: 3002) [Tema: Warm Amber]
│   └── mobile/
│       ├── merchant/          # Flutter App Merchant / Kasir Tap
│       ├── student/           # Flutter App Santri / Siswa
│       └── parent/            # Flutter App Wali Santri / Orang Tua
├── packages/
│   ├── web/
│   │   └── ui/                # @semestapay/ui (shadcn/ui shared components)
│   └── mobile/
│       ├── core/              # Shared constants, helpers & storage
│       ├── ui/                # Shared theme & Flutter widgets
│       └── api_client/        # Shared API models & HTTP client
├── docker-compose.yml         # MySQL 8, Redis, Mailpit
├── pnpm-workspace.yaml        # Workspace configuration untuk web
├── turbo.json                 # Turborepo task pipeline
└── melos.yaml                 # Melos configuration untuk Flutter
```

---

## 🚀 Panduan Menjalankan Development Server

### 1. Web Apps (Next.js)

Jalankan semua web app secara bersamaan dengan Turborepo:
```bash
pnpm dev
```
Atau jalankan masing-masing secara terpisah:
```bash
pnpm dev:admin     # http://localhost:3003
pnpm dev:school    # http://localhost:3001
pnpm dev:merchant  # http://localhost:3002
```

Build semua web app:
```bash
pnpm build
```

### 2. Backend (Laravel)

```bash
cd apps/backend
php artisan serve --port=8000
```
- Endpoint API: `http://localhost:8000/api/v1`
- Panel Filament: `http://localhost:8000/admin`

### 3. Mobile Apps (Flutter)

```bash
# Jalankan Merchant App
cd apps/mobile/merchant && flutter run

# Jalankan Student App
cd apps/mobile/student && flutter run

# Jalankan Parent App
cd apps/mobile/parent && flutter run
```

---

## 🎨 Menambah Komponen shadcn Baru

Cukup tambahkan komponen ke dalam package bersama `@semestapay/ui`:
```bash
pnpm dlx shadcn@latest add dialog table dropdown-menu -c packages/web/ui
```
Lalu komponen tersebut langsung bisa di-import di ketiga web app:
```tsx
import { Dialog, Table } from "@semestapay/ui/components/dialog";
```
Warna tombol, border, dan elemen lainnya otomatis mengikuti tema warna di masing-masing `app/globals.css`.
