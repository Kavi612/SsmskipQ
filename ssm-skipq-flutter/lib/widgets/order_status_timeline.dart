import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.confirmed, 'Accepted'),
    (OrderStatus.ready, 'Ready for Pickup'),
  ];

  int _rank(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.pickedUp:
        return 3;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _rank(status);
    return Column(
      children: _steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final stepRank = _rank(step.$1);
        final isComplete = status != OrderStatus.cancelled &&
            status != OrderStatus.pending &&
            current >= stepRank;
        final isCurrent = status != OrderStatus.cancelled &&
            status != OrderStatus.pickedUp &&
            ((status == OrderStatus.pending && index == 0) ||
                current == stepRank);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isComplete || isCurrent
                        ? AppTheme.primary
                        : AppTheme.border,
                    shape: BoxShape.circle,
                  ),
                  child: isComplete
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (index < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isComplete ? AppTheme.primary : AppTheme.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.$2,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isComplete || isCurrent
                            ? AppTheme.text
                            : AppTheme.textMuted,
                      ),
                    ),
                    if (index == 0 && status == OrderStatus.pending)
                      const Text(
                        'Waiting for acceptance',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
