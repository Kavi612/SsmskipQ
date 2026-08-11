import '../models/settings.dart';
import 'api_client.dart';

class SettingsService {
  SettingsService(this._api);

  final ApiClient _api;

  Future<OrderingWindow> fetchOrderingWindow() async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/settings/ordering-window');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return OrderingWindow.fromJson(data ?? {});
  }

  Future<OrderingWindow> updateOrderingWindow({
    required String openTime,
    required String closeTime,
  }) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/settings/ordering-window',
      data: {
        'orderingOpenTime': openTime,
        'orderingCloseTime': closeTime,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return OrderingWindow.fromJson(data ?? {});
  }
}
