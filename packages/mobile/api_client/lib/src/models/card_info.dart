class CardInfo {
  final String uid;
  final String status;

  CardInfo({required this.uid, required this.status});

  factory CardInfo.fromJson(Map<String, dynamic> json) {
    return CardInfo(
      uid: json['uid'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
    );
  }
}

class StudentInfo {
  final int id;
  final String name;
  final String nis;
  final String status;
  final String? className;

  StudentInfo({
    required this.id,
    required this.name,
    required this.nis,
    required this.status,
    this.className,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nis: json['nis'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
      className: json['class'] as String?,
    );
  }
}

class WalletInfo {
  final double balance;
  final String status;

  WalletInfo({required this.balance, required this.status});

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'inactive',
    );
  }
}

class CardReadResponse {
  final CardInfo card;
  final StudentInfo student;
  final WalletInfo wallet;
  final double dailyUsed;
  final double dailyLimit;

  CardReadResponse({
    required this.card,
    required this.student,
    required this.wallet,
    required this.dailyUsed,
    required this.dailyLimit,
  });

  double get remainingDailyLimit {
    if (dailyLimit <= 0) return wallet.balance;
    final remaining = dailyLimit - dailyUsed;
    return remaining < 0 ? 0.0 : remaining;
  }

  bool get isUsable =>
      card.status == 'active' &&
      student.status == 'active' &&
      wallet.status == 'active';

  factory CardReadResponse.fromJson(Map<String, dynamic> json) {
    return CardReadResponse(
      card: CardInfo.fromJson(json['card'] as Map<String, dynamic>? ?? {}),
      student:
          StudentInfo.fromJson(json['student'] as Map<String, dynamic>? ?? {}),
      wallet:
          WalletInfo.fromJson(json['wallet'] as Map<String, dynamic>? ?? {}),
      dailyUsed: (json['daily_used'] as num?)?.toDouble() ?? 0.0,
      dailyLimit: (json['daily_limit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
