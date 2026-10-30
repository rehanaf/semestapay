class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roles,
  });

  bool get isCashier => roles.contains('cashier') || roles.contains('super-admin');
  bool get isAdmin => roles.contains('admin') || roles.contains('super-admin');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
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
        'phone': phone,
        'roles': roles,
      };
}
