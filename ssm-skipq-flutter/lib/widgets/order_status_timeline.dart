import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.pending, 'Order Placed', Icons.receipt_long_outlined),
    (OrderStatus.preparing, 'Preparing', Icons.kitchen_outlined),
    (OrderStatus.ready, 'Ready for Pickup', Icons.restaurant_menu_outlined),
    (OrderStatus.pickedUp, 'Collected', Icons.check_circle_outline),
  ];

  int _rank(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.pickedUp:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _rank(status);

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isDone = status != OrderStatus.cancelled && current > index;
        final isCurrent = status != OrderStatus.cancelled && current == index;
        final isFuture = status != OrderStatus.cancelled && current < index;

        final contentColor = isDone || isCurrent ? AppTheme.primary : AppTheme.textMuted;
        final fillColor = isDone || isCurrent ? AppTheme.primaryMuted : AppTheme.gray100;
        final borderColor = isDone || isCurrent ? AppTheme.primary : AppTheme.border;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  step.$3,
                  color: contentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                        color: isFuture ? AppTheme.textMuted : AppTheme.text,
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: index < current ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
