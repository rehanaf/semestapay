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

  Future<void> login(String nis, String pin) async {
    final auth = await api.studentLogin(nis: nis, pin: pin);
    _token = auth.token;
    _student = auth.student;
    api.setToken(auth.token);
    notifyListeners();
    await refresh();
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
