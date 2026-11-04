import 'user.dart';

class ParentChild {
  final int id;
  final String name;
  final String nis;
  final String status;
  final String? className;
  final double balance;
  final String? cardUid;

  ParentChild({
    required this.id,
    required this.name,
    required this.nis,
    required this.status,
    this.className,
    required this.balance,
    this.cardUid,
  });

  factory ParentChild.fromJson(Map<String, dynamic> json) {
    return ParentChild(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nis: json['nis'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      className: json['class'] as String? ?? json['class_name'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      cardUid: json['card_uid'] as String?,
    );
  }
}

class ParentAuthResponse {
  final String token;
  final User user;
  final List<ParentChild> children;

  ParentAuthResponse({
    required this.token,
    required this.user,
    required this.children,
  });

  factory ParentAuthResponse.fromJson(Map<String, dynamic> json) {
    final children = (json['children'] as List<dynamic>?)
            ?.map((e) => ParentChild.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ParentAuthResponse(
      token: json['token'] as String? ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      children: children,
    );
  }
}
