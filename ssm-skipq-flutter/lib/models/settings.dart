class OrderingWindow {
  const OrderingWindow({
    required this.orderingOpenTime,
    required this.orderingCloseTime,
    required this.isOpen,
  });

  final String orderingOpenTime;
  final String orderingCloseTime;
  final bool isOpen;

  factory OrderingWindow.fromJson(Map<String, dynamic> json) {
    return OrderingWindow(
      orderingOpenTime: json['orderingOpenTime'] as String? ?? '09:30',
      orderingCloseTime: json['orderingCloseTime'] as String? ?? '11:30',
      isOpen: json['isOpen'] as bool? ?? false,
    );
  }
}
