class StudentListItem {
  final int id;
  final String nis;
  final String name;
  final String? className;
  final String? cardUid;
  final String? cardStatus;
  final String status;

  StudentListItem({
    required this.id,
    required this.nis,
    required this.name,
    this.className,
    this.cardUid,
    this.cardStatus,
    required this.status,
  });

  bool get hasActiveCard =>
      cardUid != null &&
      cardUid!.isNotEmpty &&
      cardStatus == 'active' &&
      status == 'active';

  factory StudentListItem.fromJson(Map<String, dynamic> json) {
    return StudentListItem(
      id: json['id'] as int? ?? 0,
      nis: json['nis'] as String? ?? '',
      name: json['name'] as String? ?? '',
      className: json['class_name'] as String? ?? json['class'] as String?,
      cardUid: json['card_uid'] as String?,
      cardStatus: json['card_status'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}
