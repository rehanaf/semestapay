import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';

class PosState extends ChangeNotifier {
  final SemestaPayApiClient api = SemestaPayApiClient();

  User? _currentUser;
  String _outletCode = 'KANTIN-1';
  String _outletName = 'Kantin Utama';

  // POS transaction state
  final List<CartItem> _cartItems = [];
  double _manualAmount = 0.0;
  String _note = '';

  // Scanned student card
  CardReadResponse? _scannedCard;

  // Merchant profile & balance
  MerchantSummary? _merchantSummary;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String get outletCode => _outletCode;
  String get outletName => _outletName;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  double get manualAmount => _manualAmount;
  String get note => _note;
  CardReadResponse? get scannedCard => _scannedCard;
  MerchantSummary? get merchantSummary => _merchantSummary;

  double get cartTotal {
    double sum = 0.0;
    for (final ci in _cartItems) {
      sum += ci.subtotal;
    }
    return sum;
  }

  double get grandTotal {
    return cartTotal > 0 ? cartTotal : _manualAmount;
  }

  int get totalItemCount {
    int count = 0;
    for (final ci in _cartItems) {
      count += ci.quantity;
    }
    return count;
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void setOutlet(String code, String name) {
    _outletCode = code;
    _outletName = name;
    notifyListeners();
  }

  void setUser(User? user, String token) {
    _currentUser = user;
    api.setToken(token);
    notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<String> updateAvatar(String base64Image) async {
    final avatarUrl = await api.uploadUserAvatar(base64Image);
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        username: _currentUser!.username,
        phone: _currentUser!.phone,
        avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : _currentUser!.avatarUrl,
        merchantId: _currentUser!.merchantId,
        roles: _currentUser!.roles,
      );
      notifyListeners();
    }
    return avatarUrl;
  }

  Future<User> updateProfile({
    String? name,
    String? email,
    String? username,
    String? phone,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (username != null) payload['username'] = username;
    if (phone != null) payload['phone'] = phone;
    final updated = await api.updateUserProfile(payload);
    _currentUser = updated;
    notifyListeners();
    return updated;
  }

  Future<void> refreshUserProfile() async {
    try {
      final user = await api.getUserProfile();
      _currentUser = user;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshMerchantSummary() async {
    final summary = await api.getMerchantSummary();
    _merchantSummary = summary;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    api.clearToken();
    resetTransaction();
    notifyListeners();
  }

  // Cart operations
  void addItem(MerchantItem item) {
    final existingIndex = _cartItems.indexWhere((ci) => ci.item.id == item.id);
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += 1;
    } else {
      _cartItems.add(CartItem(item: item, quantity: 1));
    }
    _manualAmount = 0.0; // Clear manual if cart used
    notifyListeners();
  }

  void removeItem(MerchantItem item) {
    final existingIndex = _cartItems.indexWhere((ci) => ci.item.id == item.id);
    if (existingIndex >= 0) {
      if (_cartItems[existingIndex].quantity > 1) {
        _cartItems[existingIndex].quantity -= 1;
      } else {
        _cartItems.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void setManualAmount(double amount) {
    _manualAmount = amount;
    if (amount > 0) {
      _cartItems.clear(); // Clear items if manual used
    }
    notifyListeners();
  }

  void setNote(String n) {
    _note = n;
    notifyListeners();
  }

  void setScannedCard(CardReadResponse card) {
    _scannedCard = card;
    notifyListeners();
  }

  void resetTransaction() {
    _cartItems.clear();
    _manualAmount = 0.0;
    _note = '';
    _scannedCard = null;
    notifyListeners();
  }
}
