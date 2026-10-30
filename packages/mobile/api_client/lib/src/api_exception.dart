class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
