import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/ordering_window_provider.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../utils/category_icons.dart';
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
  static const List<String> _greetingOptions = [
    'What are you craving today, [Name]?',
    'Hungry, [Name]? Let\'s fix that.',
    'What sounds good right now, [Name]?',
    'Craving something tasty, [Name]?',
    'Ready to munch, [Name]?',
    'Let\'s get you a great bite, [Name].',
    'What would hit the spot today, [Name]?',
    'Time for a tasty break, [Name]?',
    'What are you in the mood for, [Name]?',
    'Good food is calling, [Name].',
    'Hungry enough yet, [Name]?',
    'Your next favorite bite awaits, [Name].',
    'What sounds delicious today, [Name]?',
    'Let\'s make this meal count, [Name].',
    'Food mood check: what\'s it going to be, [Name]?',
  ];

  final ScrollController _categoryController = ScrollController();
  List<Category> _categories = [];
  List<MenuItem> _items = [];
  List<Order> _orderHistory = [];
  String? _selectedCategoryId;
  String _search = '';
  bool _pureVeg = false;
  bool _highlyOrdered = false;
  bool _newlyOrdered = false;
  String? _priceSort;
  bool _availableOnly = false;
  bool _loading = true;
  String? _error;
  late String _greetingText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _greetingText = _greetingOptions[Random().nextInt(_greetingOptions.length)];
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
    if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Category>;
        _items = results[1] as List<MenuItem>;
        _orderHistory = results[2] as List<Order>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load menu. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

  Set<String> get _topHighlyOrderedIds {
    final counts = _historicalOrderCounts;
    if (counts.isEmpty) return const {};

    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked.take(5).map((entry) => entry.key).toSet();
  }

  void _onFilterSelected(String value) {
    setState(() {
      switch (value) {
        case 'highlyOrdered':
          _highlyOrdered = !_highlyOrdered;
          break;
        case 'newlyAdded':
          _newlyOrdered = !_newlyOrdered;
          break;
        case 'priceLowToHigh':
          _priceSort = _priceSort == 'priceLowToHigh' ? null : 'priceLowToHigh';
          break;
        case 'priceHighToLow':
          _priceSort = _priceSort == 'priceHighToLow' ? null : 'priceHighToLow';
          break;
        case 'availableOnly':
          _availableOnly = !_availableOnly;
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

      const itemWidth = 98.0;
      final target = (index * itemWidth) - itemWidth;
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
    var result = List<MenuItem>.from(_items);

    if (_selectedCategoryId != null) {
      result =
          result.where((e) => e.categoryId == _selectedCategoryId).toList();
    }

    if (_pureVeg) {
      result = result.where((e) => e.isVeg).toList();
    }

    if (_availableOnly) {
      result = result.where((e) => e.available).toList();
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
    if (_newlyOrdered) {
      result = result.where((item) {
        final diff = DateTime.now().difference(item.createdAt).inDays;
        return diff <= 7;
      }).toList();
    }
    if (_priceSort == 'priceLowToHigh') {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (_priceSort == 'priceHighToLow') {
      result.sort((a, b) => b.price.compareTo(a.price));
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
    final cart = context.watch<CartProvider>();
    final firstName =
        user is StudentUser ? user.name.split(' ').first : 'Student';
    final greeting = _greetingText.replaceAll('[Name]', firstName);

    return Stack(
      fit: StackFit.expand,
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              cart.items.isEmpty ? 16 : 96,
            ),
            children: [
              Text(
                greeting,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
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
                    'Ordering is closed. Pre-book now and your order will enter the queue when ordering opens.',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search food...',
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    toggled: _pureVeg,
                    label: 'Veg only',
                    child: GestureDetector(
                      key: const ValueKey('veg-filter-toggle'),
                      onTap: () => setState(() => _pureVeg = !_pureVeg),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _pureVeg ? AppTheme.success : AppTheme.border,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 26,
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 36,
                                  height: 20,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: _pureVeg
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: AnimatedAlign(
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOut,
                                    alignment: _pureVeg
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.eco_rounded,
                                        size: 9,
                                        color: _pureVeg
                                            ? Colors.green
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Text(
                              'VEG',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                  key: const ValueKey('menu-filter-popup'),
                  tooltip: 'Filter menu',
                  onSelected: _onFilterSelected,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'highlyOrdered',
                      child: Row(
                        children: [
                          const Expanded(child: Text('Highly Ordered')),
                          if (_highlyOrdered) const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'newlyAdded',
                      child: Row(
                        children: [
                          const Expanded(child: Text('Newly Added')),
                          if (_newlyOrdered) const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'priceLowToHigh',
                      child: Row(
                        children: [
                          const Expanded(child: Text('Price: Low to High')),
                          if (_priceSort == 'priceLowToHigh')
                            const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'priceHighToLow',
                      child: Row(
                        children: [
                          const Expanded(child: Text('Price: High to Low')),
                          if (_priceSort == 'priceHighToLow')
                            const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'availableOnly',
                      child: Row(
                        children: [
                          const Expanded(child: Text('Currently Available')),
                          if (_availableOnly) const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                        Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
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
                  child:
                      Text('No menu items found.', textAlign: TextAlign.center),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 4,
                    mainAxisExtent: 214,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    return FoodCard(
                      item: item,
                      orderingOpen: ordering.isOpen,
                      isHighlyOrdered: _topHighlyOrderedIds.contains(item.id),
                    );
                  },
                ),
            ],
          ),
        ),
        if (cart.items.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Material(
              key: const ValueKey('floating-cart-bar'),
              color: AppTheme.primary,
              elevation: 8,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.go('/student?tab=cart'),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${cart.totalItems} ${cart.totalItems == 1 ? 'item' : 'items'}  •  ₹${cart.totalAmount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Text(
                        'View cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
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
