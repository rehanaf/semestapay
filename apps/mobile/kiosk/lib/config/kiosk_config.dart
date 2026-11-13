/// Konfigurasi aplikasi Kiosk.
///
/// Semua nilai dapat dioverride saat build tanpa mengubah kode:
///
/// ```bash
/// flutter build apk --release \
///   --dart-define=API_BASE_URL=https://pay-api.zet.web.id/api/v1 \
///   --dart-define=KIOSK_OPERATOR_EMAIL=operator@cashless.dev \
///   --dart-define=KIOSK_OPERATOR_PASSWORD=password
/// ```
class KioskConfig {
  KioskConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pay-api.zet.web.id/api/v1',
  );

  /// Akun perangkat yang dipakai untuk membaca kartu (`/card/read/{uid}`).
  /// Endpoint tersebut membutuhkan token Sanctum.
  static const String operatorEmail = String.fromEnvironment(
    'KIOSK_OPERATOR_EMAIL',
    defaultValue: 'operator@cashless.dev',
  );

  static const String operatorPassword = String.fromEnvironment(
    'KIOSK_OPERATOR_PASSWORD',
    defaultValue: 'password',
  );

  static const String deviceName = 'semestapay-kiosk';

  /// Lama tidak ada aktivitas sebelum sesi santri otomatis keluar.
  static const Duration idleTimeout = Duration(seconds: 60);

  /// UID kartu fallback untuk tombol simulasi tap (dipakai hanya bila daftar
  /// santri tidak bisa diambil dari API).
  static const String demoCardUid = 'CSL-CARD-004';
}
