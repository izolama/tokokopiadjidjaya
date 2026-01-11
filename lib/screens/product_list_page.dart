import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/auth_controller.dart';
import '../services/cart_controller.dart';
import '../services/firestore_service.dart';
import '../widgets/pressable_scale.dart';
import 'checkout_whatsapp.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Journey'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const CheckoutWhatsappPage(),
                      ),
                    );
                  },
                ),
                Consumer<CartController>(
                  builder: (context, cart, _) {
                    if (cart.totalItems == 0) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cart.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) _SmartReorderBanner(userId: user.uid),
              const SizedBox(height: 12),
              Text(
                'Find the coffee that suits your journey.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by taste or coffee name',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: context.read<FirestoreService>().watchActiveProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final products = snapshot.data ?? [];
                    final filtered = _query.isEmpty
                        ? products
                        : products
                            .where(
                              (product) =>
                                  product.name
                                      .toLowerCase()
                                      .contains(_query.toLowerCase()) ||
                                  product.tastingNotes.any(
                                    (note) => note
                                        .toLowerCase()
                                        .contains(_query.toLowerCase()),
                                  ),
                            )
                            .toList();
                    if (products.isEmpty) {
                      return const Center(
                        child: Text('No coffees available right now.'),
                      );
                    }
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No coffees match your search.'),
                      );
                    }
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _ProductCard(product: product);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartReorderBanner extends StatelessWidget {
  const _SmartReorderBanner({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DateTime?>(
      future: context.read<FirestoreService>().fetchLastOrderDate(userId),
      builder: (context, snapshot) {
        final lastOrder = snapshot.data;
        if (lastOrder == null) {
          return const SizedBox.shrink();
        }
        final days = DateTime.now().difference(lastOrder).inDays;
        if (days <= 14) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF4F1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_cafe, color: Color(0xFF8B1E24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your coffee might be running out.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
    final tastingNotes = product.tastingNotes.take(3).toList();
    final remaining = product.tastingNotes.length - tastingNotes.length;
    return PressableScale(
      scale: 0.98,
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'hero_product_${product.id}',
                    child: _ProductThumbnail(
                      imageUrl:
                          product.imageUrls.isEmpty ? null : product.imageUrls.first,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rp ${product.price.toStringAsFixed(0)} • ${product.weightGram}g',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF7B7B7B),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...tastingNotes.map(
                    (note) => _NoteChip(label: note),
                  ),
                  if (remaining > 0) _NoteChip(label: '+$remaining'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.story,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: PressableScale(
                  scale: 0.98,
                  onTap: () {
                    final isNew = cart.addItem(
                      OrderItem(
                        productId: product.id,
                        name: product.name,
                        qty: 1,
                        price: product.price,
                      ),
                    );
                    if (isNew) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to your cart.')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Choose',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3DDD6)),
      ),
      child: Center(
        child: imageUrl == null
            ? Icon(
                Icons.local_cafe,
                color: Theme.of(context).colorScheme.secondary,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl!,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E2DB)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: const Color(0xFF6B6B6B),
            ),
      ),
    );
  }
}
