import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../services/super_admin_service.dart';
import '../../widgets/analytics_category_bar_chart.dart';
import '../../widgets/menu_item_image.dart';
import 'super_admin_date_filter.dart';

class SuperAdminPrebookAnalyticsScreen extends StatefulWidget {
  const SuperAdminPrebookAnalyticsScreen({
    super.key,
    required this.superAdminService,
    this.initialSelection,
  });

  final SuperAdminService superAdminService;
  final SuperAdminDateFilterSelection? initialSelection;

  @override
  State<SuperAdminPrebookAnalyticsScreen> createState() =>
      _SuperAdminPrebookAnalyticsScreenState();
}

class _SuperAdminPrebookAnalyticsScreenState
    extends State<SuperAdminPrebookAnalyticsScreen> {
  List<Order> _orders = [];
  List<MenuItem> _menuItems = [];
  List<Category> _categories = [];
  late SuperAdminDateFilterSelection _selection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selection = widget.initialSelection ??
        SuperAdminDateFilterSelection(
          period: SuperAdminAnalyticsPeriod.day,
          label: DateFormat('d MMM yyyy').format(now),
          range: DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day + 1),
          ),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.superAdminService.fetchOrders(),
        widget.superAdminService.fetchMenuItems(),
        widget.superAdminService.fetchCategories(),
      ]);
      _orders = results[0] as List<Order>;
      _menuItems = results[1] as List<MenuItem>;
      _categories = results[2] as List<Category>;
    } catch (_) {
      _error = 'Unable to load pre-book analytics data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _periodPrebookOrders => _orders.where((order) {
        final isPrebook =
            order.isPreBook || order.status == OrderStatus.preBooked;
        return isPrebook &&
            !order.createdAt.isBefore(_selection.range.start) &&
            order.createdAt.isBefore(_selection.range.end);
      }).toList();

  @override
  Widget build(BuildContext context) {
    final orders = _periodPrebookOrders;
    final totalItems = orders.fold<int>(
      0,
      (total, order) =>
          total + order.items.fold<int>(0, (sum, item) => sum + item.quantity),
    );
    final rankedItems = _rankedItems(orders);

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-book Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SuperAdminDateFilter(
              initialSelection: _selection,
              onChanged: (selection) => setState(() => _selection = selection),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppTheme.error))
            else ...[
              _statCards(orders.length, totalItems),
              const SizedBox(height: 16),
              _categoryChart(orders),
              const SizedBox(height: 16),
              _topItems(rankedItems),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCards(int totalOrders, int totalItems) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Total Pre-booked Orders',
            '$totalOrders',
            Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'Total Pre-booked Items',
            '$totalItems',
            Icons.fastfood_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _categoryChart(List<Order> orders) {
    final quantities = <String, int>{
      for (final category in _categories) category.id: 0,
    };
    final menuItemsById = {
      for (final item in _menuItems) item.id: item,
    };

    for (final order in orders) {
      for (final line in order.items) {
        final item = menuItemsById[line.menuItemId];
        final category = _categories
            .where((category) =>
                category.id == item?.categoryId ||
                category.name == item?.categoryName)
            .firstOrNull;
        if (category != null) {
          quantities[category.id] =
              (quantities[category.id] ?? 0) + line.quantity;
        }
      }
    }

    final categories = _categories
        .map((category) =>
            AnalyticsCategoryBar(category.name, quantities[category.id] ?? 0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return AnalyticsCategoryBarChart(
      title: 'Pre-booked Items by Category',
      subtitle: _selection.label,
      unitLabel: 'items',
      categories: categories,
    );
  }

  List<_RankedPrebookItem> _rankedItems(List<Order> orders) {
    final quantities = <String, int>{};
    final names = <String, String>{};
    for (final order in orders) {
      for (final item in order.items) {
        final itemId = item.menuItemId.isEmpty ? item.name : item.menuItemId;
        quantities[itemId] = (quantities[itemId] ?? 0) + item.quantity;
        names[itemId] = item.name;
      }
    }

    final ranked = quantities.entries
        .map((entry) => _RankedPrebookItem(
              entry.key,
              names[entry.key] ?? 'Unknown item',
              entry.value,
            ))
        .toList()
      ..sort((a, b) {
        final byQuantity = b.quantity.compareTo(a.quantity);
        return byQuantity != 0 ? byQuantity : a.name.compareTo(b.name);
      });
    return ranked;
  }

  Widget _topItems(List<_RankedPrebookItem> ranked) {
    final menuItemsById = {
      for (final item in _menuItems) item.id: item,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Pre-booked Items',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (ranked.isEmpty)
              const Text('No pre-booked items for this period.')
            else
              ...ranked.take(5).map((entry) {
                final menuItem = menuItemsById[entry.id];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: menuItem == null
                      ? const Icon(Icons.restaurant_menu)
                      : MenuItemImage(item: menuItem, width: 46, height: 46),
                  title: Text(entry.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Quantity Pre-booked'),
                  trailing: Text('${entry.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RankedPrebookItem {
  const _RankedPrebookItem(this.id, this.name, this.quantity);

  final String id;
  final String name;
  final int quantity;
}
