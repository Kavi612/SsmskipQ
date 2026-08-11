import 'package:flutter/material.dart';

import '../config/assets.dart';

class FoodCollage extends StatefulWidget {
  const FoodCollage({super.key});

  @override
  State<FoodCollage> createState() => _FoodCollageState();
}

class _FoodCollageState extends State<FoodCollage>
    with TickerProviderStateMixin {
  static const _foods = [
    _FoodItem(AppAssets.collageFood1, -3, 0.0, 5.2, 1),
    _FoodItem(AppAssets.collageFood2, 2, 0.8, 5.9, 3),
    _FoodItem(AppAssets.collageFood3, -2, 1.6, 6.3, 2),
    _FoodItem(AppAssets.collageFood4, 3, 2.4, 5.6, 4),
  ];

  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _foods
        .map(
          (food) => AnimationController(
            vsync: this,
            duration: Duration(milliseconds: (food.duration * 1000).round()),
          )..repeat(reverse: true),
        )
        .toList();

    for (var i = 0; i < _foods.length; i++) {
      if (_foods[i].delay > 0) {
        Future.delayed(Duration(milliseconds: (_foods[i].delay * 1000).round()),
            () {
          if (mounted) _controllers[i].forward(from: 0);
        });
      } else {
        _controllers[i].forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = (MediaQuery.sizeOf(context).width * 0.21).clamp(76.0, 104.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _foods.length; i++)
            AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, child) {
                final y = Tween<double>(begin: 0, end: -8)
                    .animate(CurvedAnimation(
                      parent: _controllers[i],
                      curve: Curves.easeInOut,
                    ))
                    .value;
                return Transform.translate(
                  offset: Offset(0, y),
                  child: child,
                );
              },
              child: Transform.rotate(
                angle: _foods[i].rotate * 3.1415926535 / 180,
                child: Container(
                  width: itemWidth,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : -itemWidth * 0.28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _foods[i].asset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FoodItem {
  const _FoodItem(this.asset, this.rotate, this.delay, this.duration, this.zIndex);

  final String asset;
  final double rotate;
  final double delay;
  final double duration;
  final int zIndex;
}
