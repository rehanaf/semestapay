import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';

class StudentState extends ChangeNotifier {
  final SemestaPayApiClient api = SemestaPayApiClient();

  String? _token;
  StudentProfile? _student;
  StudentDashboard? _dashboard;
  List<StudentMutation> _mutations = [];
  bool _loading = false;

  String? get token => _token;
  StudentProfile? get student => _student;
  StudentDashboard? get dashboard => _dashboard;
  List<StudentMutation> get mutations => List.unmodifiable(_mutations);
  bool get isAuthenticated => _token != null && _student != null;
  bool get isLoading => _loading;

  Future<void> login(
    String identifier,
    String passwordOrPin, {
    bool isLegacyPin = false,
  }) async {
    final auth = await api.studentLogin(
      username: !isLegacyPin ? identifier : null,
      password: !isLegacyPin ? passwordOrPin : null,
      nis: isLegacyPin ? identifier : null,
      pin: isLegacyPin ? passwordOrPin : null,
    );
    _token = auth.token;
    _student = auth.student;
    api.setToken(auth.token);
    notifyListeners();
    await refresh();
  }

  void updateStudent(StudentProfile profile) {
    _student = profile;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? username,
    String? phone,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (username != null) payload['username'] = username;
    if (phone != null) payload['phone'] = phone;
    final updated = await api.updateStudentProfile(payload);
    _student = updated;
    notifyListeners();
  }

  Future<String> updateAvatar(String base64Image) async {
    final avatarUrl = await api.uploadStudentAvatar(base64Image);
    if (_student != null) {
      _student = StudentProfile(
        id: _student!.id,
        name: _student!.name,
        nis: _student!.nis,
        username: _student!.username,
        email: _student!.email,
        className: _student!.className,
        cardUid: _student!.cardUid,
        cardStatus: _student!.cardStatus,
        status: _student!.status,
        balance: _student!.balance,
        currency: _student!.currency,
        walletStatus: _student!.walletStatus,
        dailyLimit: _student!.dailyLimit,
        avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : _student!.avatarUrl,
        nik: _student!.nik,
        gender: _student!.gender,
        birthDate: _student!.birthDate,
        address: _student!.address,
        phoneParent: _student!.phoneParent,
        parentName: _student!.parentName,
        parentEmail: _student!.parentEmail,
        balanceUpdatedAt: _student!.balanceUpdatedAt,
      );
      notifyListeners();
    }
    return avatarUrl;
  }

  Future<void> refresh() async {
    if (!isAuthenticated) return;
    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        api.getStudentDashboard(),
        api.getStudentMutations(limit: 50),
      ]);
      _dashboard = results[0] as StudentDashboard;
      _student = _dashboard!.student;
      _mutations = results[1] as List<StudentMutation>;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void logout() {
    _token = null;
    _student = null;
    _dashboard = null;
    _mutations = [];
    api.clearToken();
    notifyListeners();
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(date.toLocal());
  }
}
