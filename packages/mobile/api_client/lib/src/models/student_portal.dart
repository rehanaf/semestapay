class StudentProfile {
  final int id;
  final String name;
  final String nis;
  final String? username;
  final String? email;
  final String? className;
  final String? cardUid;
  final String? cardStatus;
  final String status;
  final double balance;
  final String currency;
  final String? walletStatus;
  final double dailyLimit;
  final String? avatarUrl;
  final String? nik;
  final String? gender;
  final String? birthDate;
  final String? address;
  final String? phoneParent;
  final String? parentName;
  final String? parentEmail;
  final String? balanceUpdatedAt;

  StudentProfile({
    required this.id,
    required this.name,
    required this.nis,
    this.username,
    this.email,
    this.className,
    this.cardUid,
    this.cardStatus,
    required this.status,
    required this.balance,
    required this.currency,
    this.walletStatus,
    required this.dailyLimit,
    this.avatarUrl,
    this.nik,
    this.gender,
    this.birthDate,
    this.address,
    this.phoneParent,
    this.parentName,
    this.parentEmail,
    this.balanceUpdatedAt,
  });

  bool get isActive => status == 'active';

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nis: json['nis'] as String? ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      className: json['class'] as String? ?? json['class_name'] as String?,
      cardUid: json['card_uid'] as String?,
      cardStatus: json['card_status'] as String?,
      status: json['status'] as String? ?? 'active',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'IDR',
      walletStatus: json['wallet_status'] as String?,
      dailyLimit: (json['daily_limit'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: json['avatar_url'] as String?,
      nik: json['nik'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] as String?,
      address: json['address'] as String?,
      phoneParent: json['phone_parent'] as String?,
      parentName: json['parent_name'] as String?,
      parentEmail: json['parent_email'] as String?,
      balanceUpdatedAt: json['balance_updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nis': nis,
        'username': username,
        'email': email,
        'class': className,
        'card_uid': cardUid,
        'card_status': cardStatus,
        'status': status,
        'balance': balance,
        'currency': currency,
        'wallet_status': walletStatus,
        'daily_limit': dailyLimit,
        'avatar_url': avatarUrl,
        'nik': nik,
        'gender': gender,
        'birth_date': birthDate,
        'address': address,
        'phone_parent': phoneParent,
        'parent_name': parentName,
        'parent_email': parentEmail,
        'balance_updated_at': balanceUpdatedAt,
      };
}

class StudentMutation {
  final String id;
  final String type;
  final String direction;
  final double amount;
  final double? balanceAfter;
  final String status;
  final String? merchant;
  final String? outlet;
  final String? note;
  final String? createdAt;

  StudentMutation({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    this.balanceAfter,
    required this.status,
    this.merchant,
    this.outlet,
    this.note,
    this.createdAt,
  });

  bool get isCredit => direction == 'credit';

  factory StudentMutation.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final rawType = json['type'] as String? ?? 'payment';
    final creditTypes = ['topup', 'reversal', 'adjustment'];
    final direction = json['direction'] as String? ??
        (creditTypes.contains(rawType) ? 'credit' : 'debit');

    return StudentMutation(
      id: rawId,
      type: rawType,
      direction: direction,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'posted',
      merchant: json['merchant'] as String?,
      outlet: json['outlet'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class StudentBill {
  final int id;
  final String type;
  final String? period;
  final String? description;
  final double amount;
  final double paidAmount;
  final String? dueDate;
  final String status;

  StudentBill({
    required this.id,
    required this.type,
    this.period,
    this.description,
    required this.amount,
    required this.paidAmount,
    this.dueDate,
    required this.status,
  });

  double get remainingAmount {
    final remaining = amount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isPaid => status == 'paid';

  factory StudentBill.fromJson(Map<String, dynamic> json) {
    return StudentBill(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'tagihan',
      period: json['period'] as String?,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String? ?? 'unpaid',
    );
  }
}

class StudentDashboard {
  final StudentProfile student;
  final double dailyUsed;
  final double remainingDailyLimit;
  final List<StudentMutation> recentTransactions;
  final List<StudentBill> bills;

  StudentDashboard({
    required this.student,
    required this.dailyUsed,
    required this.remainingDailyLimit,
    required this.recentTransactions,
    required this.bills,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) parser) {
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(parser)
          .toList();
    }

    return StudentDashboard(
      student: StudentProfile.fromJson(
        json['student'] as Map<String, dynamic>? ?? {},
      ),
      dailyUsed: (json['daily_used'] as num?)?.toDouble() ?? 0.0,
      remainingDailyLimit:
          (json['remaining_daily_limit'] as num?)?.toDouble() ?? 0.0,
      recentTransactions: parseList(
        json['recent_transactions'],
        StudentMutation.fromJson,
      ),
      bills: parseList(json['bills'], StudentBill.fromJson),
    );
  }
}

class StudentAuthResponse {
  final String token;
  final StudentProfile student;

  StudentAuthResponse({required this.token, required this.student});

  factory StudentAuthResponse.fromJson(Map<String, dynamic> json) {
    return StudentAuthResponse(
      token: json['token'] as String? ?? '',
      student: StudentProfile.fromJson(
        json['student'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class WalletSummary {
  final int studentId;
  final double balance;
  final String currency;
  final String status;

  WalletSummary({
    required this.studentId,
    required this.balance,
    required this.currency,
    required this.status,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      studentId: json['student_id'] as int? ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'IDR',
      status: json['status'] as String? ?? 'active',
    );
  }
}
