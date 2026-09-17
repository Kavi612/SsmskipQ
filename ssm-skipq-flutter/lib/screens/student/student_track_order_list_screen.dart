import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_status_timeline.dart';

class StudentTrackOrderListScreen extends StatefulWidget {
  const StudentTrackOrderListScreen({
    super.key,
    required this.ordersService,
    required this.socketService,
  });

  final OrdersService ordersService;
  final SocketService socketService;

  @override
  State<StudentTrackOrderListScreen> createState() => _StudentTrackOrderListScreenState();
}

class _StudentTrackOrderListScreenState extends State<StudentTrackOrderListScreen> {
  bool _loading = true;
  String? _error;
  Order? _activeOrder;

  @override
  void initState() {
    super.initState();
    _load();
    widget.socketService.joinStudentRoom();
    widget.socketService.onOrderUpdated((order) {
      if (mounted && _activeOrder != null && order.id == _activeOrder!.id) {
        setState(() {
          _activeOrder = order;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.socketService.off('order:updated');
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allOrders = await widget.ordersService.fetchMyOrders();
      final activeOrders = allOrders.where((order) =>
        order.status != OrderStatus.pickedUp &&
        order.status != OrderStatus.cancelled
      ).toList();
      
      if (mounted) {
        setState(() {
          _activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load orders.';
          _loading = false;
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
    return AppScaffold(
      title: 'Track Order',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _activeOrder != null
                  ? RefreshIndicator(
                      onRefresh: _load,
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
                                  _activeOrder!.tokenNumber,
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
                                        Text(formatIstTime(_activeOrder!.createdAt), style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text('Payment', style: TextStyle(fontSize: 12)),
                                        Text(_activeOrder!.paymentMethod.label, style: const TextStyle(fontSize: 12)),
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
                              color: _activeOrder!.status == OrderStatus.ready
                                  ? AppTheme.success.withValues(alpha: 0.15)
                                  : AppTheme.primaryMuted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusMessage(_activeOrder!.status),
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
                          OrderStatusTimeline(status: _activeOrder!.status),
                          const SizedBox(height: 16),
                          const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ..._activeOrder!.items.map(
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
                              Text('₹${_activeOrder!.total}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textMuted),
                          SizedBox(height: 16),
                          Text(
                            'No active orders',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Place an order to track it here',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
    );
  }
}