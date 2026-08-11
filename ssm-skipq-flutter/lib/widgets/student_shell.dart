import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/ordering_window_provider.dart';
import '../services/menu_service.dart';
import '../screens/student/student_cart_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/student/student_profile_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.menuService,
  });

  final MenuService menuService;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<OrderingWindowProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final tabs = [
      StudentHomeScreen(menuService: widget.menuService),
      const StudentCartScreen(),
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
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.totalItems > 0,
              label: Text('${cart.totalItems}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
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
