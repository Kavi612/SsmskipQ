import '../models/order.dart';
import 'api_client.dart';

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

  Future<Order> createOrder({
    required List<OrderItem> items,
    required num total,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'paymentMethod': paymentMethod.apiValue,
        'paymentStatus': paymentStatus.apiValue,
      },
    );
    final order = (response.data?['data'] as Map<String, dynamic>)['order'];
    return Order.fromJson(order as Map<String, dynamic>);
  }

  Future<List<Order>> fetchManagerOrders() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/orders/manager');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['orders'] as List<dynamic>? ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> advanceStatus(String orderId) async {
    final response =
        await _api.dio.patch<Map<String, dynamic>>('/orders/$orderId/status');
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
