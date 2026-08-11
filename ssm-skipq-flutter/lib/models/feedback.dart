import 'order.dart';

class OrderFeedback {
  const OrderFeedback({
    required this.id,
    required this.orderId,
    required this.rating,
    required this.review,
    required this.createdAt,
    this.student,
    this.order,
  });

  final String id;
  final String orderId;
  final int rating;
  final String review;
  final DateTime createdAt;
  final OrderStudent? student;
  final FeedbackOrderSummary? order;

  factory OrderFeedback.fromJson(Map<String, dynamic> json) {
    return OrderFeedback(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      rating: json['rating'] as int? ?? 0,
      review: json['review'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      student: json['student'] != null
          ? OrderStudent.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      order: json['order'] != null
          ? FeedbackOrderSummary.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FeedbackOrderSummary {
  const FeedbackOrderSummary({
    required this.tokenNumber,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  final String tokenNumber;
  final List<OrderItem> items;
  final num total;
  final DateTime createdAt;

  factory FeedbackOrderSummary.fromJson(Map<String, dynamic> json) {
    return FeedbackOrderSummary(
      tokenNumber: json['tokenNumber'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
