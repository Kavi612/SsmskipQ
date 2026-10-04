import '../models/dashboard_analytics.dart';
import '../models/order.dart';
import '../models/prebook_analytics.dart';
import 'api_client.dart';

class CreateOrderResult {
  const CreateOrderResult({required this.order});

  final Order order;
}

class OrdersService {
  OrdersService(this._api);

  final ApiClient _api;

  Future<List<Order>> fetchMyOrders() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/orders');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['orders'] as List<dynamic>? ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CreateOrderResult> createOrder({
    required List<OrderItem> items,
    required num total,
    bool isPreBook = false,
    String note = '',
  }) async {
    final trimmedNote = note.trim();
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'paymentMethod': PaymentMethod.razorpay.apiValue,
        if (isPreBook) 'isPreBook': true,
        if (trimmedNote.isNotEmpty) 'note': trimmedNote,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final order = Order.fromJson(data['order'] as Map<String, dynamic>);
    return CreateOrderResult(order: order);
  }

  Future<List<Order>> fetchManagerOrders() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/orders/manager');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['orders'] as List<dynamic>? ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PrebookAnalyticsCategory>> fetchPrebookAnalytics() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/orders/prebook-analytics',
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return (data['categories'] as List<dynamic>? ?? [])
        .map((category) => PrebookAnalyticsCategory.fromJson(
            category as Map<String, dynamic>))
        .toList();
  }

  Future<DashboardAnalytics> fetchDashboardAnalytics({
    required String range,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/orders/analytics',
      queryParameters: {
        'range': range,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final analytics = data['analytics'] as Map<String, dynamic>? ?? {};
    return DashboardAnalytics.fromJson(analytics);
  }

  Future<Order> advanceStatus(String orderId) async {
    final response =
        await _api.dio.patch<Map<String, dynamic>>('/orders/$orderId/status');
    final order = (response.data?['data'] as Map<String, dynamic>)['order'];
    return Order.fromJson(order as Map<String, dynamic>);
  }

  Future<Order> cancelOrder(String orderId) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/orders/$orderId/cancel',
    );
    final order = (response.data?['data'] as Map<String, dynamic>)['order'];
    return Order.fromJson(order as Map<String, dynamic>);
  }

  Future<Order> updatePayment(String orderId, PaymentStatus status) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/orders/$orderId/payment',
      data: {'paymentStatus': status.apiValue},
    );
    final order = (response.data?['data'] as Map<String, dynamic>)['order'];
    return Order.fromJson(order as Map<String, dynamic>);
  }
}
