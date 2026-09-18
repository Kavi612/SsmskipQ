import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ordering_window_provider.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/order_status_badge.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({
    super.key,
    required this.ordersService,
    required this.socketService,
  });

  final OrdersService ordersService;
  final SocketService socketService;

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  List<Order> _orders = [];
  bool _loadingOrders = true;
  final _openController = TextEditingController(text: '09:30');
  final _closeController = TextEditingController(text: '11:30');
  bool _savingWindow = false;
  String? _settingsMsg;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    widget.socketService.joinManagerRoom();
    widget.socketService.onOrderCreated(_upsertOrder);
    widget.socketService.onOrderUpdated(_upsertOrder);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final window = context.read<OrderingWindowProvider>().window;
      _openController.text = window.orderingOpenTime;
      _closeController.text = window.orderingCloseTime;
    });
  }

  void _upsertOrder(Order order) {
    setState(() {
      final idx = _orders.indexWhere((o) => o.id == order.id);
      if (idx >= 0) {
        _orders[idx] = order;
      } else {
        _orders.insert(0, order);
      }
    });
  }

  Future<void> _loadOrders() async {
    try {
      _orders = await widget.ordersService.fetchManagerOrders();
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _saveWindow() async {
    setState(() {
      _savingWindow = true;
      _settingsMsg = null;
    });
    try {
      await context.read<OrderingWindowProvider>().updateWindow(
            _openController.text,
            _closeController.text,
          );
      setState(() => _settingsMsg = 'Ordering window updated.');
    } catch (_) {
      setState(() => _settingsMsg = 'Unable to save settings.');
    } finally {
      setState(() => _savingWindow = false);
    }
  }

  @override
  void dispose() {
    _openController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final window = context.watch<OrderingWindowProvider>();
    final firstName = auth.user?.name.split(' ').first ?? 'Manager';
    final todayOrders = _orders.where((o) => isTodayIst(o.createdAt)).toList();
    final pending = todayOrders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.preparing)
        .length;
    final ready = todayOrders.where((o) => o.status == OrderStatus.ready).length;
    final revenue = todayOrders.fold<num>(0, (sum, o) => sum + o.total);

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hello, $firstName 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const Text("Here's what's happening today."),
          const SizedBox(height: 16),
          if (_loadingOrders)
            const Center(child: CircularProgressIndicator())
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _statCard('Total Orders', '${todayOrders.length}'),
                _statCard('Pending', '$pending'),
                _statCard('Ready', '$ready'),
                _statCard('Revenue', '₹$revenue', highlight: true),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ordering Window',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  Text(
                    'Currently: ${window.isOpen ? 'Open' : 'Closed'}',
                    style: TextStyle(
                      color: window.isOpen ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _openController,
                          decoration: const InputDecoration(labelText: 'Open'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _closeController,
                          decoration: const InputDecoration(labelText: 'Close'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _savingWindow ? null : _saveWindow,
                    child: Text(_savingWindow ? 'Saving…' : 'Save'),
                  ),
                  if (_settingsMsg != null) Text(_settingsMsg!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          if (todayOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Live orders will appear here as students place them.'),
            )
          else
            ...todayOrders.take(5).map(
                  (order) => Card(
                    child: ListTile(
                      title: Text('${order.tokenNumber} · ${order.student?.name ?? 'Student'}'),
                      subtitle: Text('${order.items.length} items · ${formatIstTime(order.createdAt)}'),
                      trailing: OrderStatusBadge(status: order.status),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/manager/orders'),
            child: const Text('VIEW ALL ORDERS'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.primaryMuted : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

}
