import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ssm_skipq/config/theme.dart';
import 'package:ssm_skipq/models/feedback.dart';
import 'package:ssm_skipq/models/menu.dart';
import 'package:ssm_skipq/models/order.dart';
import 'package:ssm_skipq/providers/auth_provider.dart';
import 'package:ssm_skipq/providers/cart_provider.dart';
import 'package:ssm_skipq/providers/ordering_window_provider.dart';
import 'package:ssm_skipq/screens/student/student_cart_screen.dart';
import 'package:ssm_skipq/screens/student/student_home_screen.dart';
import 'package:ssm_skipq/screens/student/student_track_order_screen.dart';
import 'package:ssm_skipq/services/api_client.dart';
import 'package:ssm_skipq/services/auth_service.dart';
import 'package:ssm_skipq/services/feedback_service.dart';
import 'package:ssm_skipq/services/menu_service.dart';
import 'package:ssm_skipq/services/orders_service.dart';
import 'package:ssm_skipq/services/settings_service.dart';
import 'package:ssm_skipq/services/socket_service.dart';
import 'package:ssm_skipq/widgets/food_card.dart';
import 'package:ssm_skipq/widgets/student_bottom_navigation_bar.dart';

class FakeOrdersService extends OrdersService {
  FakeOrdersService() : super(ApiClient());

  Future<List<Order>> Function()? fetchOrders;

  @override
  Future<List<Order>> fetchMyOrders() {
    final fetch = fetchOrders;
    return fetch == null ? Future.value(const <Order>[]) : fetch();
  }
}

class FakeSocketService extends SocketService {
  FakeSocketService() : super(ApiClient());

  void Function(Order order)? orderUpdatedHandler;

  @override
  void joinStudentRoom() {}

  @override
  void onOrderUpdated(void Function(Order order) handler) {
    orderUpdatedHandler = handler;
  }

  @override
  void offOrderUpdated(void Function(Order order) handler) {
    orderUpdatedHandler = null;
  }

  void emitOrderUpdated(Order order) => orderUpdatedHandler?.call(order);
}

class FakeMenuService extends MenuService {
  FakeMenuService({this.items = const []}) : super(ApiClient());

  final List<MenuItem> items;

  @override
  Future<List<Category>> fetchCategories() async => const [];

  @override
  Future<List<MenuItem>> fetchMenuItems() async => items;
}

class FakeFeedbackService extends FeedbackService {
  FakeFeedbackService() : super(ApiClient());

  @override
  Future<OrderFeedback> submitFeedback({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    return OrderFeedback(
      id: 'fb-1',
      orderId: orderId,
      rating: rating,
      review: review ?? '',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('Cart tab stays inside the student shell route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: StudentBottomNavigationBar(selectedIndex: 0),
          ),
        ),
        GoRoute(
          path: '/student',
          builder: (_, __) => const Scaffold(body: Text('student shell')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/student?tab=cart');
  });

  testWidgets('FoodCard shows Highly Ordered badge without changing layout',
      (tester) async {
    final item = MenuItem(
      id: 'menu-1',
      name: 'Samosa',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Center(
            child: SizedBox(
              width: 170,
              child: FoodCard(
                item: item,
                orderingOpen: true,
                isHighlyOrdered: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Highly Ordered'), findsOneWidget);
    expect(find.text('ADD'), findsOneWidget);
    expect(find.text('Samosa'), findsOneWidget);
    expect(find.text('₹199'), findsOneWidget);
  });

  testWidgets('Veg-only control sits beside search and floating cart navigates',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient();
    final cart = CartProvider();
    final socket = FakeSocketService();
    final router = GoRouter(
      initialLocation: '/student',
      routes: [
        GoRoute(
          path: '/student',
          builder: (_, __) => Scaffold(
            body: StudentHomeScreen(
              menuService: FakeMenuService(items: [
                MenuItem(
                  id: 'menu-cart-bar',
                  name: 'Samosa',
                  description: 'Tasty item',
                  price: 25,
                  categoryId: 'snacks',
                  categoryName: 'Snacks',
                  imageUrl: '',
                  isVeg: true,
                  available: true,
                  createdAt: DateTime.now(),
                ),
                MenuItem(
                  id: 'menu-nonveg',
                  name: 'Chicken 65',
                  description: 'Spicy chicken',
                  price: 80,
                  categoryId: 'snacks',
                  categoryName: 'Snacks',
                  imageUrl: '',
                  isVeg: false,
                  available: true,
                  createdAt: DateTime.now(),
                ),
              ]),
              ordersService: FakeOrdersService(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
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
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('veg-filter-toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-filter-popup')), findsOneWidget);
    expect(find.text('Non-veg only'), findsNothing);
    expect(find.text('Samosa'), findsOneWidget);
    expect(find.text('Chicken 65'), findsOneWidget);
    expect(find.byKey(const ValueKey('floating-cart-bar')), findsNothing);
    final searchRect = tester.getRect(find.byType(TextField));
    final vegRect =
        tester.getRect(find.byKey(const ValueKey('veg-filter-toggle')));
    expect(searchRect.width, lessThan(350));
    expect(vegRect.bottom, closeTo(searchRect.bottom, 1));
    expect(vegRect.height, searchRect.height);
    expect(vegRect.width, searchRect.height);
    expect(vegRect.width, 48);
    expect(find.text('VEG'), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('menu-filter-popup'))).dy,
      greaterThan(tester.getRect(find.text('All')).bottom),
    );
    await tester.tap(find.byKey(const ValueKey('veg-filter-toggle')));
    await tester.pump();
    expect(find.text('Chicken 65'), findsNothing);
    expect(find.text('ADD'), findsOneWidget);
    await tester.tap(find.text('ADD'));
    await tester.pump();

    expect(find.byKey(const ValueKey('floating-cart-bar')), findsOneWidget);
    expect(find.text('1 item  •  ₹25'), findsOneWidget);
    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/student?tab=cart');
    cart.clear();
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-cart-bar')), findsNothing);
    router.dispose();
  });

  testWidgets('FoodCard shows Sold Out instead of an add control',
      (tester) async {
    final item = MenuItem(
      id: 'menu-sold-out',
      name: 'Samosa',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: false,
      createdAt: DateTime.now(),
    );
    final cart = CartProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 170,
              child: FoodCard(item: item, orderingOpen: true),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sold Out'), findsOneWidget);
    expect(find.text('ADD'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('food-card-sold-out'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Sold Out'));
    expect(cart.items, isEmpty);
  });

  testWidgets('FoodCard ADD and Pre-book actions have larger tap targets',
      (tester) async {
    final item = MenuItem(
      id: 'menu-large-actions',
      name: 'Samosa',
      description: 'Tasty item',
      price: 25,
      categoryId: 'snacks',
      categoryName: 'Snacks',
      imageUrl: '',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    Future<void> pumpCard(bool orderingOpen) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
          child: MaterialApp(
            home: Center(
              child: SizedBox(
                width: 170,
                child: FoodCard(item: item, orderingOpen: orderingOpen),
              ),
            ),
          ),
        ),
      );
    }

    await pumpCard(true);
    final name = tester.widget<Text>(find.text('Samosa'));
    final price = tester.widget<Text>(find.text('₹25'));
    expect(name.style?.fontSize, 13.5);
    expect(price.style?.fontSize, 14.5);
    final addTarget = find
        .ancestor(
          of: find.text('ADD'),
          matching: find.byType(GestureDetector),
        )
        .first;
    expect(tester.getSize(addTarget).height, greaterThanOrEqualTo(48));

    await pumpCard(false);
    final preBookTarget = find
        .ancestor(
          of: find.text('Pre-book'),
          matching: find.byType(GestureDetector),
        )
        .first;
    expect(tester.getSize(preBookTarget).height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'Pre-book cart confirms as pre-book; regular cart label is unchanged',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = MenuItem(
      id: 'checkout-label-item',
      name: 'Samosa',
      description: 'Tasty item',
      price: 25,
      categoryId: 'snacks',
      categoryName: 'Snacks',
      imageUrl: '',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    Future<void> expectCheckoutLabel({
      required bool isPreBook,
      required String expectedLabel,
    }) async {
      final cart = CartProvider();
      cart.addItem(
        menuItemId: item.id,
        name: item.name,
        price: item.price,
        imageUrl: item.imageUrl,
        isVeg: item.isVeg,
        available: item.available,
        isPreBook: isPreBook,
        categoryId: item.categoryId,
        categoryName: item.categoryName,
      );
      expect(cart.items, hasLength(1));
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: cart,
          child: MaterialApp(
            theme: AppTheme.light,
            home: StudentCartScreen(
              key: ValueKey('checkout-label-$isPreBook'),
              menuService: FakeMenuService(items: [item]),
              ordersService: FakeOrdersService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final proceedButton = find.text('PROCEED TO CHECKOUT');
      expect(find.text('Samosa'), findsOneWidget);
      expect(proceedButton, findsOneWidget);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();
      expect(find.text(expectedLabel), findsOneWidget);
    }

    await expectCheckoutLabel(
      isPreBook: false,
      expectedLabel: 'PLACE ORDER',
    );
    await expectCheckoutLabel(
      isPreBook: true,
      expectedLabel: 'Confirm Pre-book',
    );
  });

  test('Cart availability follows the latest menu availability', () {
    final cart = CartProvider();
    cart.addItem(
      menuItemId: 'menu-sold-out',
      name: 'Samosa',
      price: 199,
      imageUrl: '',
      isVeg: true,
      available: true,
    );

    cart.updateAvailability({'menu-sold-out': false});

    expect(cart.items.single.available, isFalse);
  });

  testWidgets('FoodCard quantity stepper stays synchronized with the cart',
      (tester) async {
    final item = MenuItem(
      id: 'menu-stepper',
      name: 'Samosa',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );
    final cart = CartProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 170,
              child: FoodCard(item: item, orderingOpen: true),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ADD'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(cart.getQuantity(item.id), 1);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(cart.getQuantity(item.id), 2);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('ADD'), findsOneWidget);
    expect(cart.getQuantity(item.id), 0);
  });

  testWidgets('FoodCard keeps the image height fixed and name text compact',
      (tester) async {
    final item = MenuItem(
      id: 'menu-1',
      name:
          'Another really long menu item name that should ellipsize before overflow',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Center(
            child: SizedBox(
              width: 170,
              child: FoodCard(item: item, orderingOpen: true),
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(FoodCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 112,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('ADD'), findsOneWidget);
  });

  testWidgets('Current grid ratio stays within the card height',
      (tester) async {
    final item = MenuItem(
      id: 'menu-2',
      name: 'Another really long menu item name that should ellipsize',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: SizedBox(
                height: 220,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                  children: [FoodCard(item: item, orderingOpen: true)],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Menu grid keeps every card at a uniform fixed height',
      (tester) async {
    final items = List.generate(
      4,
      (index) => MenuItem(
        id: 'menu-$index',
        name: index.isEven ? 'Bajji' : 'Chicken Fried Rice Very Long Name',
        description: 'Tasty item',
        price: 199,
        categoryId: 'main',
        categoryName: 'Main',
        imageUrl: 'https://example.com/item.jpg',
        isVeg: index.isEven,
        available: true,
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  const targetHeight = 290.0;

                  return GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: cardWidth / targetHeight,
                    children: items
                        .map((item) => FoodCard(item: item, orderingOpen: true))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final cardFinder = find.byType(FoodCard);
    final cardHeights = List.generate(
      cardFinder.evaluate().length,
      (index) => tester.getRect(cardFinder.at(index)).height,
    );

    expect(cardHeights.length, 4);
    expect(cardHeights.toSet().length, 1);
    expect(find.text('ADD'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Track order shows the feedback form once the order is picked up',
      (tester) async {
    final order = Order(
      id: 'order-1',
      studentId: 'student-1',
      items: const [
        OrderItem(
            menuItemId: 'item-1', name: 'Sandwich', price: 120, quantity: 1),
      ],
      total: 120,
      paymentMethod: PaymentMethod.googlePay,
      paymentStatus: PaymentStatus.paid,
      status: OrderStatus.pickedUp,
      tokenNumber: 'A001',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StudentTrackOrderScreen(
          orderId: order.id,
          initialOrder: order,
          ordersService: FakeOrdersService(),
          socketService: FakeSocketService(),
          feedbackService: FakeFeedbackService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('How was your order A001?'), findsOneWidget);
    expect(find.text('Submit Feedback'), findsOneWidget);
  });

  test('picked-up order remains a tracked order for feedback flow', () {
    final order = Order(
      id: 'order-2',
      studentId: 'student-2',
      items: const [
        OrderItem(
            menuItemId: 'item-2', name: 'Burger', price: 150, quantity: 1),
      ],
      total: 150,
      paymentMethod: PaymentMethod.googlePay,
      paymentStatus: PaymentStatus.paid,
      status: OrderStatus.pickedUp,
      tokenNumber: 'A002',
      createdAt: DateTime.now(),
    );

    expect(
        getCurrentActiveOrderForStudent([order], orderId: order.id), isNotNull);
  });

  testWidgets('Pre-book cross-sell adds suggestions to the pre-book cart',
      (tester) async {
    final cart = CartProvider();
    cart.addItem(
      menuItemId: 'prebook-main',
      name: 'Rice',
      price: 120,
      imageUrl: '',
      isVeg: true,
      available: true,
      isPreBook: true,
      categoryId: 'meals',
      categoryName: 'Meals',
    );
    final suggestion = MenuItem(
      id: 'prebook-side',
      name: 'Curd',
      description: 'Fresh curd',
      price: 30,
      categoryId: 'meals',
      categoryName: 'Meals',
      imageUrl: '',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(
          theme: AppTheme.light,
          home: StudentCartScreen(
            menuService: FakeMenuService(items: [suggestion]),
            ordersService: FakeOrdersService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your Pre-book Cart'), findsOneWidget);
    expect(find.text('Curd'), findsOneWidget);

    await tester.tap(find.text('+'));
    await tester.pump();

    expect(cart.items.map((item) => item.menuItemId), contains('prebook-side'));
    expect(cart.isPreBook, isTrue);
  });

  testWidgets('Track Order follows live status updates without stale refresh',
      (tester) async {
    final pending = Order(
      id: 'live-order',
      studentId: 'student-1',
      items: const [
        OrderItem(
          menuItemId: 'item-1',
          name: 'Sandwich',
          price: 120,
          quantity: 1,
        ),
      ],
      total: 120,
      paymentMethod: PaymentMethod.razorpay,
      paymentStatus: PaymentStatus.pending,
      status: OrderStatus.pending,
      tokenNumber: 'A100',
      createdAt: DateTime.now(),
    );
    final refreshCompleter = Completer<List<Order>>();
    final ordersService = FakeOrdersService()
      ..fetchOrders = () => refreshCompleter.future;
    final socketService = FakeSocketService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StudentTrackOrderScreen(
          orderId: pending.id,
          initialOrder: pending,
          ordersService: ordersService,
          socketService: socketService,
          feedbackService: FakeFeedbackService(),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Waiting for the canteen'), findsOneWidget);

    final accepted = pending.copyWith(status: OrderStatus.confirmed);
    socketService.emitOrderUpdated(accepted);
    await tester.pump();
    expect(find.textContaining('Order accepted'), findsOneWidget);
    expect(_statusCircleColor(tester, OrderStatus.pending), AppTheme.primary);
    expect(_statusCircleColor(tester, OrderStatus.confirmed),
        AppTheme.primaryMuted);
    expect(
      _statusCircleColor(tester, OrderStatus.active),
      AppTheme.gray100,
    );

    final active = accepted.copyWith(
      status: OrderStatus.active,
      paymentStatus: PaymentStatus.paid,
    );
    socketService.emitOrderUpdated(active);
    await tester.pump();
    expect(find.text('The canteen is preparing your food.'), findsOneWidget);
    expect(_statusCircleColor(tester, OrderStatus.confirmed), AppTheme.primary);
    expect(
        _statusCircleColor(tester, OrderStatus.active), AppTheme.primaryMuted);

    final completed = active.copyWith(status: OrderStatus.pickedUp);
    socketService.emitOrderUpdated(completed);
    await tester.pump();
    expect(find.text('Order completed. Enjoy your meal!'), findsOneWidget);
    expect(_statusCircleColor(tester, OrderStatus.active), AppTheme.primary);
    expect(_statusCircleColor(tester, OrderStatus.pickedUp),
        AppTheme.primaryMuted);

    refreshCompleter.complete([pending]);
    await tester.pump();
    expect(find.text('Order completed. Enjoy your meal!'), findsOneWidget);
    expect(_statusCircleColor(tester, OrderStatus.pickedUp),
        AppTheme.primaryMuted);
  });
}

Color _statusCircleColor(WidgetTester tester, OrderStatus status) {
  final circle = tester.widget<Container>(
    find.byKey(ValueKey('order-status-step-${status.apiValue}')),
  );
  return (circle.decoration! as BoxDecoration).color!;
}
