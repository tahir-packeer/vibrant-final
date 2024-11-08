import 'dart:async';

class CartService {
  final _cartCountController = StreamController<int>.broadcast();
  Stream<int> get cartCount => _cartCountController.stream;

  void updateCartCount(int count) {
    _cartCountController.add(count);
  }

  void dispose() {
    _cartCountController.close();
  }
}

final cartService = CartService();
