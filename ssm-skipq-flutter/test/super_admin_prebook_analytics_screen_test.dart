import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssm_skipq/config/theme.dart';
import 'package:ssm_skipq/models/menu.dart';
import 'package:ssm_skipq/models/order.dart';
import 'package:ssm_skipq/screens/super_admin/super_admin_date_filter.dart';
import 'package:ssm_skipq/screens/super_admin/super_admin_prebook_analytics_screen.dart';
import 'package:ssm_skipq/services/api_client.dart';
import 'package:ssm_skipq/services/super_admin_service.dart';

class FakeSuperAdminService extends SuperAdminService {
  FakeSuperAdminService({
    required this.orders,
    required this.menuItems,
    required this.categories,
  }) : super(ApiClient());

  final List<Order> orders;
  final List<MenuItem> menuItems;
  final List<Category> categories;

  @override
  Future<List<Order>> fetchOrders() async => orders;

  @override
  Future<List<MenuItem>> fetchMenuItems() async => menuItems;

  @override
  Future<List<Category>> fetchCategories() async => categories;
}

void main() {
  test('legacy pre-book status is recognized without a stored marker', () {
    final order = Order.fromJson({
      'id': 'legacy',
      'status': 'PRE_BOOKED',
      'createdAt': '2026-10-04T10:00:00.000',
    });

    expect(order.isPreBook, isTrue);
  });

  testWidgets('date filter updates pre-book totals, category chart and ranking',
      (tester) async {
    final orders = [
      Order(
        id: 'sunday-prebook',
        studentId: 'student-1',
        items: const [
          OrderItem(
              menuItemId: 'rice', name: 'Rice', price: 20, quantity: 1200),
          OrderItem(menuItemId: 'tea', name: 'Tea', price: 5, quantity: 1),
        ],
        total: 24005,
        paymentMethod: PaymentMethod.razorpay,
        paymentStatus: PaymentStatus.pending,
        status: OrderStatus.pending,
        tokenNumber: 'A001',
        createdAt: DateTime(2026, 10, 4, 10),
        isPreBook: true,
      ),
      Order(
        id: 'friday-prebook',
        studentId: 'student-2',
        items: const [
          OrderItem(menuItemId: 'tea', name: 'Tea', price: 5, quantity: 6),
        ],
        total: 30,
        paymentMethod: PaymentMethod.razorpay,
        paymentStatus: PaymentStatus.pending,
        status: OrderStatus.pending,
        tokenNumber: 'A002',
        createdAt: DateTime(2026, 10, 2, 10),
        isPreBook: true,
      ),
      Order(
        id: 'regular-order',
        studentId: 'student-3',
        items: const [
          OrderItem(menuItemId: 'rice', name: 'Rice', price: 20, quantity: 999),
        ],
        total: 19980,
        paymentMethod: PaymentMethod.razorpay,
        paymentStatus: PaymentStatus.pending,
        status: OrderStatus.pending,
        tokenNumber: 'A003',
        createdAt: DateTime(2026, 10, 4, 11),
      ),
    ];
    final menuItems = [
      MenuItem(
        id: 'rice',
        name: 'Rice',
        description: '',
        price: 20,
        categoryId: 'mains',
        categoryName: 'Mains',
        imageUrl: '',
        isVeg: true,
        available: true,
        createdAt: DateTime(2026),
      ),
      MenuItem(
        id: 'tea',
        name: 'Tea',
        description: '',
        price: 5,
        categoryId: 'drinks',
        categoryName: 'Drinks',
        imageUrl: '',
        isVeg: true,
        available: true,
        createdAt: DateTime(2026),
      ),
    ];
    final service = FakeSuperAdminService(
      orders: orders,
      menuItems: menuItems,
      categories: const [
        Category(id: 'mains', name: 'Mains'),
        Category(id: 'drinks', name: 'Drinks'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SuperAdminPrebookAnalyticsScreen(
          superAdminService: service,
          initialSelection: SuperAdminDateFilterSelection(
            period: SuperAdminAnalyticsPeriod.day,
            label: '4 Oct 2026',
            range: DateTimeRange(
              start: DateTime(2026, 10, 4),
              end: DateTime(2026, 10, 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Pre-booked Orders'), findsOneWidget);
    expect(find.text('Total Pre-booked Items'), findsOneWidget);
    expect(find.text('1201'), findsOneWidget);
    expect(find.text('Scale: 0 - 5000 items'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Tea'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fri\n2'));
    await tester.pumpAndSettle();

    expect(find.text('1201'), findsNothing);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Scale: 0 - 100 items'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Rice'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Tea'), findsOneWidget);
  });
}
