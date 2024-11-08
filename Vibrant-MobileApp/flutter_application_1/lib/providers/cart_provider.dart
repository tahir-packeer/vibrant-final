import 'package:flutter/foundation.dart';

class CartProvider with ChangeNotifier {
  int _cartCount = 0;

  int get cartCount => _cartCount;

  void updateCartCount(int count) {
    _cartCount = count;
    notifyListeners();
  }
}
