class MerchantItem {
  final int id;
  final int merchantId;
  final String merchantName;
  final String name;
  final double price;
  final String status;

  MerchantItem({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.name,
    required this.price,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory MerchantItem.fromJson(Map<String, dynamic> json) {
    return MerchantItem(
      id: json['id'] as int? ?? 0,
      merchantId: json['merchant_id'] as int? ?? 0,
      merchantName: json['merchant_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class CartItem {
  final MerchantItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get subtotal => item.price * quantity;
}
