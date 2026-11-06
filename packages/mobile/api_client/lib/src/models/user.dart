class User {
  final int id;
  final String name;
  final String email;
  final String? username;
  final String? phone;
  final String? avatarUrl;
  final int? merchantId;
  final List<String> roles;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.phone,
    this.avatarUrl,
    this.merchantId,
    required this.roles,
  });

  bool get isCashier =>
      roles.contains('cashier') || roles.contains('super-admin');
  bool get isAdmin => roles.contains('admin') || roles.contains('super-admin');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      merchantId: json['merchant_id'] as int?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'phone': phone,
        'avatar_url': avatarUrl,
        'merchant_id': merchantId,
        'roles': roles,
      };
}
