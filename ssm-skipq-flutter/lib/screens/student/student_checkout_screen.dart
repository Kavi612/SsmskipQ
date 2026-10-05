import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/orders_service.dart';
import '../../widgets/app_scaffold.dart';

class StudentCheckoutScreen extends StatefulWidget {
  const StudentCheckoutScreen({
    super.key,
    required this.ordersService,
  });

  final OrdersService ordersService;

  @override
  State<StudentCheckoutScreen> createState() => _StudentCheckoutScreenState();
}

class _StudentCheckoutScreenState extends State<StudentCheckoutScreen> {
  bool _processing = false;
  bool _orderPlaced = false;
  String? _error;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user is! StudentUser) {
      setState(() => _error = 'Please log in as a student to place an order.');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final result = await widget.ordersService.createOrder(
        items: cart.items
            .map(
              (item) => OrderItem(
                menuItemId: item.menuItemId,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
              ),
            )
            .toList(),
        total: cart.totalAmount,
        isPreBook: cart.isPreBook,
        note: cart.note,
      );

      if (mounted) {
        setState(() => _orderPlaced = true);
        cart.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.order.status == OrderStatus.preBooked
                ? 'Pre-book placed successfully'
                : 'Order placed successfully'),
          ),
        );
        context.go(
          '/student/track-order/${result.order.id}',
          extra: result.order,
        );
      }
    } catch (e) {
      setState(() {
        _error = e is String
            ? e
            : context.read<AuthProvider>().messageFromError(
                  e,
                  fallback: 'Unable to place order. Please try again.',
                );
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.items.isEmpty && !_processing && !_orderPlaced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/student');
      });
    }

    return AppScaffold(
      title: 'Checkout',
      showBack: true,
      backTo: '/student?tab=cart',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Your Order',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ...cart.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('× ${item.quantity}'),
              trailing: Text('₹${item.price * item.quantity}'),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text(
                '₹${cart.totalAmount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment will be requested after the canteen accepts your order.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          if (_processing)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child:
                  Text(_error!, style: const TextStyle(color: AppTheme.error)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _processing ? null : _placeOrder,
            child: Text(
              _processing
                  ? 'Please wait…'
                  : cart.isPreBook
                      ? 'Confirm Pre-book'
                      : 'PLACE ORDER',
            ),
          ),
        ],
      ),
    );
  }
}
