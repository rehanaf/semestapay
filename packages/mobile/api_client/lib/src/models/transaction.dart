class TransactionRecord {
  final int id;
  final String invoiceNumber;
  final String type;
  final double amount;
  final String status;
  final String? note;
  final String? studentName;
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
    this.outletName,
    required this.createdAt,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as int? ?? 0,
      invoiceNumber: json['invoice_number'] as String? ??
          json['reference_no'] as String? ??
          '-',
      type: json['type'] as String? ?? 'purchase',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'success',
      note: json['note'] as String?,
      studentName: json['student_name'] as String? ?? json['student']?['name'] as String?,
      outletName: json['outlet_name'] as String? ?? json['outlet']?['name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
