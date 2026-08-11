import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../services/orders_service.dart';
import '../../widgets/app_scaffold.dart';

class StudentCheckoutScreen extends StatefulWidget {
  const StudentCheckoutScreen({super.key, required this.ordersService});

  final OrdersService ordersService;

  @override
  State<StudentCheckoutScreen> createState() => _StudentCheckoutScreenState();
}

class _StudentCheckoutScreenState extends State<StudentCheckoutScreen> {
  PaymentMethod _method = PaymentMethod.googlePay;
  bool _processing = false;
  String? _error;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    final isOnline = _method != PaymentMethod.payAtCounter;
    try {
      if (isOnline) {
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      }

      final order = await widget.ordersService.createOrder(
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
        paymentMethod: _method,
        paymentStatus:
            isOnline ? PaymentStatus.paid : PaymentStatus.pending,
      );

      cart.clear();
      if (mounted) {
        context.go('/student/order-confirmation', extra: order);
      }
    } catch (e) {
      setState(() => _error = 'Unable to place order. Please try again.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.items.isEmpty && !_processing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/student/cart');
      });
    }

    return AppScaffold(
      title: 'Checkout',
      showBack: true,
      backTo: '/student/cart',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Your Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('₹${cart.totalAmount}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.googlePay,
            groupValue: _method,
            onChanged: _processing ? null : (v) => setState(() => _method = v!),
            title: const Text('Pay Online'),
            subtitle: const Text('UPI · Cards · Net Banking (Mock)'),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.payAtCounter,
            groupValue: _method,
            onChanged: _processing ? null : (v) => setState(() => _method = v!),
            title: const Text('Pay at Counter'),
            subtitle: const Text('Pay when you collect your order'),
          ),
          if (_processing)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _processing ? null : _placeOrder,
            child: Text(_processing ? 'Please wait…' : 'PLACE ORDER'),
          ),
        ],
      ),
    );
  }
}
