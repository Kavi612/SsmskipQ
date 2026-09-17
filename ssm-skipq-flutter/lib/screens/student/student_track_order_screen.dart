import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_status_timeline.dart';

class StudentTrackOrderScreen extends StatefulWidget {
  const StudentTrackOrderScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    required this.ordersService,
    required this.socketService,
  });

  final String orderId;
  final Order? initialOrder;
  final OrdersService ordersService;
  final SocketService socketService;

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
      return const AppScaffold(
        title: 'Track Order',
        showBack: true,
        backTo: '/student',
        body: Center(child: CircularProgressIndicator()),
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
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/student'),
                child: const Text('BACK TO HOME'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return AppScaffold(
      title: 'Track Order',
      showBack: true,
      backTo: '/student',
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Token Number', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(
                    order.tokenNumber,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Order Placed', style: TextStyle(fontSize: 12)),
                          Text(formatIstTime(order.createdAt), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Payment', style: TextStyle(fontSize: 12)),
                          Text(order.paymentMethod.label, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: order.status == OrderStatus.ready
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusMessage(order.status),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            OrderStatusTimeline(status: order.status),
            const SizedBox(height: 16),
            const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/student'),
              child: const Text('BACK TO HOME', style: TextStyle(fontSize: 14)),
            ),
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