import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/super_admin_service.dart';
import '../../services/orders_service.dart';
import '../../services/feedback_service.dart';
import '../../services/menu_service.dart';
import 'super_admin_analytics_detail_screen.dart';
import 'super_admin_date_filter.dart';
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
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final pages = [
      SuperAdminDashboardScreen(
        ordersService: widget.ordersService,
        feedbackService: widget.feedbackService,
        superAdminService: widget.superAdminService,
        menuService: widget.menuService,
      ),
      SuperAdminAnalyticsDetailScreen(
        title: 'Order Analytics',
        filter: SuperAdminDateFilterSelection(
          period: SuperAdminAnalyticsPeriod.day,
          label: DateFormat('d MMM yyyy').format(todayStart),
          range: DateTimeRange(
            start: todayStart,
            end: todayStart.add(const Duration(days: 1)),
          ),
        ),
        ordersService: widget.ordersService,
        menuService: widget.menuService,
        feedbackService: widget.feedbackService,
        superAdminService: widget.superAdminService,
      ),
      SuperAdminAnalyticsDetailScreen(
        title: 'Feedback Analytics',
        filter: SuperAdminDateFilterSelection(
          period: SuperAdminAnalyticsPeriod.year,
          label: '${now.year}',
          range: DateTimeRange(
            start: DateTime(now.year),
            end: DateTime(now.year + 1),
          ),
        ),
        ordersService: widget.ordersService,
        menuService: widget.menuService,
        feedbackService: widget.feedbackService,
        superAdminService: widget.superAdminService,
      ),
      SuperAdminAnalyticsDetailScreen(
        title: 'Cancellation Analytics',
        filter: SuperAdminDateFilterSelection(
          period: SuperAdminAnalyticsPeriod.year,
          label: '${now.year}',
          range: DateTimeRange(
            start: DateTime(now.year),
            end: DateTime(now.year + 1),
          ),
        ),
        ordersService: widget.ordersService,
        menuService: widget.menuService,
        feedbackService: widget.feedbackService,
        superAdminService: widget.superAdminService,
      ),
      SuperAdminAnalyticsDetailScreen(
        title: 'Revenue Analytics',
        filter: SuperAdminDateFilterSelection(
          period: SuperAdminAnalyticsPeriod.year,
          label: '${now.year}',
          range: DateTimeRange(
            start: DateTime(now.year),
            end: DateTime(now.year + 1),
          ),
        ),
        ordersService: widget.ordersService,
        menuService: widget.menuService,
        feedbackService: widget.feedbackService,
        superAdminService: widget.superAdminService,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Portal'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _SuperAdminProfileScreen()),
            ),
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
              icon: Icon(Icons.cancel_outlined),
              selectedIcon: Icon(Icons.cancel),
              label: 'Cancellation'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Revenue'),
        ],
      ),
    );
  }
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
