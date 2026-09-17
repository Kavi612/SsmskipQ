import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_status_timeline.dart';
import '../../widgets/student_bottom_navigation_bar.dart';

class StudentTrackOrderScreen extends StatefulWidget {
  const StudentTrackOrderScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    required this.ordersService,
    required this.socketService,
    this.showBottomNavigation = false,
  });

  final String orderId;
  final Order? initialOrder;
  final OrdersService ordersService;
  final SocketService socketService;
  final bool showBottomNavigation;

  @override
  State<StudentTrackOrderScreen> createState() => _StudentTrackOrderScreenState();
}

class _StudentTrackOrderScreenState extends State<StudentTrackOrderScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _loading = _order == null;
    _refresh();
    widget.socketService.joinStudentRoom();
    widget.socketService.onOrderUpdated(_handleOrderUpdated);
  }

  @override
  void dispose() {
    widget.socketService.off('order:updated');
    super.dispose();
  }

  void _handleOrderUpdated(Order updated) {
    if (updated.id == widget.orderId && mounted) {
      setState(() {
        _order = updated;
        _loading = false;
        _error = null;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final orders = await widget.ordersService.fetchMyOrders();
      final latest = orders.where((o) => o.id == widget.orderId).firstOrNull;
      if (!mounted) return;
      if (latest != null) {
        setState(() {
          _order = latest;
          _loading = false;
          _error = null;
        });
      } else if (_order == null) {
        setState(() {
          _loading = false;
          _error = 'Order not found.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (_order == null) {
        setState(() {
          _loading = false;
          _error = 'Unable to load order details.';
        });
      }
    }
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 'Your order has been received!';
      case OrderStatus.preparing:
        return 'The canteen is preparing your food.';
      case OrderStatus.ready:
        return 'Your order is ready! Please collect it from the counter using your token number.';
      case OrderStatus.pickedUp:
        return 'Order completed. Enjoy your meal!';
      case OrderStatus.cancelled:
        return 'This order has been cancelled.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Track Order',
        showBack: true,
        backTo: '/student',
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: widget.showBottomNavigation
            ? const StudentBottomNavigationBar(selectedIndex: 2)
            : null,
      );
    }

    if (_error != null || _order == null) {
      return AppScaffold(
        title: 'Track Order',
        showBack: true,
        backTo: '/student',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Order not found.'),
            ],
          ),
        ),
        bottomNavigationBar: widget.showBottomNavigation
            ? const StudentBottomNavigationBar(selectedIndex: 2)
            : null,
      );
    }

    final order = _order!;

    return AppScaffold(
      title: 'Track Order',
      showBack: true,
      backTo: '/student',
        bottomNavigationBar: widget.showBottomNavigation
          ? const StudentBottomNavigationBar(selectedIndex: 2)
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                children: [
                  const Text('Your Token Number', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    order.tokenNumber,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStatusMessage(order.status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              color: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 16),
                    OrderStatusTimeline(status: order.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              color: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...order.items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${item.name} × ${item.quantity}', style: const TextStyle(fontSize: 14)),
                        trailing: Text('₹${item.price * item.quantity}', style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('₹${order.total}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}