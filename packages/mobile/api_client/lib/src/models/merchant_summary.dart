class MerchantOutlet {
  final int id;
  final String code;
  final String name;
  final String status;

  MerchantOutlet({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
  });

  factory MerchantOutlet.fromJson(Map<String, dynamic> json) {
    return MerchantOutlet(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class MerchantSummary {
  final int id;
  final String code;
  final String name;
  final String? type;
  final String status;
  final double balance;
  final double todayIncome;
  final int transactionCount;
  final String? lastTransactionAt;
  final List<MerchantOutlet> outlets;

  MerchantSummary({
    required this.id,
    required this.code,
    required this.name,
    this.type,
    required this.status,
    required this.balance,
    required this.todayIncome,
    required this.transactionCount,
    this.lastTransactionAt,
    required this.outlets,
  });

  bool get isActive => status == 'active';

  factory MerchantSummary.fromJson(Map<String, dynamic> json) {
    final outletList = (json['outlets'] as List<dynamic>?)
            ?.map((e) => MerchantOutlet.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return MerchantSummary(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      status: json['status'] as String? ?? 'active',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      todayIncome: (json['today_income'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      lastTransactionAt: json['last_transaction_at'] as String?,
      outlets: outletList,
    );
  }
}
