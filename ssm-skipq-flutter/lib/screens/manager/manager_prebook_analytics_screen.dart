import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../models/prebook_analytics.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/category_icons.dart';
import '../../utils/helpers.dart';
import '../../widgets/menu_item_image.dart';

class ManagerPrebookAnalyticsScreen extends StatefulWidget {
  const ManagerPrebookAnalyticsScreen({
    super.key,
    required this.ordersService,
    required this.socketService,
    required this.menuService,
    this.refreshKey = 0,
  });

  final OrdersService ordersService;
  final SocketService socketService;
  final MenuService menuService;
  final int refreshKey;

  @override
  State<ManagerPrebookAnalyticsScreen> createState() =>
      _ManagerPrebookAnalyticsScreenState();
}

class _ManagerPrebookAnalyticsScreenState
    extends State<ManagerPrebookAnalyticsScreen> {
  List<Category> _categories = [];
  List<PrebookAnalyticsCategory> _demand = [];
  List<MenuItem> _menuItems = [];
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String? _selectedCategoryId;
  int _selectedTab = 0;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
    widget.socketService.joinManagerRoom();
    widget.socketService.onOrderCreated(_handleOrderCreated);
    widget.socketService.onOrderUpdated(_handleOrderUpdated);
  }

  @override
  void didUpdateWidget(covariant ManagerPrebookAnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) _load();
  }

  void _handleOrderCreated(Order order) {
    if (order.status == OrderStatus.preBooked) _load();
  }

  void _handleOrderUpdated(Order _) => _load();

  @override
  void dispose() {
    widget.socketService.off('order:created');
    widget.socketService.off('order:updated');
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<Object>([
        widget.menuService.fetchManagerMenu(),
        widget.ordersService.fetchPrebookAnalytics(),
        widget.ordersService.fetchManagerOrders(),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      final menu =
          results[0] as ({List<Category> categories, List<MenuItem> items});
      setState(() {
        _categories = menu.categories;
        _demand = results[1] as List<PrebookAnalyticsCategory>;
        _menuItems = menu.items;
        _orders = results[2] as List<Order>;
        if (_selectedCategoryId != null &&
            !menu.categories
                .any((category) => category.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = 'Unable to load pre-book demand.';
        _loading = false;
      });
    }
  }

  int _countForCategory(String categoryId) {
    for (final category in _demand) {
      if (category.id == categoryId) return category.totalQuantity;
    }
    return 0;
  }

  PrebookAnalyticsCategory? _demandForCategory(String categoryId) {
    for (final category in _demand) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  MenuItem? _menuItemForId(String id) {
    for (final item in _menuItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<PrebookAnalyticsItem> get _allDemandItems {
    final items = _demand
        .expand((category) => category.items)
        .where((item) => item.quantity > 0)
        .toList();
    items.sort((a, b) {
      final quantityOrder = b.quantity.compareTo(a.quantity);
      return quantityOrder != 0 ? quantityOrder : a.name.compareTo(b.name);
    });
    return items;
  }

  List<Order> get _todayPrebookOrders => _orders
      .where((order) =>
          order.status == OrderStatus.preBooked && isTodayIst(order.createdAt))
      .toList();

  int get _todayPrebookItemCount => _todayPrebookOrders.fold<int>(
        0,
        (total, order) =>
            total +
            order.items.fold<int>(0, (sum, item) => sum + item.quantity),
      );

  ({String name, int orderCount})? get _mostPrebookedItemToday {
    final orderCounts = <String, int>{};
    for (final order in _todayPrebookOrders) {
      for (final item in order.items) {
        orderCounts.update(item.name, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    if (orderCounts.isEmpty) return null;
    final mostOrdered = orderCounts.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );
    return (name: mostOrdered.key, orderCount: mostOrdered.value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _categories
        .where((category) => category.id == _selectedCategoryId)
        .firstOrNull;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tabBar(),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (_selectedTab == 1 && _categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No menu categories are available.'),
            )
          else if (_selectedTab == 0)
            _foodItems()
          else if (_selectedTab == 1 && selected != null) ...[
            Row(
              children: [
                IconButton(
                  tooltip: 'Back to categories',
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
                Text(
                  '${_countForCategory(selected.id)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            _categoryItems(selected),
          ] else if (_selectedTab == 1)
            _categoryGrid()
          else
            _summary(),
        ],
      ),
    );
  }

  Widget _tabBar() {
    const tabs = ['Food Items', 'Categories', 'Summary'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: selected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  key: ValueKey('prebook-tab-$index'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() {
                    _selectedTab = index;
                    if (index != 1) _selectedCategoryId = null;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Text(
                      tabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _foodItems() {
    final items = _allDemandItems;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No pre-booked items yet.'),
      );
    }
    return Column(
      children: items
          .map((item) => _prebookItemRow(item, itemCountLabel: 'pre-booked'))
          .toList(),
    );
  }

  Widget _summary() {
    final mostOrdered = _mostPrebookedItemToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryStat(
                'Pre-booked orders today',
                '${_todayPrebookOrders.length}',
                Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryStat(
                'Items pre-booked today',
                '$_todayPrebookItemCount',
                Icons.restaurant_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: AppTheme.primaryMuted,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.star_outline,
                    color: AppTheme.primary, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: mostOrdered == null
                      ? const Text(
                          'No pre-booked items today yet.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        )
                      : Text(
                          '${mostOrdered.name} is your most pre-booked item '
                          'today — ${mostOrdered.orderCount} '
                          '${mostOrdered.orderCount == 1 ? 'order' : 'orders'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryStat(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final count = _countForCategory(category.id);
        return Card(
          key: ValueKey('prebook-category-${category.id}'),
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selectedCategoryId = category.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        CategoryIcons.resolve(category.icon),
                        color: AppTheme.primary,
                        size: 28,
                      ),
                      Positioned(
                        top: -10,
                        right: -14,
                        child: Container(
                          key: ValueKey('prebook-count-${category.id}'),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.surface,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryItems(Category category) {
    final demand = _demandForCategory(category.id);
    final items = demand?.items.toList() ?? <PrebookAnalyticsItem>[];
    items.sort((a, b) => b.quantity.compareTo(a.quantity));
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No pre-booked items in this category.'),
      );
    }

    return Column(
      children: items
          .map((item) => _prebookItemRow(item, itemCountLabel: 'pre-booked'))
          .toList(),
    );
  }

  Widget _prebookItemRow(
    PrebookAnalyticsItem item, {
    required String itemCountLabel,
  }) {
    final menuItem = _menuItemForId(item.id);

    return Card(
      key: ValueKey('prebook-item-${item.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: menuItem == null
                  ? Container(
                      width: 56,
                      height: 56,
                      color: AppTheme.bgSubtle,
                      child: const Icon(
                        Icons.restaurant,
                        size: 28,
                        color: AppTheme.textMuted,
                      ),
                    )
                  : MenuItemImage(
                      item: menuItem,
                      width: 56,
                      height: 56,
                      borderRadius: 8,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.quantity}',
                  key: ValueKey('prebook-item-count-${item.id}'),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  itemCountLabel,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
