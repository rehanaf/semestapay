import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'models/auth_response.dart';
import 'models/card_info.dart';
import 'models/merchant_item.dart';
import 'models/payment_request.dart';
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

  void dispose() {
    _client.close();
  }
}
