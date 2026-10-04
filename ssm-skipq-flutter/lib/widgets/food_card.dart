import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu.dart';
import '../providers/cart_provider.dart';
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
    final isPreBook = !orderingOpen;
    final quantity = cart.getQuantityForMode(item.id, isPreBook: isPreBook);
    final vegBadge = VegStatusBadge(isVeg: item.isVeg);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEE6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: item.available ? 1 : 0.55,
                  child: SizedBox(
                    height: 112,
                    width: double.infinity,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF7E1D2),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 36,
                            color: Color(0xFFB86A3D),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (isHighlyOrdered)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
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
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              vegBadge,
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹${item.price}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF111827),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: item.available
                      ? const Color(0xFFFE4101)
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: !item.available
                    ? Semantics(
                        button: true,
                        enabled: false,
                        label: 'Sold Out',
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 7,
                          ),
                          child: Text(
                            'Sold Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : quantity == 0
                        ? GestureDetector(
                            onTap: () {
                              final added = cart.addItem(
                                menuItemId: item.id,
                                name: item.name,
                                price: item.price,
                                imageUrl: item.imageUrl,
                                isVeg: item.isVeg,
                                available: item.available,
                                isPreBook: isPreBook,
                                categoryId: item.categoryId,
                                categoryName: item.categoryName,
                              );
                              if (!added) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Clear your current cart before starting a pre-book or regular order.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isPreBook ? 8 : 12,
                                vertical: 7,
                              ),
                              child: isPreBook
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.schedule, size: 13,
                                            color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Pre-book',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'ADD',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QuantityButton(
                                icon: Icons.remove,
                                onTap: () => cart.decrement(item.id),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                onTap: () => cart.increment(item.id),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
