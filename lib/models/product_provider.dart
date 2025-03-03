import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  final Map<String, int> _quantities = {};

  void setQuantity(String productId, int quantity) {
    _quantities[productId] = quantity;
    notifyListeners();
  }

  int getQuantity(String productId) {
    return _quantities[productId] ?? 0;
  }

  void clearQuantities() {
    _quantities.clear();
    notifyListeners();
  }
}
