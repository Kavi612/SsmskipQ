import '../models/feedback.dart';
import 'api_client.dart';

class FeedbackService {
  FeedbackService(this._api);

  final ApiClient _api;

  Future<OrderFeedback> submitFeedback({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/orders/$orderId/feedback',
      data: {
        'rating': rating,
        if (review != null && review.trim().isNotEmpty) 'review': review.trim(),
      },
    );
    final feedback =
        (response.data?['data'] as Map<String, dynamic>)['feedback'];
    return OrderFeedback.fromJson(feedback as Map<String, dynamic>);
  }

  Future<List<OrderFeedback>> fetchManagerFeedback() async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/orders/feedback/manager');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['feedback'] as List<dynamic>? ?? [])
        .map((e) => OrderFeedback.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
