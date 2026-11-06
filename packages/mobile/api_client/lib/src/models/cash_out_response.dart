class CashOutResponse {
  final String transactionId;
  final String cardUid;
  final String studentName;
  final String? studentNis;
  final String? merchant;
  final String? outlet;
  final double amount;
  final double balanceAfter;
  final double merchantBalanceAfter;
  final String? createdAt;

  CashOutResponse({
    required this.transactionId,
    required this.cardUid,
    required this.studentName,
    this.studentNis,
    this.merchant,
    this.outlet,
    required this.amount,
    required this.balanceAfter,
    required this.merchantBalanceAfter,
    this.createdAt,
  });

  factory CashOutResponse.fromJson(Map<String, dynamic> json) {
    final studentMap = json['student'] as Map<String, dynamic>?;
    return CashOutResponse(
      transactionId: json['transaction_id']?.toString() ?? '',
      cardUid: json['card_uid'] as String? ?? '',
      studentName:
          studentMap?['name'] as String? ?? json['student_name'] as String? ?? '',
      studentNis: studentMap?['nis'] as String?,
      merchant: json['merchant'] as String?,
      outlet: json['outlet'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      merchantBalanceAfter:
          (json['merchant_balance_after'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at']?.toString(),
    );
  }
}
