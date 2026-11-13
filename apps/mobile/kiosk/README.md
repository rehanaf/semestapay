# SemestaPAY Kiosk

Aplikasi Flutter stasiun mandiri santri. Alur utama:

1. **Tap kartu RFID** — dibaca sebagai keyboard HID (USB RFID reader) atau lewat tombol simulasi untuk demo.
2. **Masukkan PIN 6 digit** — memakai `SemestaKeypad` dari package bersama.
3. **Dashboard** — saldo, limit harian, akses cepat, dan riwayat transaksi.
4. **Auto logout** — sesi santri berakhir otomatis setelah 60 detik tanpa aktivitas.

## Menjalankan

```bash
cd apps/mobile/kiosk
flutter pub get
flutter run
```

## Konfigurasi

Nilai berikut dapat di-override lewat `--dart-define` saat build:

| Variabel | Default | Keterangan |
| --- | --- | --- |
| `API_BASE_URL` | `https://pay-api.zet.web.id/api/v1` | Base URL API |
| `KIOSK_OPERATOR_EMAIL` | `operator@cashless.dev` | Akun perangkat untuk membaca kartu |
| `KIOSK_OPERATOR_PASSWORD` | `password` | Password akun perangkat |

Contoh:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://pay-api.zet.web.id/api/v1 \
  --dart-define=KIOSK_OPERATOR_EMAIL=operator@cashless.dev \
  --dart-define=KIOSK_OPERATOR_PASSWORD=rahasia
```

Build lalu salin otomatis ke folder landing:

```bash
bash scripts/build_apk.sh kiosk
```

## Arsitektur

Aplikasi ini hanya berisi layar dan orkestrasi state. Seluruh widget dan API
dipakai bersama lewat package:

- `packages/mobile/ui` — `SemestaBalanceCard`, `SemestaHistoryTile`,
  `SemestaKeypad`, tema, dan widget dasar lain.
- `packages/mobile/api_client` — client API dan model.
- `packages/mobile/core` — util bersama.

Dua sesi API dipertahankan terpisah di `KioskState`:

- `deviceApi` — token operator, dipakai untuk `GET /card/read/{uid}`.
- `studentApi` — token santri hasil PIN, dipakai untuk dashboard & mutasi.
