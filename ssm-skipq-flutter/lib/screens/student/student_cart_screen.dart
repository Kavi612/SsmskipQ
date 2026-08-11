import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_scaffold.dart';

class StudentCartScreen extends StatelessWidget {
  const StudentCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) {
      return AppScaffold(
        title: 'Your Cart',
        showBack: true,
        backTo: '/student',
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          message: 'Browse the menu and add your favourite dishes to get started.',
          actionLabel: 'Browse Menu',
          onAction: () => context.go('/student'),
        ),
      );
    }

    return AppScaffold(
      title: 'Your Cart',
      showBack: true,
      backTo: '/student',
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item.imageUrl,
                                width: 48, height: 48, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.restaurant),
                    title: Text(item.name),
                    subtitle: Text('₹${item.price} each'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => cart.decrement(item.menuItemId),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          onPressed: () => cart.increment(item.menuItemId),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('₹${cart.totalAmount}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/student/checkout'),
                    child: const Text('PROCEED TO CHECKOUT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
