import 'package:flutter/material.dart';

import '../../services/super_admin_service.dart';
import '../../services/orders_service.dart';
import '../../services/feedback_service.dart';
import '../../services/menu_service.dart';
import 'super_admin_dashboard_screen.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({
    super.key,
    required this.superAdminService,
    required this.ordersService,
    required this.feedbackService,
    required this.menuService,
  });

  final SuperAdminService superAdminService;
  final OrdersService ordersService;
  final FeedbackService feedbackService;
  final MenuService menuService;

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      SuperAdminDashboardScreen(
        ordersService: widget.ordersService,
        feedbackService: widget.feedbackService,
        superAdminService: widget.superAdminService,
        menuService: widget.menuService,
      ),
      const _SuperAdminPlaceholder(title: 'Orders'),
      const _SuperAdminPlaceholder(title: 'Feedback'),
      const _SuperAdminPlaceholder(title: 'Revenue'),
      const _SuperAdminProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Portal'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => setState(() => _index = 4),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: 'Feedback'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Revenue'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _SuperAdminPlaceholder extends StatelessWidget {
  const _SuperAdminPlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: Text('$title analytics will be available soon.',
            style: const TextStyle(color: Colors.grey)),
      );
}

class _SuperAdminProfileScreen extends StatelessWidget {
  const _SuperAdminProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text('Super Admin'),
              subtitle: Text('superadmin'),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
