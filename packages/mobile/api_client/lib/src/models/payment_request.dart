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
  final String transactionId;
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
    final rawId = json['transaction_id']?.toString() ??
        json['id']?.toString() ??
        '';
    final invoice =
        rawId.length >= 8 ? rawId.substring(0, 8).toUpperCase() : rawId;

    return TapPaymentResponse(
      transactionId: rawId,
      invoiceNumber: invoice,
      status: (json['status'] as String?) ?? 'success',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      walletBalanceAfter: (json['balance_after'] as num?)?.toDouble() ??
          (json['wallet_balance_after'] as num?)?.toDouble(),
      studentName: json['student'] is Map
          ? (json['student'] as Map)['name']?.toString()
          : json['student_name']?.toString(),
      createdAt: json['created_at']?.toString(),
      note: json['note'] as String?,
    );
  }
}
