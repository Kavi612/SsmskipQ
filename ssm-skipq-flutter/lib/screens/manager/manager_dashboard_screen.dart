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
    final pending = todayOrders.where((o) => o.status == OrderStatus.pending).length;
    final completed = todayOrders.where((o) => o.status == OrderStatus.pickedUp).length;
    final cancelled = todayOrders.where((o) => o.status == OrderStatus.cancelled).length;
    final recentOrders = List<Order>.of(todayOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _greetingCard(firstName),
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
              childAspectRatio: 1.18,
              children: [
                _statCard('Total Orders', '${todayOrders.length}', Icons.assignment_outlined, AppTheme.primary),
                _statCard('Pending', '$pending', Icons.schedule_outlined, AppTheme.primary),
                _statCard('Completed', '$completed', Icons.check_circle_outline, AppTheme.success),
                _statCard('Cancelled', '$cancelled', Icons.close_rounded, AppTheme.error),
              ],
            ),
          const SizedBox(height: 16),
          _orderingWindowCard(window),
          const SizedBox(height: 16),
          const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 10),
          if (recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Live orders will appear here as students place them.'),
            )
          else
            ...recentOrders.take(5).map(_recentOrderRow),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/manager/orders'),
            child: const Text('VIEW ALL ORDERS'),
          ),
        ],
      ),
    );
  }

  Widget _greetingCard(String firstName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppTheme.primaryMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $firstName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text("Here's what's happening today.", style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.room_service_outlined, color: AppTheme.primary, size: 38),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _orderingWindowCard(OrderingWindowProvider window) {
    final statusColor = window.isOpen ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Ordering Window', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Currently: ${window.isOpen ? 'Open' : 'Closed'}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _timeField(_openController, 'Open', Icons.wb_sunny_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _timeField(_closeController, 'Close', Icons.nightlight_outlined)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingWindow ? null : _saveWindow,
              child: Text(_savingWindow ? 'Saving...' : 'Save'),
            ),
          ),
          if (_settingsMsg != null) ...[
            const SizedBox(height: 8),
            Text(_settingsMsg!, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _timeField(TextEditingController controller, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _recentOrderRow(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text('${order.tokenNumber} · ${order.student?.name ?? 'Student'}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${order.items.length} items · ${formatIstTime(order.createdAt)}', style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OrderStatusBadge(status: order.status),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
        onTap: () => context.go('/manager/orders'),
      ),
    );
  }

}
