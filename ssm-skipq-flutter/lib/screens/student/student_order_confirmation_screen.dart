import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_status_timeline.dart';

class StudentOrderConfirmationScreen extends StatefulWidget {
  const StudentOrderConfirmationScreen({
    super.key,
    required this.initialOrder,
    required this.ordersService,
    required this.socketService,
  });

  final Order initialOrder;
  final OrdersService ordersService;
  final SocketService socketService;

  @override
  State<StudentOrderConfirmationScreen> createState() =>
      _StudentOrderConfirmationScreenState();
}

class _StudentOrderConfirmationScreenState
    extends State<StudentOrderConfirmationScreen> {
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _refresh();
    widget.socketService.joinStudentRoom();
    widget.socketService.onOrderUpdated((updated) {
      if (updated.id == _order.id && mounted) {
        setState(() => _order = updated);
      }
    });
  }

  Future<void> _refresh() async {
    try {
      final orders = await widget.ordersService.fetchMyOrders();
      final latest = orders.where((o) => o.id == _order.id).firstOrNull;
      if (latest != null && mounted) setState(() => _order = latest);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Order',
      showBack: true,
      backTo: '/student',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Token Number', style: TextStyle(color: AppTheme.textSecondary)),
                Text(
                  _order.tokenNumber,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Order Placed'),
                        Text(formatIstTime(_order.createdAt)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Payment'),
                        Text(_order.paymentMethod.label),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          OrderStatusTimeline(status: _order.status),
          const SizedBox(height: 24),
          const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ..._order.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${item.name} × ${item.quantity}'),
              trailing: Text('₹${item.price * item.quantity}'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('₹${_order.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go('/student'),
            child: const Text('BACK TO HOME'),
          ),
        ],
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
