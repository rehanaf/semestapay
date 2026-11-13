import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'models/auth_response.dart';
import 'models/card_info.dart';
import 'models/cash_out_response.dart';
import 'models/merchant_item.dart';
import 'models/merchant_report.dart';
import 'models/merchant_summary.dart';
import 'models/parent_portal.dart';
import 'models/payment_request.dart';
import 'models/student_portal.dart';
import 'models/transaction.dart';
import 'models/user.dart';
import 'models/virtual_account.dart';

class SemestaPayApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  SemestaPayApiClient({
    this.baseUrl = 'https://pay-api.zet.web.id/api/v1',
    http.Client? client,
    String? token,
  })  : _client = client ?? http.Client(),
        _token = token;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    final bodyStr = response.body;
    dynamic data;
    try {
      data = bodyStr.isNotEmpty ? jsonDecode(bodyStr) : null;
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = 'Terjadi kesalahan sistem (${response.statusCode})';
    String? code;
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        message = data['message'];
      }
      if (data['code'] is String) {
        code = data['code'];
      }
      if (data['errors'] is Map<String, dynamic>) {
        errors = data['errors'];
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      code: code,
      errors: errors,
    );
  }

  // ==========================================
  // AUTH
  // ==========================================

  Future<AuthResponse> login({
    required String email,
    required String password,
    String deviceName = 'flutter-mobile',
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': deviceName,
      }),
    );

    final data = _processResponse(response) as Map<String, dynamic>;
    final auth = AuthResponse.fromJson(data);
    _token = auth.token;
    return auth;
  }

  Future<User> me() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final response = await _client.post(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');
      await _client.post(url, headers: _buildHeaders());
    } finally {
      clearToken();
    }
  }

  // ==========================================
  // STUDENT & PARENT AUTH
  // ==========================================

  Future<StudentAuthResponse> studentLogin({
    String? nis,
    String? pin,
    String? username,
    String? password,
    String? identifier,
    String deviceName = 'student-flutter-app',
  }) async {
    final url = Uri.parse('$baseUrl/auth/student-login');
    final payload = <String, dynamic>{
      'device_name': deviceName,
    };

    if (username != null && username.isNotEmpty) {
      payload['username'] = username;
    } else if (identifier != null && identifier.isNotEmpty) {
      payload['username'] = identifier;
    } else if (nis != null && nis.isNotEmpty) {
      payload['nis'] = nis;
    }

    if (password != null && password.isNotEmpty) {
      payload['password'] = password;
    } else if (pin != null && pin.isNotEmpty) {
      payload['pin'] = pin;
    }

    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(payload),
    );

    final data = _processResponse(response) as Map<String, dynamic>;
    final auth = StudentAuthResponse.fromJson(data);
    _token = auth.token;
    return auth;
  }

  Future<ParentAuthResponse> parentLogin({
    required String phone,
    required String nis,
    String deviceName = 'parent-flutter-app',
  }) async {
    final url = Uri.parse('$baseUrl/auth/parent-login');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'phone': phone,
        'nis': nis,
        'device_name': deviceName,
      }),
    );

    final data = _processResponse(response) as Map<String, dynamic>;
    final auth = ParentAuthResponse.fromJson(data);
    _token = auth.token;
    return auth;
  }

  Future<void> sendOtp(String phone) async {
    final url = Uri.parse('$baseUrl/auth/send-otp');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({'phone': phone}),
    );
    _processResponse(response);
  }

  Future<ParentAuthResponse> verifyOtp({
    required String phone,
    required String otp,
    String deviceName = 'parent-flutter-app',
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'device_name': deviceName,
      }),
    );

    final data = _processResponse(response) as Map<String, dynamic>;
    final auth = ParentAuthResponse.fromJson(data);
    _token = auth.token;
    return auth;
  }

  // ==========================================
  // STUDENT PORTAL
  // ==========================================

  Future<StudentDashboard> getStudentDashboard() async {
    final url = Uri.parse('$baseUrl/student/dashboard');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return StudentDashboard.fromJson(data);
  }

  Future<List<StudentMutation>> getStudentMutations({int limit = 50}) async {
    final url = Uri.parse('$baseUrl/student/mutations?limit=$limit');
    final response = await _client.get(url, headers: _buildHeaders());
    return _parseList(response, StudentMutation.fromJson);
  }

  Future<List<StudentBill>> getStudentBills() async {
    final url = Uri.parse('$baseUrl/student/bills');
    final response = await _client.get(url, headers: _buildHeaders());
    return _parseList(response, StudentBill.fromJson);
  }

  // ==========================================
  // PARENT PORTAL
  // ==========================================

  Future<WalletSummary> getWallet(int studentId) async {
    final url = Uri.parse('$baseUrl/wallet/$studentId');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return WalletSummary.fromJson(
      data['wallet'] as Map<String, dynamic>? ?? data,
    );
  }

  Future<List<StudentMutation>> getWalletMutations(
    int studentId, {
    int limit = 50,
  }) async {
    final url =
        Uri.parse('$baseUrl/wallet/$studentId/mutations?limit=$limit');
    final response = await _client.get(url, headers: _buildHeaders());
    return _parseList(response, StudentMutation.fromJson);
  }

  Future<List<StudentBill>> getBills(int studentId) async {
    final url = Uri.parse('$baseUrl/bills?student_id=$studentId');
    final response = await _client.get(url, headers: _buildHeaders());
    return _parseList(response, StudentBill.fromJson);
  }

  // ==========================================
  // PROFILES & AVATARS
  // ==========================================

  Future<StudentProfile> getStudentProfile() async {
    final url = Uri.parse('$baseUrl/profile/student');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return StudentProfile.fromJson(
      data['student'] as Map<String, dynamic>? ?? data,
    );
  }

  Future<StudentProfile> updateStudentProfile(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/profile/student');
    final response = await _client.put(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    final data = _processResponse(response) as Map<String, dynamic>;
    return StudentProfile.fromJson(
      data['student'] as Map<String, dynamic>? ?? data,
    );
  }

  Future<String> uploadStudentAvatar(String base64Image) async {
    final url = Uri.parse('$baseUrl/profile/student/avatar');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({'avatar': base64Image}),
    );
    final data = _processResponse(response) as Map<String, dynamic>;
    return (data['avatar_url'] as String?) ?? '';
  }

  Future<User> getUserProfile() async {
    final url = Uri.parse('$baseUrl/profile/me');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<User> updateUserProfile(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/profile/me');
    final response = await _client.put(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    final data = _processResponse(response) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<String> uploadUserAvatar(String base64Image) async {
    final url = Uri.parse('$baseUrl/profile/me/avatar');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({'avatar': base64Image}),
    );
    final data = _processResponse(response) as Map<String, dynamic>;
    return (data['avatar_url'] as String?) ?? '';
  }

  // ==========================================
  // MERCHANT PORTAL
  // ==========================================

  Future<MerchantSummary> getMerchantSummary({int? merchantId}) async {
    final query = merchantId == null ? '' : '?merchant_id=$merchantId';
    final url = Uri.parse('$baseUrl/merchant/summary$query');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return MerchantSummary.fromJson(
      data['merchant'] as Map<String, dynamic>? ?? data,
    );
  }

  Future<Map<String, dynamic>> getMerchantProfile() async {
    final url = Uri.parse('$baseUrl/merchant/profile');
    final response = await _client.get(url, headers: _buildHeaders());
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMerchantProfile(
      Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/merchant/profile');
    final response = await _client.put(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<CashOutResponse> cashOut({
    required String cardUid,
    required double amount,
    String? pin,
    String? note,
    String? outletCode,
    String? idempotencyKey,
  }) async {
    final url = Uri.parse('$baseUrl/merchant/cash-out');
    final payload = <String, dynamic>{
      'card_uid': cardUid,
      'amount': amount,
      'idempotency_key': idempotencyKey ??
          'cashout_${DateTime.now().millisecondsSinceEpoch}_$cardUid',
    };
    if (pin != null && pin.isNotEmpty) payload['pin'] = pin;
    if (note != null && note.isNotEmpty) payload['note'] = note;
    if (outletCode != null && outletCode.isNotEmpty) {
      payload['outlet_code'] = outletCode;
    }

    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(payload),
    );
    final data = _processResponse(response) as Map<String, dynamic>;
    return CashOutResponse.fromJson(data);
  }

  Future<MerchantReport> getMerchantReports({
    String period = 'day',
    String? date,
    String? month,
    String? start,
    String? end,
  }) async {
    final params = <String, String>{'period': period};
    if (date != null && date.isNotEmpty) params['date'] = date;
    if (month != null && month.isNotEmpty) params['month'] = month;
    if (start != null && start.isNotEmpty) params['start'] = start;
    if (end != null && end.isNotEmpty) params['end'] = end;

    final query = Uri(queryParameters: params).query;
    final url = Uri.parse('$baseUrl/merchant/reports?$query');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return MerchantReport.fromJson(data);
  }

  // ==========================================
  // CARD & POS
  // ==========================================

  Future<CardReadResponse> readCard(String cardUid) async {
    final url = Uri.parse('$baseUrl/card/read/$cardUid');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return CardReadResponse.fromJson(data);
  }

  Future<List<MerchantItem>> getItems() async {
    final url = Uri.parse('$baseUrl/items');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response);

    List<dynamic> list;
    if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list
        .map((e) => MerchantItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TapPaymentResponse> tapPayment(TapPaymentRequest request) async {
    final url = Uri.parse('$baseUrl/payments/tap');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(request.toJson()),
    );
    final data = _processResponse(response) as Map<String, dynamic>;
    return TapPaymentResponse.fromJson(data);
  }

  Future<List<TransactionRecord>> getTransactions() async {
    final url = Uri.parse('$baseUrl/transactions');
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response);

    List<dynamic> list;
    if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list
        .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<T> _parseList<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    final data = _processResponse(response);
    List<dynamic> list;

    if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'] as List<dynamic>;
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList();
  }

  Future<VirtualAccountInfo> getOrCreateTopupVa({
    double amount = 10000,
    String? paymentMethod,
    bool forceNew = false,
  }) async {
    final params = <String, String>{
      'amount': amount.toInt().toString(),
    };
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      params['payment_method'] = paymentMethod;
    }
    if (forceNew) {
      params['force_new'] = '1';
    }
    final url = Uri.parse('$baseUrl/student/topup/va').replace(queryParameters: params);
    final response = await _client.get(url, headers: _buildHeaders());
    final data = _processResponse(response) as Map<String, dynamic>;
    return VirtualAccountInfo.fromJson(data);
  }

  void dispose() {
    _client.close();
  }
}
