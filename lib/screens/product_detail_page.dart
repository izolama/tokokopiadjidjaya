import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/cart_controller.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/coffee_hero_image.dart';
import 'checkout_whatsapp.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final PageController _pageController;
  double _pageOffset = 0;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _heroFade;
  late final Animation<double> _heroScale;
  late final Animation<double> _storyFade;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pageController = PageController();
    _pageController.addListener(() {
      if (!mounted) return;
      setState(() => _pageOffset = _pageController.page ?? 0);
    });
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.45)),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.45, curve: Curves.easeInOut),
    );
    _heroFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _heroScale = Tween<double>(begin: 0.98, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );
    _storyFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.95, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showOrderSheet() {
    final cart = context.read<CartController>();
    int quantity = 1;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DAD2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _OrderThumbnail(
                        imageUrl: widget.product.imageUrls.isEmpty
                            ? null
                            : widget.product.imageUrls.first,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rp ${widget.product.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$quantity'),
                          IconButton(
                            onPressed: () => setState(() => quantity++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: PressableScale(
                      onTap: () {
                        cart.addItem(
                          OrderItem(
                            productId: widget.product.id,
                            name: widget.product.name,
                            qty: quantity,
                            price: widget.product.price,
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const CheckoutWhatsappPage(),
                            transitionsBuilder:
                                (_, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Continue to WhatsApp',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final notes = product.tastingNotes.take(3).toList();
    final remaining = product.tastingNotes.length - notes.length;
    final imageUrls = product.imageUrls;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _heroFade,
                child: ScaleTransition(
                  scale: _heroScale,
                  child: _DetailImageCarousel(
                    heroTag: 'hero_product_${product.id}',
                    imageUrls: imageUrls,
                    controller: _pageController,
                    pageOffset: _pageOffset,
                    onChanged: (index) =>
                        setState(() => _currentImage = index),
                  ),
                ),
              ),
              if (imageUrls.length > 1) ...[
                const SizedBox(height: 10),
                Center(
                  child: _DotIndicator(
                    count: imageUrls.length,
                    currentIndex: _currentImage,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.weightGram}g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF7B7B7B),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...List.generate(notes.length, (index) {
                    final start = 0.35 + (index * 0.12);
                    final end = (start + 0.3).clamp(0.0, 1.0);
                    final animation = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(start, end, curve: Curves.easeInOut),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: _DetailNoteChip(label: notes[index]),
                    );
                  }),
                  if (remaining > 0) _DetailNoteChip(label: '+$remaining'),
                ],
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _storyFade,
                child: Text(
                  product.story,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PressableScale(
                scale: 0.97,
                onTap: _showOrderSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Order via WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No checkout hassle. Order directly via WhatsApp.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B7B7B),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailImageCarousel extends StatelessWidget {
  const _DetailImageCarousel({
    required this.heroTag,
    required this.imageUrls,
    required this.controller,
    required this.pageOffset,
    required this.onChanged,
  });

  final String heroTag;
  final List<String> imageUrls;
  final PageController controller;
  final double pageOffset;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE6),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: _SoftBlob(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.08),
                size: 140,
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: _SoftBlob(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withOpacity(0.08),
                size: 160,
              ),
            ),
            if (imageUrls.isEmpty)
              Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.local_cafe,
                  size: 48,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              )
            else
              PageView.builder(
                controller: controller,
                itemCount: imageUrls.length,
                onPageChanged: onChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final delta = (pageOffset - index).clamp(-1.0, 1.0);
                  final translateX = delta * 10;
                  final tag = index == 0 ? heroTag : '${heroTag}_$index';
                  return Transform.translate(
                    offset: Offset(translateX, 0),
                    child: SizedBox.expand(
                      child: CoffeeHeroImage(
                        heroTag: tag,
                        imageProvider: NetworkImage(imageUrls[index]),
                        radius: 28,
                        aspectRatio: null,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                : const Color(0xFFD8D1C8),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class _OrderThumbnail extends StatelessWidget {
  const _OrderThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3DDD6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl == null
            ? Icon(
                Icons.local_cafe,
                color: Theme.of(context).colorScheme.secondary,
              )
            : Image.network(imageUrl!, fit: BoxFit.cover),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

class _DetailNoteChip extends StatelessWidget {
  const _DetailNoteChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E0D8)),
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
