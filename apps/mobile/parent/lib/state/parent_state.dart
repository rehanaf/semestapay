import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';

class ParentState extends ChangeNotifier {
  final SemestaPayApiClient api = SemestaPayApiClient();

  String? _token;
  User? _user;
  List<ParentChild> _children = [];
  ParentChild? _selectedChild;
  WalletSummary? _wallet;
  List<StudentMutation> _mutations = [];
  List<StudentBill> _bills = [];
  bool _loading = false;

  String? get token => _token;
  User? get user => _user;
  List<ParentChild> get children => List.unmodifiable(_children);
  ParentChild? get selectedChild => _selectedChild;
  WalletSummary? get wallet => _wallet;
  List<StudentMutation> get mutations => List.unmodifiable(_mutations);
  List<StudentBill> get bills => List.unmodifiable(_bills);
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _loading;

  double get outstandingBills {
    return _bills
        .where((bill) => !bill.isPaid)
        .fold(0.0, (sum, bill) => sum + bill.remainingAmount);
  }

  Future<void> loginWithNis(String phone, String nis) async {
    final auth = await api.parentLogin(phone: phone, nis: nis);
    _applyAuth(auth);
    await refreshChild();
  }

  Future<void> requestOtp(String phone) async {
    await api.sendOtp(phone);
  }

  Future<void> verifyOtp(String phone, String otp) async {
    final auth = await api.verifyOtp(phone: phone, otp: otp);
    _applyAuth(auth);
    await refreshChild();
  }

  void _applyAuth(ParentAuthResponse auth) {
    _token = auth.token;
    _user = auth.user;
    _children = auth.children;
    api.setToken(auth.token);
    _selectedChild = _children.isNotEmpty ? _children.first : null;
    notifyListeners();
  }

  Future<void> selectChild(ParentChild child) async {
    if (_selectedChild?.id == child.id) return;
    _selectedChild = child;
    _wallet = null;
    _mutations = [];
    _bills = [];
    notifyListeners();
    await refreshChild();
  }

  Future<void> refreshChild() async {
    final child = _selectedChild;
    if (child == null || !isAuthenticated) return;

    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        api.getWallet(child.id),
        api.getWalletMutations(child.id, limit: 50),
        api.getBills(child.id),
      ]);
      _wallet = results[0] as WalletSummary;
      _mutations = results[1] as List<StudentMutation>;
      _bills = results[2] as List<StudentBill>;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _children = [];
    _selectedChild = null;
    _wallet = null;
    _mutations = [];
    _bills = [];
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
