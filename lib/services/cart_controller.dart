import 'package:flutter/material.dart';

import '../models/order.dart';

class CartController extends ChangeNotifier {
  final List<OrderItem> _items = [];

  List<OrderItem> get items => List.unmodifiable(_items);

  bool addItem(OrderItem item) {
    final index =
        _items.indexWhere((existing) => existing.productId == item.productId);
    if (index == -1) {
      _items.add(item);
      notifyListeners();
      return true;
    } else {
      final existing = _items[index];
      _items[index] = OrderItem(
        productId: existing.productId,
        name: existing.name,
        qty: existing.qty + item.qty,
        price: existing.price,
      );
    }
    notifyListeners();
    return false;
  }

  void updateQty(String productId, int qty) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index == -1) {
      return;
    }
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      final item = _items[index];
      _items[index] = OrderItem(
        productId: item.productId,
        name: item.name,
        qty: qty,
        price: item.price,
      );
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  num get totalPrice {
    return _items.fold<num>(
      0,
      (sum, item) => sum + (item.price * item.qty),
    );
  }

  int get totalItems {
    return _items.fold<int>(0, (sum, item) => sum + item.qty);
  }
}
