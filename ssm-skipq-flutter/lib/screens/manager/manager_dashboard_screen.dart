import 'package:flutter/material.dart';
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
    required this.onViewOrders,
    this.refreshKey = 0,
  });

  final OrdersService ordersService;
  final SocketService socketService;
  final VoidCallback onViewOrders;
  final int refreshKey;

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  List<Order> _orders = [];
  bool _loadingOrders = true;
  String? _ordersError;
  final Map<String, Order> _liveOrderUpdates = {};
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
      _openController.text = _displayTime(window.orderingOpenTime);
      _closeController.text = _displayTime(window.orderingCloseTime);
    });
  }

  @override
  void didUpdateWidget(covariant ManagerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) _loadOrders();
  }

  void _upsertOrder(Order order) {
    if (!mounted) return;
    _liveOrderUpdates[order.id] = order;
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
      final fetched = await widget.ordersService.fetchManagerOrders();
      final ordersById = {for (final order in fetched) order.id: order};
      ordersById.addAll(_liveOrderUpdates);
      if (!mounted) return;
      setState(() {
        _orders = ordersById.values.toList();
        _ordersError = null;
        _loadingOrders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ordersError = 'Unable to load orders. Pull down to retry.';
        _loadingOrders = false;
      });
    }
  }

  Future<void> _saveWindow() async {
    setState(() {
      _savingWindow = true;
      _settingsMsg = null;
    });
    try {
      await context.read<OrderingWindowProvider>().updateWindow(
            _apiTime(_openController.text),
            _apiTime(_closeController.text),
          );
      setState(() => _settingsMsg = 'Ordering window updated.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordering window updated')),
        );
      }
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
    final preBooked =
        todayOrders.where((o) => o.status == OrderStatus.preBooked).length;
    final pending =
        todayOrders.where((o) => o.status == OrderStatus.pending).length;
    final completed =
        todayOrders.where((o) => o.status == OrderStatus.pickedUp).length;
    final cancelled =
        todayOrders.where((o) => o.status == OrderStatus.cancelled).length;
    final recentOrders = List<Order>.of(todayOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _greetingCard(firstName, todayOrders.length),
          const SizedBox(height: 16),
          if (_loadingOrders)
            const Center(child: CircularProgressIndicator())
          else if (_ordersError != null && _orders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_ordersError!,
                  style: const TextStyle(color: AppTheme.error)),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.18,
              children: [
                _statCard('Pre-booked', '$preBooked', Icons.schedule_outlined,
                    AppTheme.primary),
                _statCard('Pending', '$pending', Icons.schedule_outlined,
                    AppTheme.primary),
                _statCard('Completed', '$completed', Icons.check_circle_outline,
                    AppTheme.success),
                _statCard('Cancelled', '$cancelled', Icons.close_rounded,
                    AppTheme.error),
              ],
            ),
          const SizedBox(height: 16),
          _orderingWindowCard(window),
          const SizedBox(height: 16),
          const Text('Recent Orders',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 10),
          if (_ordersError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_ordersError!,
                  style: const TextStyle(color: AppTheme.error)),
            ),
          if (_loadingOrders && recentOrders.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child:
                  Text('Live orders will appear here as students place them.'),
            )
          else
            ...recentOrders.take(5).map(_recentOrderRow),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: widget.onViewOrders,
            child: const Text('VIEW ALL ORDERS'),
          ),
        ],
      ),
    );
  }

  Widget _greetingCard(String firstName, int totalOrdersToday) {
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
                Text('Hello, $firstName',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text("Here's what's happening today.",
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Total Orders Today: ',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextSpan(
                        text: '$totalOrdersToday',
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  key: const ValueKey('dashboard-total-orders-today'),
                ),
              ],
            ),
          ),
          const Icon(Icons.room_service_outlined,
              color: AppTheme.primary, size: 38),
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
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              key: ValueKey('dashboard-stat-${label.toLowerCase()}-count'),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
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
              Text('Ordering Window',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Currently: ${window.isOpen ? 'Open' : 'Closed'}',
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _timeField(_openController, 'Open')),
              const SizedBox(width: 10),
              Expanded(child: _timeField(_closeController, 'Close')),
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
            Text(_settingsMsg!,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _timeField(TextEditingController controller, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pickTime(controller, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 6),
                Text(controller.text,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(TextEditingController controller, String label) async {
    final initialTime = _parseTime(controller.text) ?? TimeOfDay.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select $label time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() => controller.text = selected.format(context));
    }
  }

  TimeOfDay? _parseTime(String value) {
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false)
            .firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _displayTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return value;
    final hour = int.parse(match.group(1)!);
    final meridiem = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${displayHour.toString().padLeft(2, '0')}:${match.group(2)} $meridiem';
  }

  String _apiTime(String value) {
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false)
            .firstMatch(value.trim());
    if (match == null) return value.trim();
    var hour = int.parse(match.group(1)!);
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${match.group(2)}';
  }

  Widget _recentOrderRow(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(
            '${order.tokenNumber} · ${order.student?.name ?? 'Student'}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
              '${order.items.length} items · ${formatIstTime(order.createdAt)}',
              style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OrderStatusBadge(status: order.status),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
        onTap: widget.onViewOrders,
      ),
    );
  }
}
