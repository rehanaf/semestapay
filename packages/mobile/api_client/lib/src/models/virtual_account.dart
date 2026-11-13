class VirtualAccountInfo {
  final String id;
  final int studentId;
  final String? studentName;
  final String? studentNis;
  final String? accountName;
  final String provider;
  final String paymentMethod;
  final String bankName;
  final String accountNumber;
  final String merchantOrderId;
  final String? reference;
  final double amount;
  final String status;
  final bool isStatic;
  final bool isOpenAmount;
  final String? paymentUrl;
  final String? expiresAt;
  final bool isNew;

  VirtualAccountInfo({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentNis,
    this.accountName,
    required this.provider,
    required this.paymentMethod,
    required this.bankName,
    required this.accountNumber,
    required this.merchantOrderId,
    this.reference,
    required this.amount,
    required this.status,
    this.isStatic = false,
    this.isOpenAmount = false,
    this.paymentUrl,
    this.expiresAt,
    required this.isNew,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isExpired => status == 'expired';

  factory VirtualAccountInfo.fromJson(Map<String, dynamic> json,
      {bool isNew = false}) {
    final va = json['virtual_account'] as Map<String, dynamic>? ?? json;
    return VirtualAccountInfo(
      id: va['id']?.toString() ?? '',
      studentId: (va['student_id'] as num?)?.toInt() ?? 0,
      studentName: va['student_name'] as String?,
      studentNis: va['student_nis'] as String?,
      accountName: va['account_name'] as String?,
      provider: va['provider'] as String? ?? 'duitku',
      paymentMethod: va['payment_method'] as String? ?? '',
      bankName: va['bank_name'] as String? ?? '',
      accountNumber: va['account_number'] as String? ?? '',
      merchantOrderId: va['merchant_order_id'] as String? ?? '',
      reference: va['reference'] as String?,
      amount: (va['amount'] as num?)?.toDouble() ?? 0.0,
      status: va['status'] as String? ?? 'pending',
      isStatic: va['is_static'] as bool? ?? false,
      isOpenAmount: va['is_open_amount'] as bool? ?? false,
      paymentUrl: va['payment_url'] as String?,
      expiresAt: va['expires_at'] as String?,
      isNew: json['is_new'] as bool? ?? isNew,
    );
  }
}
