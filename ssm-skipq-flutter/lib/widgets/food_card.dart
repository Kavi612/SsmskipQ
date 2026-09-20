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
    this.isHighlyOrdered = false,
  });

  final MenuItem item;
  final bool orderingOpen;
  final bool isHighlyOrdered;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.getQuantity(item.id);
    final isNewlyAdded = DateTime.now().difference(item.createdAt).inDays <= 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = constraints.maxWidth.clamp(120.0, 170.0);

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: imageSize,
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: MenuItemImage(
                          item: item,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                        ),
                      ),
                    ),
                    if (isNewlyAdded || isHighlyOrdered)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isHighlyOrdered)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Highly Ordered',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            if (isHighlyOrdered && isNewlyAdded)
                              const SizedBox(width: 6),
                            if (isNewlyAdded)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        VegStatusBadge(isVeg: item.isVeg),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${item.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (!item.available)
                          const Text(
                            'Sold Out',
                            style: TextStyle(color: AppTheme.error, fontSize: 12),
                          )
                        else if (!orderingOpen)
                          const Text(
                            'Closed',
                            style:
                                TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          )
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
                              minimumSize: const Size(58, 30),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('ADD'),
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => cart.decrement(item.id),
                                icon: const Icon(Icons.remove_circle_outline),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                onPressed: () => cart.increment(item.id),
                                icon: const Icon(Icons.add_circle_outline),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
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
        );
      },
    );
  }
}
