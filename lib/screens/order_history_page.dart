import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/auth_controller.dart';
import '../services/firestore_service.dart';
import '../widgets/pressable_scale.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  String _friendlyStatus(String status) {
    return switch (status) {
      'PAID' => 'Paid',
      'SHIPPED' => 'Shipped',
      _ => 'Pending payment',
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'PAID' => const Color(0xFF5E7D69),
      'SHIPPED' => const Color(0xFF4F6D8A),
      _ => const Color(0xFFB07A44),
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your coffee journey is just beginning.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your past cups will live here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final isLatest = index == 0;
                final statusColor = _statusColor(order.status);
                return _AnimatedOrderEntry(
                  index: index,
                  child: PressableScale(
                    scale: 0.98,
                    onTap: () {},
                    child: Opacity(
                      opacity: isLatest ? 1 : 0.92,
                      child: Transform.scale(
                        scale: isLatest ? 1.01 : 1,
                        child: Card(
                          elevation: isLatest ? 3 : 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _friendlyStatus(order.status),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(order.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF7B7B7B),
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Rp ${order.totalPrice.toStringAsFixed(0)}',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: order.items
                                      .map(
                                        (item) => Text(
                                          '${item.name} × ${item.qty}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _AnimatedOrderEntry extends StatefulWidget {
  const _AnimatedOrderEntry({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedOrderEntry> createState() => _AnimatedOrderEntryState();
}

class _AnimatedOrderEntryState extends State<_AnimatedOrderEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
