import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../models/prebook_analytics.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';

class ManagerPrebookAnalyticsScreen extends StatefulWidget {
  const ManagerPrebookAnalyticsScreen({
    super.key,
    required this.ordersService,
    required this.socketService,
  });

  final OrdersService ordersService;
  final SocketService socketService;

  @override
  State<ManagerPrebookAnalyticsScreen> createState() =>
      _ManagerPrebookAnalyticsScreenState();
}

class _ManagerPrebookAnalyticsScreenState
    extends State<ManagerPrebookAnalyticsScreen> {
  List<PrebookAnalyticsCategory> _categories = [];
  bool _loading = true;
  String? _error;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _load();
    widget.socketService.joinManagerRoom();
    widget.socketService.onOrderCreated((order) {
      if (order.status == OrderStatus.preBooked) _load();
    });
    widget.socketService.onOrderUpdated((_) => _load());
  }

  @override
  void dispose() {
    widget.socketService.off('order:created');
    widget.socketService.off('order:updated');
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final categories = await widget.ordersService.fetchPrebookAnalytics();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (_selectedCategoryId != null &&
            !categories.any((category) => category.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load pre-book demand.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _categories
        .where((category) => category.id == _selectedCategoryId)
        .firstOrNull;
    final maxQuantity = _categories.fold<int>(
      0,
      (maximum, category) =>
          category.totalQuantity > maximum ? category.totalQuantity : maximum,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (selected != null)
            Row(
              children: [
                IconButton(
                  tooltip: 'All categories',
                  onPressed: () => setState(() => _selectedCategoryId = null),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    selected.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${selected.totalQuantity}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            )
          else ...[
            const Text(
              'Pre-book Demand',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Current closed-period totals',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (selected != null)
            if (selected.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No pre-booked items in this category.'),
              )
            else
              ...selected.items.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.name),
                    trailing: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              )
          else if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No pre-booked orders in the current period.'),
            )
          else
            ..._categories.map(
              (category) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () =>
                      setState(() => _selectedCategoryId = category.id),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${category.totalQuantity} pre-booked',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: maxQuantity == 0
                              ? 0
                              : category.totalQuantity / maxQuantity,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}