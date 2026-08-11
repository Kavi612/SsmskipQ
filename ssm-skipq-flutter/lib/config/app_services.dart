import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/feedback_service.dart';
import '../services/menu_service.dart';
import '../services/orders_service.dart';
import '../services/settings_service.dart';
import '../services/socket_service.dart';

class AppServices {
  AppServices() : apiClient = ApiClient() {
    authService = AuthService(apiClient);
    menuService = MenuService(apiClient);
    ordersService = OrdersService(apiClient);
    feedbackService = FeedbackService(apiClient);
    settingsService = SettingsService(apiClient);
    socketService = SocketService(apiClient);
  }

  final ApiClient apiClient;
  late final AuthService authService;
  late final MenuService menuService;
  late final OrdersService ordersService;
  late final FeedbackService feedbackService;
  late final SettingsService settingsService;
  late final SocketService socketService;
}
