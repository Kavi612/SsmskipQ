import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ordering_window_provider.dart';
import '../../services/menu_service.dart';
import '../../utils/category_icons.dart';
import '../../utils/helpers.dart';
import '../../widgets/food_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.menuService,
    this.refreshToken = 0,
  });

  final MenuService menuService;
  final int refreshToken;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
  with WidgetsBindingObserver {
  List<Category> _categories = [];
  List<MenuItem> _items = [];
  String? _selectedCategoryId;
  String _search = '';
  bool _showVegOnly = false;
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
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _items = results[1] as List<MenuItem>;
      });
    } catch (_) {
      setState(() => _error = 'Unable to load menu. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<MenuItem> get _filtered {
    var result = _items;
    if (_selectedCategoryId != null) {
      result =
          result.where((e) => e.categoryId == _selectedCategoryId).toList();
    }
    if (_showVegOnly) {
      result = result.where((e) => e.isVeg).toList();
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Center(
                  child: Icon(Icons.circle, color: Colors.white, size: 7),
                ),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: _showVegOnly,
                onChanged: (value) => setState(() => _showVegOnly = value),
                activeTrackColor: Colors.green,
                activeThumbColor: Colors.white,
                inactiveTrackColor: Colors.white,
                inactiveThumbColor: AppTheme.textMuted,
                trackOutlineColor:
                  const WidgetStatePropertyAll(AppTheme.border),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryCard(
                  name: 'All',
                  icon: Icons.restaurant_menu,
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() => _selectedCategoryId = null),
                ),
                ..._categories.map(
                  (cat) => _CategoryCard(
                    name: cat.name,
                    icon: _iconForCategory(cat.icon),
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                  ),
                ),
              ],
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
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
