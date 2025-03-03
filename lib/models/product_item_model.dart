import 'package:flutter/material.dart';

class ProductItemModel extends ChangeNotifier {
  int _quantity;
  ProductItemModel(this._quantity);
  int get quantity => _quantity;
  void increment() {
    _quantity++;
    notifyListeners();
  }

  void decrement() {
    if (_quantity > 0) {
      _quantity--;
      notifyListeners();
    }
  }
}
