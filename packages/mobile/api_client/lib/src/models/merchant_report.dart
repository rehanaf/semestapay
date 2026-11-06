class MerchantReportSeries {
  final String date;
  final double income;
  final double cashOut;
  final int count;

  MerchantReportSeries({
    required this.date,
    required this.income,
    required this.cashOut,
    required this.count,
  });

  factory MerchantReportSeries.fromJson(Map<String, dynamic> json) {
    return MerchantReportSeries(
      date: json['date'] as String? ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      cashOut: (json['cash_out'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
    );
  }
}

class MerchantReportSummary {
  final double income;
  final double cashOut;
  final double net;
  final int transactionCount;

  MerchantReportSummary({
    required this.income,
    required this.cashOut,
    required this.net,
    required this.transactionCount,
  });

  factory MerchantReportSummary.fromJson(Map<String, dynamic> json) {
    return MerchantReportSummary(
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      cashOut: (json['cash_out'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
    );
  }
}

class MerchantReportItem {
  final String id;
  final String createdAt;
  final String type;
  final double amount;
  final String? studentName;
  final String? outletName;
  final String? note;

  MerchantReportItem({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.amount,
    this.studentName,
    this.outletName,
    this.note,
  });

  factory MerchantReportItem.fromJson(Map<String, dynamic> json) {
    return MerchantReportItem(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      type: json['type'] as String? ?? 'payment',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      studentName: json['student_name'] as String?,
      outletName: json['outlet_name'] as String?,
      note: json['note'] as String?,
    );
  }
}

class MerchantReport {
  final String period;
  final String start;
  final String end;
  final double merchantBalance;
  final MerchantReportSummary summary;
  final List<MerchantReportSeries> series;
  final List<MerchantReportItem> transactions;

  MerchantReport({
    required this.period,
    required this.start,
    required this.end,
    required this.merchantBalance,
    required this.summary,
    required this.series,
    required this.transactions,
  });

  factory MerchantReport.fromJson(Map<String, dynamic> json) {
    final merchantMap = json['merchant'] as Map<String, dynamic>? ?? {};
    final summaryMap = json['summary'] as Map<String, dynamic>? ?? {};
    final seriesList = (json['series'] as List<dynamic>?)
            ?.map((e) => MerchantReportSeries.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final txList = (json['transactions'] as List<dynamic>?)
            ?.map((e) => MerchantReportItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return MerchantReport(
      period: json['period'] as String? ?? 'day',
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      merchantBalance: (merchantMap['balance'] as num?)?.toDouble() ?? 0.0,
      summary: MerchantReportSummary.fromJson(summaryMap),
      series: seriesList,
      transactions: txList,
    );
  }
}
