import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';

class AnalyticsCategoryBar {
  const AnalyticsCategoryBar(this.label, this.value);

  final String label;
  final int value;
}

class AnalyticsCategoryBarChart extends StatelessWidget {
  const AnalyticsCategoryBarChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.unitLabel,
    required this.categories,
  });

  final String title;
  final String subtitle;
  final String unitLabel;
  final List<AnalyticsCategoryBar> categories;

  @override
  Widget build(BuildContext context) {
    final chartMax =
        _chartScaleMax(categories.map((category) => category.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: categories.map((category) {
                    final height = category.value == 0
                        ? 2.0
                        : 150 * category.value / chartMax;
                    return Tooltip(
                      message: '${category.value} $unitLabel',
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: categories.length > 8 ? 52 : 68,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(height: 150 - height),
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(category.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Text('Scale: 0 - $chartMax $unitLabel',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

int _chartScaleMax(Iterable<int> values) {
  final maximum = values.fold<int>(0, math.max);
  for (final step in [100, 1000, 5000, 10000]) {
    if (maximum <= step) return step;
  }
  var scale = 20000;
  while (scale < maximum) {
    scale *= 2;
  }
  return scale;
}
