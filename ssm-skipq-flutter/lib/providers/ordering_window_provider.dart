import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/settings.dart';
import '../services/settings_service.dart';
import '../services/socket_service.dart';

class OrderingWindowProvider extends ChangeNotifier {
  OrderingWindowProvider({
    required SettingsService settingsService,
    required SocketService socketService,
  })  : _settings = settingsService,
        _socket = socketService;

  final SettingsService _settings;
  final SocketService _socket;
  Timer? _pollTimer;

  OrderingWindow _window = const OrderingWindow(
    orderingOpenTime: '09:30',
    orderingCloseTime: '11:30',
    isOpen: true,
  );
  bool _isLoading = true;

  OrderingWindow get window => _window;
  bool get isOpen => _window.isOpen;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    await refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());

    _socket.onOrderingWindow((data) {
      _window = data;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    try {
      _window = await _settings.fetchOrderingWindow();
    } catch (_) {
      _window = OrderingWindow(
        orderingOpenTime: _window.orderingOpenTime,
        orderingCloseTime: _window.orderingCloseTime,
        isOpen: false,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderingWindow> updateWindow(String open, String close) async {
    _window = await _settings.updateOrderingWindow(
      openTime: open,
      closeTime: close,
    );
    notifyListeners();
    return _window;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
