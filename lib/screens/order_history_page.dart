import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/auth_controller.dart';
import '../services/firestore_service.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  String _friendlyStatus(String status) {
    return switch (status) {
      'PAID' => 'Paid',
      'SHIPPED' => 'Shipped',
      _ => 'Pending payment',
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthController>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view orders.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Order>>(
          stream: context.read<FirestoreService>().watchUserOrders(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const Center(
                child: Text('No orders yet. Your journey awaits.'),
              );
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
                          _friendlyStatus(order.status),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${order.totalPrice.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: order.items
                              .map(
                                (item) => Text(
                                  '${item.name} x${item.qty}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                              .toList(),
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
