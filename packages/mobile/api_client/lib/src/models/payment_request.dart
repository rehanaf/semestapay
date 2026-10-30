class TapPaymentItem {
  final int itemId;
  final int quantity;

  TapPaymentItem({required this.itemId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
      };
}

class TapPaymentRequest {
  final String cardUid;
  final String outletCode;
  final double amount;
  final String idempotencyKey;
  final String? note;
  final String? pin;
  final List<TapPaymentItem>? items;

  TapPaymentRequest({
    required this.cardUid,
    required this.outletCode,
    required this.amount,
    required this.idempotencyKey,
    this.note,
    this.pin,
    this.items,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'card_uid': cardUid,
      'outlet_code': outletCode,
      'amount': amount,
      'idempotency_key': idempotencyKey,
    };
    if (note != null && note!.isNotEmpty) map['note'] = note;
    if (pin != null && pin!.isNotEmpty) map['pin'] = pin;
    if (items != null && items!.isNotEmpty) {
      map['items'] = items!.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

class TapPaymentResponse {
  final int transactionId;
  final String invoiceNumber;
  final String status;
  final double amount;
  final double? walletBalanceAfter;
  final String? studentName;
  final String? createdAt;
  final String? note;

  TapPaymentResponse({
    required this.transactionId,
    required this.invoiceNumber,
    required this.status,
    required this.amount,
    this.walletBalanceAfter,
    this.studentName,
    this.createdAt,
    this.note,
  });

  factory TapPaymentResponse.fromJson(Map<String, dynamic> json) {
    final tx = json['transaction'] as Map<String, dynamic>? ?? json;
    return TapPaymentResponse(
      transactionId: (tx['id'] as int?) ?? 0,
      invoiceNumber: (tx['invoice_number'] as String?) ??
          (tx['reference_no'] as String?) ??
          '',
      status: (tx['status'] as String?) ?? 'success',
      amount: (tx['amount'] as num?)?.toDouble() ?? 0.0,
      walletBalanceAfter: (tx['wallet_balance_after'] as num?)?.toDouble() ??
          (json['wallet']?['balance'] as num?)?.toDouble(),
      studentName: tx['student']?['name'] as String?,
      createdAt: tx['created_at'] as String?,
      note: tx['note'] as String?,
    );
  }
}
