import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/firestore_service.dart';

class AdminOrderListPage extends StatelessWidget {
  const AdminOrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Verification'),
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
            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${order.id.substring(0, 6).toUpperCase()}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${order.status}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: Rp ${order.totalPrice.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map(
                          (item) => Text('${item.name} x${item.qty}'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => context
                                  .read<FirestoreService>()
                                  .updateOrderStatus(order.id, 'PAID'),
                              child: const Text('Mark Paid'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => context
                                  .read<FirestoreService>()
                                  .updateOrderStatus(order.id, 'SHIPPED'),
                              child: const Text('Mark Shipped'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
