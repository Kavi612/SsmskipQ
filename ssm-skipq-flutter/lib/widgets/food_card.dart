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
    final isNewlyAdded = DateTime.now().difference(item.createdAt).inDays <= 7;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: MenuItemImage(
                  item: item,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 0,
                ),
              ),
              if (isNewlyAdded)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text(
                      'Newly added',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    VegStatusBadge(isVeg: item.isVeg),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₹${item.price}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (item.available && orderingOpen)
                      ElevatedButton(
                        onPressed: () => cart.addItem(
                          menuItemId: item.id,
                          name: item.name,
                          price: item.price,
                          imageUrl: item.imageUrl,
                          isVeg: item.isVeg,
                          available: item.available,
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(58, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('ADD'),
                      )
                    else if (!item.available)
                      const Text(
                        'Sold Out',
                        style: TextStyle(color: AppTheme.error, fontSize: 12),
                      )
                    else
                      const Text(
                        'Closed',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
