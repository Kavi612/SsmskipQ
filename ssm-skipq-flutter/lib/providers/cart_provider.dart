import 'package:flutter/foundation.dart';

import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String _note = '';
  bool? _isPreBook;

  List<CartItem> get items => List.unmodifiable(_items);
  String get note => _note;
  bool get isPreBook => _isPreBook ?? false;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  num get totalAmount =>
      _items.fold<num>(0, (sum, item) => sum + item.price * item.quantity);

  void setNote(String value) {
    final next = value.trim();
    if (_note == next) return;
    _note = next;
    notifyListeners();
  }

  void updateAvailability(Map<String, bool> availabilityById) {
    var changed = false;
    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      final available = availabilityById[item.menuItemId] ?? false;
      if (item.available != available) {
        _items[index] = item.copyWith(available: available);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  int getQuantity(String menuItemId) {
    return _items
            .firstWhere(
              (item) => item.menuItemId == menuItemId,
              orElse: () => const CartItem(
                menuItemId: '',
                name: '',
                price: 0,
                quantity: 0,
                imageUrl: '',
                isVeg: true,
                available: true,
              ),
            )
            .quantity;
  }

  int getQuantityForMode(String menuItemId, {required bool isPreBook}) =>
      _isPreBook == isPreBook ? getQuantity(menuItemId) : 0;

  bool addItem({
    required String menuItemId,
    required String name,
    required num price,
    required String imageUrl,
    required bool isVeg,
    required bool available,
    bool isPreBook = false,
    String categoryId = '',
    String categoryName = '',
  }) {
    if (!_canAdd(isPreBook)) return false;
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    } else {
      _items.add(
        CartItem(
          menuItemId: menuItemId,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
          isVeg: isVeg,
          available: available,
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  void addItemWithQuantity({
    required String menuItemId,
    required String name,
    required num price,
    required String imageUrl,
    required bool isVeg,
    required bool available,
    required int quantity,
    String categoryId = '',
    String categoryName = '',
  }) {
    if (quantity < 1) return;
    if (!_canAdd(false)) return;
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + quantity,
      );
    } else {
      _items.add(
        CartItem(
          menuItemId: menuItemId,
          name: name,
          price: price,
          quantity: quantity,
          imageUrl: imageUrl,
          isVeg: isVeg,
          available: available,
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      );
    }
    notifyListeners();
  }

  void increment(String menuItemId) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
      notifyListeners();
    }
  }

  void decrement(String menuItemId) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index < 0) return;
    final next = _items[index].quantity - 1;
    if (next <= 0) {
      _items.removeAt(index);
      if (_items.isEmpty) _isPreBook = null;
    } else {
      _items[index] = _items[index].copyWith(quantity: next);
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.removeWhere((e) => e.menuItemId == menuItemId);
    if (_items.isEmpty) _isPreBook = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _note = '';
    _isPreBook = null;
    notifyListeners();
  }

  bool _canAdd(bool isPreBook) {
    if (_items.isNotEmpty && _isPreBook != isPreBook) return false;
    _isPreBook ??= isPreBook;
    return true;
  }
}
