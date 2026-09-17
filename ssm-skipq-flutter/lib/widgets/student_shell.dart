import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/ordering_window_provider.dart';
import '../services/menu_service.dart';
import '../services/orders_service.dart';
import '../services/socket_service.dart';
import '../screens/student/student_cart_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/student/student_track_order_list_screen.dart';
import '../screens/student/student_profile_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.menuService,
    required this.ordersService,
    required this.socketService,
    this.initialTab = 0,
  });

  final MenuService menuService;
  final OrdersService ordersService;
  final SocketService socketService;
  final int initialTab;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  late int _index;
  int _homeRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 3);
    context.read<OrderingWindowProvider>().initialize();
  }

  @override
  void didUpdateWidget(covariant StudentShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _index = widget.initialTab.clamp(0, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final tabs = [
      StudentHomeScreen(
        menuService: widget.menuService,
        refreshToken: _homeRefreshToken,
      ),
      const StudentCartScreen(),
      StudentTrackOrderListScreen(
        ordersService: widget.ordersService,
        socketService: widget.socketService,
      ),
      const StudentProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkipQ · Pre-Order · Pick Up'),
        centerTitle: true,
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          if (i == 0) _homeRefreshToken++;
        }),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _CartNavigationIcon(
              itemCount: cart.totalItems,
              selected: false,
            ),
            selectedIcon: _CartNavigationIcon(
              itemCount: cart.totalItems,
              selected: true,
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Track Order',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CartNavigationIcon extends StatelessWidget {
  const _CartNavigationIcon({
    required this.itemCount,
    required this.selected,
  });

  final int itemCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: itemCount > 0,
      label: Text(itemCount > 99 ? '99+' : '$itemCount'),
      child: Icon(
        selected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      ),
    );
  }
}
