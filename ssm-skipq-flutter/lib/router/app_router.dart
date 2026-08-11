import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_services.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../screens/manager/manager_login_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/student/student_checkout_screen.dart';
import '../screens/student/student_login_screen.dart';
import '../screens/student/student_order_confirmation_screen.dart';
import '../widgets/manager_shell.dart';
import '../widgets/student_shell.dart';

GoRouter createRouter(AppServices services, AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoading) return null;

      final loc = state.matchedLocation;
      final isPublic = loc == '/' ||
          loc == '/student/login' ||
          loc == '/manager/login';

      if (auth.user == null && !isPublic) {
        return '/student/login';
      }
      if (auth.isStudent && loc.startsWith('/manager')) {
        return '/student';
      }
      if (auth.isManager && loc.startsWith('/student')) {
        return '/manager';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/student/login', builder: (_, __) => const StudentLoginScreen()),
      GoRoute(path: '/manager/login', builder: (_, __) => const ManagerLoginScreen()),
      GoRoute(
        path: '/student',
        builder: (_, __) => StudentShell(
          menuService: services.menuService,
        ),
      ),
      GoRoute(
        path: '/student/checkout',
        builder: (_, __) => StudentCheckoutScreen(ordersService: services.ordersService),
      ),
      GoRoute(
        path: '/student/order-confirmation',
        builder: (_, state) {
          final order = state.extra as Order?;
          if (order == null) {
            return const Scaffold(body: Center(child: Text('Order not found')));
          }
          return StudentOrderConfirmationScreen(
            initialOrder: order,
            ordersService: services.ordersService,
            socketService: services.socketService,
          );
        },
      ),
      GoRoute(
        path: '/manager',
        builder: (_, __) => ManagerShell(
          ordersService: services.ordersService,
          menuService: services.menuService,
          feedbackService: services.feedbackService,
          socketService: services.socketService,
        ),
      ),
    ],
  );
}
