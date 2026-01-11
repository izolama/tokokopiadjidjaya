import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/firestore_service.dart';

class AdminProductManagementPage extends StatelessWidget {
  const AdminProductManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const AdminProductForm(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Product>>(
          stream: context.read<FirestoreService>().watchAllProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const Center(child: Text('No products yet.'));
            }
            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      'Rp ${product.price.toStringAsFixed(0)} • ${product.weightGram}g',
                    ),
                    trailing: Icon(
                      product.active ? Icons.check_circle : Icons.pause_circle,
                      color: product.active ? Colors.green : Colors.orange,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => AdminProductForm(product: product),
                        ),
                      );
                    },
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

class AdminProductForm extends StatefulWidget {
  const AdminProductForm({super.key, this.product});

  final Product? product;

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends State<AdminProductForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  late final TextEditingController _storyController;
  late final TextEditingController _imageUrlsController;
  bool _active = true;
  bool _saving = false;
  final List<String> _imageUrls = [];

  List<String> get _parsedPreviewUrls {
    return _imageUrlsController.text
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    _weightController =
        TextEditingController(text: product?.weightGram.toString() ?? '');
    _notesController =
        TextEditingController(text: product?.tastingNotes.join(', ') ?? '');
    _storyController = TextEditingController(text: product?.story ?? '');
    _imageUrlsController =
        TextEditingController(text: (product?.imageUrls ?? []).join(', '));
    _active = product?.active ?? true;
    _imageUrls.addAll(product?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _storyController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final notes = _notesController.text
        .split(',')
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList();
    final urls = _imageUrlsController.text
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    final service = context.read<FirestoreService>();
    String productId;
    if (widget.product == null) {
      productId = service.newProductId();
    } else {
      productId = widget.product!.id;
    }
    final allUrls = urls;
    if (widget.product == null) {
      await service.createProduct(
        productId: productId,
        name: _nameController.text.trim(),
        price: num.tryParse(_priceController.text.trim()) ?? 0,
        weightGram: num.tryParse(_weightController.text.trim()) ?? 0,
        tastingNotes: notes,
        story: _storyController.text.trim(),
        active: _active,
        imageUrls: allUrls,
      );
    } else {
      final product = widget.product!;
      await service.upsertProduct(
        Product(
          id: product.id,
          name: _nameController.text.trim(),
          price: num.tryParse(_priceController.text.trim()) ?? 0,
          weightGram: num.tryParse(_weightController.text.trim()) ?? 0,
          tastingNotes: notes,
          story: _storyController.text.trim(),
          active: _active,
          imageUrls: allUrls,
          createdAt: product.createdAt,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.product == null ? 'New Product' : 'Edit Product'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Product image URLs (optional)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _imageUrlsController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Paste image URLs, separated by commas',
              ),
            ),
            const SizedBox(height: 12),
            if (_parsedPreviewUrls.isNotEmpty)
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _parsedPreviewUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final url = _parsedPreviewUrls[index];
                    return _ImagePreviewTile(url: url);
                  },
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (gram)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Tasting notes (comma separated)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _storyController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Coffee story'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              title: const Text('Active product'),
              onChanged: (value) => setState(() => _active = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  const _ImagePreviewTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 96,
        height: 96,
        color: const Color(0xFFF1ECE7),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
