import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.preBooked, 'Pre-booked', Icons.schedule_outlined),
    (OrderStatus.pending, 'Pending', Icons.receipt_long_outlined),
    (OrderStatus.confirmed, 'Accepted', Icons.check_circle_outline),
    (OrderStatus.active, 'Preparing', Icons.kitchen_outlined),
    (OrderStatus.pickedUp, 'Completed', Icons.restaurant_menu_outlined),
  ];

  int _rank(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 1;
      case OrderStatus.confirmed:
        return 2;
      case OrderStatus.active:
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return 3;
      case OrderStatus.pickedUp:
        return 4;
      case OrderStatus.preBooked:
        return 0;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _rank(status);
    final isCancelled = status == OrderStatus.cancelled;

    return SizedBox(
      height: 86,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepWidth = constraints.maxWidth / _steps.length;
          final progress = current < 0 ? 0.0 : current / (_steps.length - 1);
          final progressWidth = constraints.maxWidth - stepWidth;

          return Stack(
            children: [
              Positioned(
                top: 19,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Container(height: 3, color: AppTheme.border),
              ),
              if (!isCancelled && progress > 0)
                Positioned(
                  top: 19,
                  left: stepWidth / 2,
                  child: Container(
                    width: progressWidth * progress,
                    height: 3,
                    color: AppTheme.primary,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_steps.length, (index) {
                  final step = _steps[index];
                  final isDone = !isCancelled && current > index;
                  final isCurrent = !isCancelled && current == index;
                  final isFuture = isCancelled || current < index;
                  final contentColor = isDone
                      ? Colors.white
                      : isCurrent
                          ? AppTheme.primaryActive
                          : AppTheme.textMuted;
                  final fillColor = isDone
                      ? AppTheme.primary
                      : isCurrent
                          ? AppTheme.primaryMuted
                          : AppTheme.gray100;
                  final borderColor =
                      isDone || isCurrent ? AppTheme.primary : AppTheme.border;
                  final state = isDone
                      ? 'completed'
                      : isCurrent
                          ? 'current'
                          : 'future';

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          key:
                              ValueKey('order-status-step-${step.$1.apiValue}'),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: fillColor,
                            border: Border.all(
                              color: borderColor,
                              width: isCurrent ? 3 : 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Semantics(
                            label: '${step.$2}, $state',
                            child: Icon(step.$3, color: contentColor, size: 19),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.$2,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: isFuture
                                ? AppTheme.textMuted
                                : isCurrent
                                    ? AppTheme.primaryActive
                                    : AppTheme.text,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
