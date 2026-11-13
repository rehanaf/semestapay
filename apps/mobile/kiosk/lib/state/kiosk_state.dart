import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';

import '../config/kiosk_config.dart';

/// State pusat aplikasi Kiosk.
///
/// Dua sesi dipertahankan secara terpisah:
/// - [deviceApi]  : token akun operator (untuk membaca kartu RFID)
/// - [studentApi] : token santri hasil verifikasi PIN
class KioskState extends ChangeNotifier {
  final SemestaPayApiClient deviceApi =
      SemestaPayApiClient(baseUrl: KioskConfig.apiBaseUrl);
  final SemestaPayApiClient studentApi =
      SemestaPayApiClient(baseUrl: KioskConfig.apiBaseUrl);

  bool _booting = true;
  String? _bootError;
  bool _signingIn = false;

  CardReadResponse? _scannedCard;
  StudentProfile? _student;
  StudentDashboard? _dashboard;
  List<StudentMutation> _mutations = [];
  bool _loadingDashboard = false;

  bool get booting => _booting;
  String? get bootError => _bootError;
  bool get signingIn => _signingIn;
  CardReadResponse? get scannedCard => _scannedCard;
  StudentProfile? get student => _student;
  StudentDashboard? get dashboard => _dashboard;
  List<StudentMutation> get mutations => List.unmodifiable(_mutations);
  bool get loadingDashboard => _loadingDashboard;
  bool get isStudentAuthenticated => _student != null;
  double get balance => _student?.balance ?? 0;

  // ── Bootstrap perangkat ────────────────────────────────────────────────────

  Future<void> bootstrap() async {
    _booting = true;
    _bootError = null;
    notifyListeners();

    try {
      await deviceApi.login(
        email: KioskConfig.operatorEmail,
        password: KioskConfig.operatorPassword,
        deviceName: KioskConfig.deviceName,
      );
    } catch (e) {
      _bootError = e is ApiException
          ? 'Aktivasi perangkat gagal: ${e.message}'
          : 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  // ── Tap kartu ──────────────────────────────────────────────────────────────

  /// UID kartu untuk tombol simulasi tap. Diambil dari santri pertama yang
  /// kartunya aktif, dengan fallback ke [KioskConfig.demoCardUid].
  Future<String> resolveDemoCardUid() async {
    try {
      final students = await deviceApi.getStudents();
      final student = students.firstWhere(
        (s) => s.hasActiveCard,
        orElse: () => students.first,
      );
      final uid = student.cardUid;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {
      // Abaikan — kembali ke konstanta demo.
    }
    return KioskConfig.demoCardUid;
  }

  Future<CardReadResponse> readCard(String uid) async {
    final card = await deviceApi.readCard(uid);
    if (!card.isUsable) {
      throw Exception('Kartu santri tidak aktif atau diblokir.');
    }
    _scannedCard = card;
    notifyListeners();
    return card;
  }

  void clearScannedCard() {
    _scannedCard = null;
    notifyListeners();
  }

  // ── Login santri dengan PIN ────────────────────────────────────────────────

  Future<void> loginWithPin(String pin) async {
    final card = _scannedCard;
    if (card == null) {
      throw Exception('Kartu belum terbaca. Silakan tap ulang kartu.');
    }
    _signingIn = true;
    notifyListeners();

    try {
      final auth = await studentApi.studentLogin(
        nis: card.student.nis,
        pin: pin,
        deviceName: KioskConfig.deviceName,
      );
      _student = auth.student;
      await _loadDashboard();
      notifyListeners();
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<void> _loadDashboard() async {
    _loadingDashboard = true;
    try {
      final results = await Future.wait([
        studentApi.getStudentDashboard(),
        studentApi.getStudentMutations(limit: 50),
      ]);
      _dashboard = results[0] as StudentDashboard;
      _student = _dashboard!.student;
      _mutations = results[1] as List<StudentMutation>;
    } finally {
      _loadingDashboard = false;
    }
  }

  Future<void> refresh() async {
    if (_student == null) return;
    notifyListeners();
    await _loadDashboard();
    notifyListeners();
  }

  // ── Logout santri (kembali ke layar tap) ───────────────────────────────────

  Future<void> logoutStudent() async {
    try {
      await studentApi.logout();
    } catch (_) {
      studentApi.clearToken();
    }
    _student = null;
    _dashboard = null;
    _mutations = [];
    _scannedCard = null;
    notifyListeners();
  }

  // ── Helper format ──────────────────────────────────────────────────────────

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(date.toLocal());
  }

  @override
  void dispose() {
    deviceApi.dispose();
    studentApi.dispose();
    super.dispose();
  }
}
