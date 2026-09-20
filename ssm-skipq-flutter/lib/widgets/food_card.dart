import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/menu.dart';
import '../providers/cart_provider.dart';
import 'menu_item_image.dart';
import 'veg_status_badge.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.orderingOpen,
  });

  final MenuItem item;
  final bool orderingOpen;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.getQuantity(item.id);
    final isNewlyAdded = DateTime.now().difference(item.createdAt).inDays <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuItemImage(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isNewlyAdded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMuted,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.25)),
                          ),
                          child: const Text(
                            'Newly added',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      VegStatusBadge(isVeg: item.isVeg),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item.price}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (!item.available)
                        const Text('Sold Out',
                            style: TextStyle(color: AppTheme.error))
                      else if (!orderingOpen)
                        const Text('Closed',
                            style: TextStyle(color: AppTheme.textMuted))
                      else if (qty == 0)
                        FilledButton(
                          onPressed: () => cart.addItem(
                            menuItemId: item.id,
                            name: item.name,
                            price: item.price,
                            imageUrl: item.imageUrl,
                            isVeg: item.isVeg,
                            available: item.available,
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(72, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('ADD'),
                        )
                      else
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => cart.decrement(item.id),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            IconButton(
                              onPressed: () => cart.increment(item.id),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
