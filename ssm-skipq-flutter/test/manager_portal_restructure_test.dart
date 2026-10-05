import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssm_skipq/config/theme.dart';
import 'package:ssm_skipq/models/menu.dart';
import 'package:ssm_skipq/models/order.dart';
import 'package:ssm_skipq/models/prebook_analytics.dart';
import 'package:ssm_skipq/providers/auth_provider.dart';
import 'package:ssm_skipq/providers/ordering_window_provider.dart';
import 'package:ssm_skipq/screens/manager/manager_dashboard_screen.dart';
import 'package:ssm_skipq/screens/manager/manager_orders_screen.dart';
import 'package:ssm_skipq/screens/manager/manager_prebook_analytics_screen.dart';
import 'package:ssm_skipq/services/api_client.dart';
import 'package:ssm_skipq/services/auth_service.dart';
import 'package:ssm_skipq/services/menu_service.dart';
import 'package:ssm_skipq/services/orders_service.dart';
import 'package:ssm_skipq/services/settings_service.dart';
import 'package:ssm_skipq/services/socket_service.dart';
import 'package:ssm_skipq/utils/helpers.dart';
import 'package:ssm_skipq/widgets/menu_item_image.dart';
import 'package:provider/provider.dart';

class _FakeOrdersService extends OrdersService {
  _FakeOrdersService({
    this.orders = const [],
    this.prebookCategories = const [],
  }) : super(ApiClient());

  final List<Order> orders;
  final List<PrebookAnalyticsCategory> prebookCategories;
  int prebookAnalyticsRequests = 0;

  @override
  Future<List<Order>> fetchManagerOrders() async => orders;

  @override
  Future<List<PrebookAnalyticsCategory>> fetchPrebookAnalytics() async {
    prebookAnalyticsRequests++;
    return prebookCategories;
  }
}

class _FakeMenuService extends MenuService {
  _FakeMenuService({
    this.categories = const [],
    this.items = const [],
  }) : super(ApiClient());

  final List<Category> categories;
  final List<MenuItem> items;
  int managerMenuRequests = 0;

  @override
  Future<({List<Category> categories, List<MenuItem> items})>
      fetchManagerMenu() async {
    managerMenuRequests++;
    return (categories: categories, items: items);
  }
}

class _FakeSocketService extends SocketService {
  _FakeSocketService() : super(ApiClient());

  void Function(Order order)? orderCreatedHandler;
  void Function(Order order)? orderUpdatedHandler;

  @override
  void joinManagerRoom() {}

  @override
  void onOrderCreated(void Function(Order order) handler) {
    orderCreatedHandler = handler;
  }

  @override
  void onOrderUpdated(void Function(Order order) handler) {
    orderUpdatedHandler = handler;
  }

  @override
  void off(String event) {}
}

Order _order(
  String id,
  OrderStatus status, {
  DateTime? createdAt,
}) =>
    Order(
      id: id,
      studentId: 'student-$id',
      items: const [
        OrderItem(
          menuItemId: 'item-1',
          name: 'Samosa',
          price: 25,
          quantity: 1,
        ),
      ],
      total: 25,
      paymentMethod: PaymentMethod.razorpay,
      paymentStatus: PaymentStatus.pending,
      status: status,
      tokenNumber: 'A$id',
      createdAt: createdAt ?? DateTime.now(),
      student: const OrderStudent(name: 'Student One', mobile: '000'),
    );

void main() {
  testWidgets(
      'Dashboard shows pre-book stats and total today inline with recent pre-books',
      (tester) async {
    final api = ApiClient();
    final initialOrders = <Order>[
      _order('1', OrderStatus.preBooked),
      _order('2', OrderStatus.pending),
      _order('3', OrderStatus.pickedUp),
      _order('4', OrderStatus.cancelled),
      _order(
        '6',
        OrderStatus.preBooked,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    final ordersService = _FakeOrdersService(orders: initialOrders);
    final socket = _FakeSocketService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              apiClient: api,
              authService: AuthService(api),
              socketService: socket,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => OrderingWindowProvider(
              settingsService: SettingsService(api),
              socketService: socket,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ManagerDashboardScreen(
              ordersService: ordersService,
              socketService: socket,
              onViewOrders: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pre-booked'), findsWidgets);
    expect(find.text('Total Orders'), findsNothing);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.textContaining('Total Orders Today: 4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-stat-pre-booked-count')),
      findsOneWidget,
    );
    socket.orderCreatedHandler?.call(_order('5', OrderStatus.preBooked));
    await tester.pumpAndSettle();
    expect(find.textContaining('Total Orders Today: 5'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('dashboard-stat-pre-booked-count')),
          )
          .data,
      '2',
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.text('A5 · Student One'), findsOneWidget);
    expect(find.text('A6 · Student One'), findsNothing);
    expect(find.text('Pre-booked'), findsNWidgets(2));
  });

  testWidgets('Pre-book tab uses category badges and image item drilldown',
      (tester) async {
    final category = const Category(
      id: 'snacks',
      name: 'Snacks',
      icon: 'fastfood',
    );
    final zeroCategory = const Category(
      id: 'drinks',
      name: 'Drinks',
      icon: 'cup_soda',
    );
    final item = MenuItem(
      id: 'samosa',
      name: 'Samosa',
      description: 'Crispy snack',
      price: 25,
      categoryId: category.id,
      categoryName: category.name,
      imageUrl: 'https://example.com/samosa.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );
    final demand = [
      PrebookAnalyticsCategory(
        id: category.id,
        name: category.name,
        totalQuantity: 7,
        items: const [
          PrebookAnalyticsItem(
            id: 'samosa',
            name: 'Samosa',
            quantity: 5,
          ),
          PrebookAnalyticsItem(
            id: 'pakora',
            name: 'Pakora',
            quantity: 2,
          ),
        ],
      ),
    ];
    final prebookOrders = [
      _order('10', OrderStatus.preBooked).copyWith(
        status: OrderStatus.preBooked,
      ),
      _order('11', OrderStatus.preBooked),
    ];
    final socket = _FakeSocketService();
    final ordersService = _FakeOrdersService(
      prebookCategories: demand,
      orders: prebookOrders,
    );
    final menuService = _FakeMenuService(
      categories: [category, zeroCategory],
      items: [item],
    );
    Widget buildScreen({int refreshKey = 0}) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ManagerPrebookAnalyticsScreen(
              ordersService: ordersService,
              socketService: socket,
              menuService: menuService,
              refreshKey: refreshKey,
            ),
          ),
        );

    await tester.pumpWidget(buildScreen());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(ordersService.prebookAnalyticsRequests, 1);

    expect(find.text('Food Items'), findsOneWidget);
    expect(find.text('Pakora'), findsOneWidget);
    expect(find.text('Samosa'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('prebook-item-samosa'))).dy,
      lessThan(tester
          .getTopLeft(find.byKey(const ValueKey('prebook-item-pakora')))
          .dy),
    );
    expect(find.byKey(const ValueKey('prebook-item-count-pakora')),
        findsOneWidget);
    expect(find.byTooltip('Filter'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('prebook-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    final badge = tester.widget<Container>(
      find.byKey(const ValueKey('prebook-count-snacks')),
    );
    expect(tester.getSize(find.byKey(const ValueKey('prebook-count-snacks'))),
        const Size(20, 20));
    expect(
      (badge.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(4),
    );

    await tester.tap(find.byKey(const ValueKey('prebook-category-snacks')));
    await tester.pumpAndSettle();

    expect(find.text('Samosa'), findsOneWidget);
    expect(find.byType(MenuItemImage), findsOneWidget);
    expect(find.byTooltip('Edit item'), findsNothing);
    expect(find.byTooltip('Delete item'), findsNothing);
    expect(find.byKey(const ValueKey('prebook-item-count-samosa')),
        findsOneWidget);
    final countText = tester.widget<Text>(
      find.byKey(const ValueKey('prebook-item-count-samosa')),
    );
    expect(countText.style?.color, AppTheme.primary);
    expect(find.text('pre-booked'), findsNWidgets(2));

    demand[0] = PrebookAnalyticsCategory(
      id: category.id,
      name: category.name,
      totalQuantity: 7,
      items: const [
        PrebookAnalyticsItem(id: 'samosa', name: 'Samosa', quantity: 7),
      ],
    );
    socket.orderCreatedHandler?.call(_order('5', OrderStatus.preBooked));
    await tester.pumpAndSettle();

    expect(find.text('7'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('prebook-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('Pre-booked orders today'), findsOneWidget);
    expect(find.text('Items pre-booked today'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Samosa is your most pre-booked item today — 2 orders'),
        findsOneWidget);
    await tester.pumpWidget(buildScreen(refreshKey: 1));
    await tester.pumpAndSettle();
    expect(ordersService.prebookAnalyticsRequests, 3);
    expect(menuService.managerMenuRequests, 3);
  });

  test('today order bucketing uses India Standard Time for UTC timestamps', () {
    const istOffset = Duration(hours: 5, minutes: 30);
    final nowIst = DateTime.now().toUtc().add(istOffset);
    final utcStartOfIstToday =
        DateTime.utc(nowIst.year, nowIst.month, nowIst.day).subtract(istOffset);

    expect(
        isTodayIst(utcStartOfIstToday.add(const Duration(hours: 1))), isTrue);
    expect(isTodayIst(utcStartOfIstToday.subtract(const Duration(seconds: 1))),
        isFalse);
  });

  testWidgets(
      'Orders page exposes exactly five status filters including prebook',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ManagerOrdersScreen(
            ordersService: _FakeOrdersService(
              orders: [
                _order('1', OrderStatus.preBooked),
                _order('2', OrderStatus.pending),
                _order('3', OrderStatus.active),
                _order('4', OrderStatus.pickedUp),
                _order('5', OrderStatus.cancelled),
                _order(
                  '6',
                  OrderStatus.pending,
                  createdAt: DateTime.now().subtract(const Duration(days: 1)),
                ),
              ],
            ),
            socketService: _FakeSocketService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chipLabels = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .map((chip) => (chip.label as Text).data)
        .toList();
    expect(chipLabels,
        ['Pre-booked', 'Pending', 'Active', 'Completed', 'Cancelled']);
    expect(
      find.ancestor(
        of: find.text('Cancelled'),
        matching: find.byType(Wrap),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Pre-booked'));
    await tester.pumpAndSettle();
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsNothing);
    expect(find.text('A6'), findsNothing);
  });
}
