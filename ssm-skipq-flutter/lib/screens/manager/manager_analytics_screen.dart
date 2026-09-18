import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../models/menu.dart';
import '../../config/menu_assets.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';

class ManagerAnalyticsScreen extends StatefulWidget {
  const ManagerAnalyticsScreen({
    super.key,
    required this.ordersService,
    required this.menuService,
  });

  final OrdersService ordersService;
  final MenuService menuService;

  @override
  State<ManagerAnalyticsScreen> createState() => _ManagerAnalyticsScreenState();
}

enum _AnalyticsPeriod { day, month, year, custom }

class _ManagerAnalyticsScreenState extends State<ManagerAnalyticsScreen> {
  final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  final DateFormat _shortDateFormat = DateFormat('d MMM');
  List<Order> _orders = [];
  List<MenuItem> _menuItems = [];
  bool _loading = true;
  String? _error;
  _AnalyticsPeriod _period = _AnalyticsPeriod.day;
  DateTime _day = DateTime.now();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _year = DateTime.now().year;
  DateTimeRange? _customRange;
  int _weekOffset = 0;
  int _monthStripYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.ordersService.fetchManagerOrders(),
        widget.menuService.fetchMenuItems(),
      ]);
      _orders = results[0] as List<Order>;
      _menuItems = results[1] as List<MenuItem>;
    } catch (_) {
      _error = 'Unable to load analytics data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> get _years {
    final currentYear = DateTime.now().year;
    return [for (var year = 2026; year <= currentYear; year++) year];
  }

  DateTimeRange get _selectedRange {
    switch (_period) {
      case _AnalyticsPeriod.day:
        final start = DateTime(_day.year, _day.month, _day.day);
        return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
      case _AnalyticsPeriod.month:
        final start = DateTime(_month.year, _month.month);
        return DateTimeRange(start: start, end: DateTime(start.year, start.month + 1));
      case _AnalyticsPeriod.year:
        return DateTimeRange(start: DateTime(_year), end: DateTime(_year + 1));
      case _AnalyticsPeriod.custom:
        return _customRange ??
            DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 1)));
    }
  }

  List<Order> get _filteredOrders {
    final range = _selectedRange;
    return _orders.where((order) {
      return !order.createdAt.isBefore(range.start) && order.createdAt.isBefore(range.end);
    }).toList();
  }

  Future<void> _choosePeriod(_AnalyticsPeriod period) async {
    final previousPeriod = _period;
    if (mounted) setState(() => _period = period);

    switch (period) {
      case _AnalyticsPeriod.day:
        final chosen = await _showDayPicker();
        if (chosen != null && mounted) {
          setState(() => _day = chosen);
        } else if (mounted) {
          setState(() => _period = previousPeriod);
        }
      case _AnalyticsPeriod.month:
        final chosen = await _showMonthPicker();
        if (chosen != null && mounted) {
          setState(() {
            _month = chosen;
            _monthStripYear = chosen.year;
          });
        } else if (mounted) {
          setState(() => _period = previousPeriod);
        }
      case _AnalyticsPeriod.year:
        final chosen = await _showYearPicker();
        if (chosen != null && mounted) {
          setState(() => _year = chosen);
        } else if (mounted) {
          setState(() => _period = previousPeriod);
        }
      case _AnalyticsPeriod.custom:
        final chosen = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2026),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          initialDateRange: _customRange,
          helpText: 'Select analytics range',
          saveText: 'Apply',
        );
        if (chosen != null && mounted) {
          final start = DateTime(chosen.start.year, chosen.start.month, chosen.start.day);
          final end = DateTime(chosen.end.year, chosen.end.month, chosen.end.day).add(const Duration(days: 1));
          setState(() {
            _customRange = DateTimeRange(start: start, end: end);
          });
        } else if (mounted) {
          setState(() => _period = previousPeriod);
        }
    }
  }

  Future<DateTime?> _showDayPicker() {
    var weekOffset = 0;
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final today = DateTime.now();
          final monday = DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: today.weekday - 1))
              .add(Duration(days: weekOffset * 7));
          final dates = [for (var index = 0; index < 7; index++) monday.add(Duration(days: index))];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose a day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: () => setSheetState(() => weekOffset--), icon: const Icon(Icons.chevron_left)),
                      Text('${_shortDateFormat.format(dates.first)} - ${_shortDateFormat.format(dates.last)}'),
                      IconButton(onPressed: () => setSheetState(() => weekOffset++), icon: const Icon(Icons.chevron_right)),
                    ],
                  ),
                  ...dates.map((date) => ListTile(
                        dense: true,
                        title: Text(DateFormat('EEEE, MMMM d, yyyy').format(date)),
                        trailing: date == _day ? const Icon(Icons.check, color: AppTheme.primary) : null,
                        onTap: () => Navigator.pop(sheetContext, date),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<DateTime?> _showMonthPicker() {
    var selectedYear = _month.year;
    return showModalBottomSheet<DateTime>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose a month', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                DropdownButton<int>(
                  value: _years.contains(selectedYear) ? selectedYear : _years.last,
                  items: _years.map((year) => DropdownMenuItem(value: year, child: Text('$year'))).toList(),
                  onChanged: (value) => setSheetState(() => selectedYear = value ?? selectedYear),
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  children: [for (var month = 1; month <= 12; month++)
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext, DateTime(selectedYear, month)),
                      child: Text(DateFormat('MMM').format(DateTime(2026, month))),
                    )],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int?> _showYearPicker() {
    return showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Choose a year', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ..._years.map((year) => ListTile(
                  title: Text('$year'),
                  trailing: year == _year ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () => Navigator.pop(sheetContext, year),
                )),
          ],
        ),
      ),
    );
  }

  String get _periodLabel {
    switch (_period) {
      case _AnalyticsPeriod.day: return _dateFormat.format(_day);
      case _AnalyticsPeriod.month: return _monthFormat.format(_month);
      case _AnalyticsPeriod.year: return '$_year';
      case _AnalyticsPeriod.custom:
        return _customRange == null ? 'Choose a range' : '${_dateFormat.format(_customRange!.start)} - ${_dateFormat.format(_customRange!.end)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;
    final cancelled = orders
      .where((order) => order.status == OrderStatus.cancelled && order.cancelledBy == 'STUDENT')
      .toList();
    final completed = orders.where((order) => order.status == OrderStatus.pickedUp).toList();
    final revenue = completed.fold<num>(0, (sum, order) => sum + order.total);
    final topItems = _rankItems(orders);
    final cancelledItems = _rankItems(cancelled);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_periodLabel, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _filterBar(),
          if (_period == _AnalyticsPeriod.day) _dayStrip(),
          if (_period == _AnalyticsPeriod.month) _monthStrip(),
          if (_period == _AnalyticsPeriod.custom && _customRange != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _period = _AnalyticsPeriod.day;
                  _customRange = null;
                  _day = DateTime.now();
                }),
                icon: const Icon(Icons.clear),
                label: const Text('Clear selection'),
              ),
            ),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else ...[
            _primaryCards(orders, completed, cancelled, revenue),
            const SizedBox(height: 16),
            _highlight(topItems),
            const SizedBox(height: 16),
            _section('Top 5 most ordered items', _rankedList(topItems, empty: 'No order data available for this period')),
            const SizedBox(height: 16),
            _section('Cancellation analytics', Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: _miniMetric('Cancelled Orders', '${cancelled.length}')), const SizedBox(width: 10), Expanded(child: _miniMetric('Cancelled Item Quantities', '${cancelled.fold<int>(0, (sum, order) => sum + order.items.fold<int>(0, (itemSum, item) => itemSum + item.quantity))}'))]),
                const SizedBox(height: 16),
                const Text('Most cancelled food items', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _rankedList(cancelledItems, empty: 'No cancelled items for this period'),
              ],
            )),
          ],
        ],
      ),
    );
  }

  Widget _filterBar() => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            spacing: 8,
            children: [
              (_AnalyticsPeriod.day, 'Day'),
              (_AnalyticsPeriod.month, 'Month'),
              (_AnalyticsPeriod.year, 'Year'),
              (_AnalyticsPeriod.custom, 'Custom Range'),
            ].map((entry) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.$2),
                selected: _period == entry.$1,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: _period == entry.$1 ? Colors.white : AppTheme.textSecondary),
                onSelected: (_) => _choosePeriod(entry.$1),
              ),
            )).toList(),
            ),
          ),
        ),
      );

  Widget _dayStrip() {
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: _weekOffset * 7));
    final dates = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    return _stripCard(
      leading: IconButton(
        onPressed: () => setState(() => _weekOffset--),
        icon: const Icon(Icons.chevron_left),
      ),
      trailing: IconButton(
        onPressed: () => setState(() => _weekOffset++),
        icon: const Icon(Icons.chevron_right),
      ),
      children: dates.map((date) {
        final selected = _day.year == date.year && _day.month == date.month && _day.day == date.day;
        return _periodPill(
          label: DateFormat('EEE\nd').format(date),
          selected: selected,
          onTap: () => setState(() { _period = _AnalyticsPeriod.day; _day = date; }),
        );
      }).toList(),
    );
  }

  Widget _monthStrip() {
    return _stripCard(
      leading: IconButton(
        onPressed: () => setState(() => _monthStripYear--),
        icon: const Icon(Icons.chevron_left),
      ),
      trailing: IconButton(
        onPressed: () => setState(() => _monthStripYear++),
        icon: const Icon(Icons.chevron_right),
      ),
      children: [for (var month = 1; month <= 12; month++)
        _periodPill(
          label: DateFormat('MMM').format(DateTime(2026, month)),
          selected: _month.year == _monthStripYear && _month.month == month,
          onTap: () => setState(() {
            _period = _AnalyticsPeriod.month;
            _month = DateTime(_monthStripYear, month);
          }),
        )],
    );
  }

  Widget _stripCard({required Widget leading, required Widget trailing, required List<Widget> children}) => Card(
        child: Row(
          children: [leading, Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: children))), trailing],
        ),
      );

  Widget _periodPill({required String label, required bool selected, required VoidCallback onTap}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.bgSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      );

  Widget _primaryCards(List<Order> total, List<Order> completed, List<Order> cancelled, num revenue) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          _metricCard('Total Orders', '${total.length}', Icons.receipt_long_outlined, () => _showOrderList('Total Orders', total)),
          _metricCard('Completed Orders', '${completed.length}', Icons.check_circle_outline, () => _showOrderList('Completed Orders', completed)),
          _metricCard('Cancelled Orders', '${cancelled.length}', Icons.cancel_outlined, () => _showOrderList('Cancelled Orders', cancelled)),
          _metricCard('Revenue', '₹$revenue', Icons.payments_outlined, null, highlight: true),
        ],
      );

  Widget _metricCard(String label, String value, IconData icon, VoidCallback? onTap, {bool highlight = false}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: highlight ? AppTheme.primaryMuted : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppTheme.primary, size: 22), const SizedBox(height: 6), Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))]),
        ),
      );

  Future<void> _showOrderList(String title, List<Order> orders) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: orders.isEmpty
              ? const Text('No orders for this period.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final order = orders[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${order.tokenNumber} · ${order.student?.name ?? 'Student'}'),
                      subtitle: Text('${_dateFormat.format(order.createdAt)} · ${order.status.label}'),
                      trailing: Text('₹${order.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  Widget _section(String title, Widget child) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 14), child])));

  Widget _highlight(List<_RankedItem> items) => Card(color: AppTheme.primaryMuted, child: Padding(padding: const EdgeInsets.all(16), child: items.isEmpty ? const Text('No order data available for this period') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Most Ordered Item', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(items.first.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${items.first.quantity} portions')])));

  Widget _rankedList(List<_RankedItem> items, {required String empty}) {
    if (items.isEmpty) {
      return Text(empty, style: const TextStyle(color: AppTheme.textSecondary));
    }
    return Column(
      children: items.take(5).toList().asMap().entries.map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryMuted,
            child: Text('${entry.key + 1}'),
          ),
          title: Text(entry.value.name),
          trailing: Text(
            '${entry.value.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
    );
  }

  Widget _miniMetric(String label, String value) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.bgSubtle, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]));

  List<_RankedItem> _rankItems(List<Order> orders) {
    final quantities = <String, int>{};
    final latest = <String, DateTime>{};
    for (final order in orders) {
      for (final item in order.items) {
        quantities[item.name] = (quantities[item.name] ?? 0) + item.quantity;
        if (!latest.containsKey(item.name) || order.createdAt.isAfter(latest[item.name]!)) latest[item.name] = order.createdAt;
      }
    }
    return quantities.entries.map((entry) => _RankedItem(entry.key, entry.value, latest[entry.key]!)).toList()..sort((a, b) => b.quantity != a.quantity ? b.quantity.compareTo(a.quantity) : b.latest.compareTo(a.latest));
  }

}

class _RankedItem {
  const _RankedItem(this.name, this.quantity, this.latest);
  final String name;
  final int quantity;
  final DateTime latest;
}

