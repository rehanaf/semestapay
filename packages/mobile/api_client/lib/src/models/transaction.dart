class TransactionRecord {
  final String id;
  final String invoiceNumber;
  final String type;
  final double amount;
  final String status;
  final String? note;
  final String? studentName;
  final String? studentNis;
  final String? outletName;
  final String createdAt;

  TransactionRecord({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    required this.amount,
    required this.status,
    this.note,
    this.studentName,
    this.studentNis,
    this.outletName,
    required this.createdAt,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final invoice = json['invoice_number'] as String? ??
        json['reference_no'] as String? ??
        (rawId.length >= 8 ? rawId.substring(0, 8).toUpperCase() : rawId);

    return TransactionRecord(
      id: rawId,
      invoiceNumber: invoice,
      type: json['type'] as String? ?? 'payment',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'posted',
      note: json['note'] as String?,
      studentName: json['student_name'] as String? ??
          json['student']?['name'] as String? ??
          'Santri',
      studentNis: json['student_nis'] as String? ??
          json['student']?['nis'] as String?,
      outletName: json['merchant_name'] as String? ??
          json['outlet_name'] as String? ??
          json['outlet']?['name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
