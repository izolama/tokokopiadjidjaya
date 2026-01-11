import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/firestore_service.dart';

class AdminOrderSummaryPage extends StatelessWidget {
  const AdminOrderSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Order>>(
          stream: context.read<FirestoreService>().watchAllOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const Center(child: Text('No orders yet.'));
            }
            final now = DateTime.now();
            final daily = _groupByDay(orders, now, days: 7);
            final weekly = _groupByWeek(orders, now, weeks: 4);
            final monthly = _groupByMonth(orders, now, months: 6);
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _SummarySection(title: 'Daily (last 7 days)', items: daily),
                const SizedBox(height: 20),
                _SummarySection(title: 'Weekly (last 4 weeks)', items: weekly),
                const SizedBox(height: 20),
                _SummarySection(title: 'Monthly (last 6 months)', items: monthly),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.total, this.count);

  final String label;
  final num total;
  final int count;
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${item.count} orders',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Rp ${item.total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_SummaryItem> _groupByDay(
  List<Order> orders,
  DateTime now, {
  required int days,
}) {
  final items = <_SummaryItem>[];
  for (var i = 0; i < days; i++) {
    final date = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: i),
    );
    final next = date.add(const Duration(days: 1));
    final dayOrders = orders.where(
      (order) => order.createdAt.isAfter(date) && order.createdAt.isBefore(next),
    );
    final total = dayOrders.fold<num>(0, (sum, o) => sum + o.totalPrice);
    items.add(
      _SummaryItem(_formatDayLabel(date), total, dayOrders.length),
    );
  }
  return items;
}

List<_SummaryItem> _groupByWeek(
  List<Order> orders,
  DateTime now, {
  required int weeks,
}) {
  final items = <_SummaryItem>[];
  final startOfWeek = _startOfWeek(now);
  for (var i = 0; i < weeks; i++) {
    final start = startOfWeek.subtract(Duration(days: 7 * i));
    final end = start.add(const Duration(days: 7));
    final weekOrders = orders.where(
      (order) => order.createdAt.isAfter(start) && order.createdAt.isBefore(end),
    );
    final total = weekOrders.fold<num>(0, (sum, o) => sum + o.totalPrice);
    items.add(
      _SummaryItem(
        '${_formatDayLabel(start)} - ${_formatDayLabel(end.subtract(const Duration(days: 1)))}',
        total,
        weekOrders.length,
      ),
    );
  }
  return items;
}

List<_SummaryItem> _groupByMonth(
  List<Order> orders,
  DateTime now, {
  required int months,
}) {
  final items = <_SummaryItem>[];
  for (var i = 0; i < months; i++) {
    final month = DateTime(now.year, now.month - i, 1);
    final next = DateTime(month.year, month.month + 1, 1);
    final monthOrders = orders.where(
      (order) => order.createdAt.isAfter(month) && order.createdAt.isBefore(next),
    );
    final total = monthOrders.fold<num>(0, (sum, o) => sum + o.totalPrice);
    items.add(
      _SummaryItem(_formatMonthLabel(month), total, monthOrders.length),
    );
  }
  return items;
}

DateTime _startOfWeek(DateTime date) {
  final weekday = date.weekday; // 1 = Monday
  final start = DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: weekday - 1));
  return start;
}

String _formatDayLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

String _formatMonthLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
