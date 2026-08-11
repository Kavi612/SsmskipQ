import 'package:flutter/material.dart';

import '../services/feedback_service.dart';
import '../services/menu_service.dart';
import '../services/orders_service.dart';
import '../services/socket_service.dart';
import '../screens/manager/manager_dashboard_screen.dart';
import '../screens/manager/manager_feedback_screen.dart';
import '../screens/manager/manager_menu_screen.dart';
import '../screens/manager/manager_orders_screen.dart';
import '../screens/manager/manager_profile_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({
    super.key,
    required this.ordersService,
    required this.menuService,
    required this.feedbackService,
    required this.socketService,
  });

  final OrdersService ordersService;
  final MenuService menuService;
  final FeedbackService feedbackService;
  final SocketService socketService;

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ManagerDashboardScreen(
        ordersService: widget.ordersService,
        socketService: widget.socketService,
      ),
      ManagerOrdersScreen(
        ordersService: widget.ordersService,
        socketService: widget.socketService,
      ),
      ManagerMenuScreen(menuService: widget.menuService),
      ManagerFeedbackScreen(feedbackService: widget.feedbackService),
      const ManagerProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manager Portal')),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.message_outlined), selectedIcon: Icon(Icons.message), label: 'Feedback'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
