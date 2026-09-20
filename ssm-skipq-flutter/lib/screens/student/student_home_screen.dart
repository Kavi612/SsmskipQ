import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ordering_window_provider.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../utils/category_icons.dart';
import '../../utils/helpers.dart';
import '../../widgets/food_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.menuService,
    required this.ordersService,
    this.refreshToken = 0,
  });

  final MenuService menuService;
  final OrdersService ordersService;
  final int refreshToken;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with WidgetsBindingObserver {
  final ScrollController _categoryController = ScrollController();
  List<Category> _categories = [];
  List<MenuItem> _items = [];
  List<Order> _orderHistory = [];
  String? _selectedCategoryId;
  String _search = '';
  bool _vegOnly = false;
  bool _nonVegOnly = false;
  bool _highlyOrdered = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(covariant StudentHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.menuService.fetchCategories(),
        widget.menuService.fetchMenuItems(),
        widget.ordersService.fetchMyOrders(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _items = results[1] as List<MenuItem>;
        _orderHistory = results[2] as List<Order>;
      });
    } catch (_) {
      setState(() => _error = 'Unable to load menu. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, int> get _historicalOrderCounts {
    final counts = <String, int>{};
    for (final order in _orderHistory) {
      for (final item in order.items) {
        counts[item.menuItemId] =
            (counts[item.menuItemId] ?? 0) + item.quantity;
      }
    }
    return counts;
  }

  void _toggleFilter(String value) {
    setState(() {
      switch (value) {
        case 'veg':
          _vegOnly = !_vegOnly;
          if (_vegOnly) {
            _nonVegOnly = false;
          }
          break;
        case 'nonVeg':
          _nonVegOnly = !_nonVegOnly;
          if (_nonVegOnly) {
            _vegOnly = false;
          }
          break;
        case 'highlyOrdered':
          _highlyOrdered = !_highlyOrdered;
          break;
      }
    });
  }

  void _selectCategory(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_categoryController.hasClients) return;
      final index = categoryId == null
          ? 0
          : _categories.indexWhere((c) => c.id == categoryId);
      if (index < 0) return;
      const itemWidth = 92.0;
      final viewportWidth = _categoryController.position.viewportDimension;
      final target = (index * itemWidth + itemWidth / 2) - (viewportWidth / 2);
      final offset = target.clamp(
        _categoryController.position.minScrollExtent,
        _categoryController.position.maxScrollExtent,
      );
      _categoryController.animateTo(
        offset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  List<MenuItem> get _filtered {
    var result = _items;
    if (_selectedCategoryId != null) {
      result =
          result.where((e) => e.categoryId == _selectedCategoryId).toList();
    }
    if (_vegOnly) {
      result = result.where((e) => e.isVeg).toList();
    }
    if (_nonVegOnly) {
      result = result.where((e) => !e.isVeg).toList();
    }

    final orderCounts = _historicalOrderCounts;
    if (_highlyOrdered) {
      final rankedIds = orderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final ids = rankedIds.map((entry) => entry.key).toSet();
      result = result.where((e) => ids.contains(e.id)).toList();
      result.sort(
          (a, b) => (orderCounts[b.id] ?? 0).compareTo(orderCounts[a.id] ?? 0));
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              e.categoryName.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final ordering = context.watch<OrderingWindowProvider>();
    final firstName =
        user is StudentUser ? user.name.split(' ').first : 'Student';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${timeGreeting()}, $firstName',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const Text('What would you like to order today?',
              style: TextStyle(color: AppTheme.textSecondary)),
          if (!ordering.isOpen) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ordering is closed. Please visit the canteen directly.',
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search food...',
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.builder(
              controller: _categoryController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CategoryCard(
                    name: 'All',
                    icon: Icons.restaurant_menu,
                    isSelected: _selectedCategoryId == null,
                    onTap: () => _selectCategory(null),
                  );
                }
                final category = _categories[index - 1];
                return _CategoryCard(
                  name: category.name,
                  icon: _iconForCategory(category.icon),
                  isSelected: _selectedCategoryId == category.id,
                  onTap: () => _selectCategory(category.id),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<String>(
              tooltip: 'Filter menu',
              onSelected: _toggleFilter,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'veg',
                  child: Row(
                    children: [
                      const Expanded(child: Text('Veg Only')),
                      if (_vegOnly) const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'nonVeg',
                  child: Row(
                    children: [
                      const Expanded(child: Text('Non-Veg Only')),
                      if (_nonVegOnly) const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'highlyOrdered',
                  child: Row(
                    children: [
                      const Expanded(child: Text('Highly Ordered')),
                      if (_highlyOrdered) const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppTheme.bgSubtle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppTheme.border),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Filter',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(width: 6),
                    Icon(Icons.tune, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Today's Menu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (_filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No menu items found.', textAlign: TextAlign.center),
            )
          else
            ..._filtered.map(
              (item) => FoodCard(item: item, orderingOpen: ordering.isOpen),
            ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String? iconKey) {
    return CategoryIcons.resolve(iconKey);
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryMuted : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.35)
                : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
