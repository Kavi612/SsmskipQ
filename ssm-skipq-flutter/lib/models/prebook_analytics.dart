class PrebookAnalyticsCategory {
  const PrebookAnalyticsCategory({
    required this.id,
    required this.name,
    required this.totalQuantity,
    required this.items,
  });

  final String id;
  final String name;
  final int totalQuantity;
  final List<PrebookAnalyticsItem> items;

  factory PrebookAnalyticsCategory.fromJson(Map<String, dynamic> json) {
    return PrebookAnalyticsCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Other',
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => PrebookAnalyticsItem.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PrebookAnalyticsItem {
  const PrebookAnalyticsItem({
    required this.id,
    required this.name,
    required this.quantity,
  });

  final String id;
  final String name;
  final int quantity;

  factory PrebookAnalyticsItem.fromJson(Map<String, dynamic> json) {
    return PrebookAnalyticsItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}