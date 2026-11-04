import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'models/auth_response.dart';
import 'models/card_info.dart';
import 'models/merchant_item.dart';
import 'models/merchant_summary.dart';
import 'models/parent_portal.dart';
import 'models/payment_request.dart';
import 'models/student_portal.dart';
import 'models/transaction.dart';
import 'models/user.dart';

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
    required String nis,
    required String pin,
    String deviceName = 'student-flutter-app',
  }) async {
    final url = Uri.parse('$baseUrl/auth/student-login');
    final response = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'nis': nis,
        'pin': pin,
        'device_name': deviceName,
      }),
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

  void dispose() {
    _client.close();
  }
}
