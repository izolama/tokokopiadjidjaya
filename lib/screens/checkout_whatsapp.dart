import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../services/auth_controller.dart';
import '../services/cart_controller.dart';
import '../services/firestore_service.dart';
import '../widgets/pressable_scale.dart';

class CheckoutWhatsappPage extends StatefulWidget {
  const CheckoutWhatsappPage({super.key});

  @override
  State<CheckoutWhatsappPage> createState() => _CheckoutWhatsappPageState();
}

class _CheckoutWhatsappPageState extends State<CheckoutWhatsappPage> {
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;
  bool _pageReady = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _pageReady = true);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();
    final user = auth.user;
    if (user == null || cart.items.isEmpty) return;
    setState(() => _submitting = true);
    await context.read<FirestoreService>().createOrder(
      userId: user.uid,
      items: cart.items,
      totalPrice: cart.totalPrice,
      paymentMethod: 'WHATSAPP',
    );
    final message = _buildMessage(
      name: user.displayName ?? 'Customer',
      items: cart.items,
      totalPrice: cart.totalPrice,
      note: _noteController.text.trim(),
    );
    final url = _buildWhatsappUrl(message);
    cart.clear();
    if (!mounted) return;
    setState(() => _submitting = false);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _buildMessage({
    required String name,
    required List<OrderItem> items,
    required num totalPrice,
    required String note,
  }) {
    final buffer =
        StringBuffer()
          ..writeln('Hi Tokokopiadjidjaya, I would like to reorder:')
          ..writeln('Name: $name')
          ..writeln('Items:');
    for (final item in items) {
      buffer.writeln('- ${item.name} x${item.qty}');
    }
    buffer.writeln('Total: Rp ${totalPrice.toStringAsFixed(0)}');
    if (note.isNotEmpty) {
      buffer.writeln('Delivery note: $note');
    }
    buffer.writeln('Thank you.');
    return buffer.toString();
  }

  Uri _buildWhatsappUrl(String message) {
    const phoneNumber =
        '6285935367387'; // TODO: replace with real store number.
    final encoded = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$phoneNumber?text=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (cart.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Your cart is calm and empty.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 260),
                    opacity: _pageReady ? 1 : 0,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Rp ${item.price.toStringAsFixed(0)}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF7B7B7B),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                _QuantityControl(
                                  qty: item.qty,
                                  onDecrease:
                                      () => cart.updateQty(
                                        item.productId,
                                        item.qty - 1,
                                      ),
                                  onIncrease:
                                      () => cart.updateQty(
                                        item.productId,
                                        item.qty + 1,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (cart.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _SoftDivider(),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Order summary',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7B7B7B),
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} × ${item.qty}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          'Rp ${(item.price * item.qty).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF7B7B7B),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Note for us (optional)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7B7B7B),
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Any special request or delivery note?',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF7B7B7B),
                            ),
                      ),
                      Text(
                        'Rp ${cart.totalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PressableScale(
                    scale: 0.98,
                    onTap: _submitting ? null : _placeOrder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _submitting
                                ? 'Preparing...'
                                : 'Continue to WhatsApp',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You’ll confirm your order directly via WhatsApp chat.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B7B7B),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: const Color(0xFFE9E2DB),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.qty,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _QtyButton(icon: Icons.remove, onTap: onDecrease),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Text(
              '$qty',
              key: ValueKey(qty),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 6),
          _QtyButton(icon: Icons.add, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF7B7B7B)),
      ),
    );
  }
}
