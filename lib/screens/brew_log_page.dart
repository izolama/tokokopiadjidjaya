import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/brew_log.dart';
import '../services/auth_controller.dart';
import '../services/firestore_service.dart';

class BrewLogPage extends StatefulWidget {
  const BrewLogPage({super.key});

  @override
  State<BrewLogPage> createState() => _BrewLogPageState();
}

class _BrewLogPageState extends State<BrewLogPage> {
  String? _selectedProductId;
  String _brewMethod = 'V60';
  int _rating = 4;
  final TextEditingController _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null || _selectedProductId == null) return;
    setState(() => _saving = true);
    await context.read<FirestoreService>().addBrewLog(
          userId: user.uid,
          productId: _selectedProductId!,
          brewMethod: _brewMethod,
          rating: _rating,
          note: _noteController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    _noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your coffee journal.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew Journal'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<List<Product>>(
            stream: context.read<FirestoreService>().watchActiveProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              final user = context.read<AuthController>().user;
              final productNameById = {
                for (final product in products) product.id: product.name,
              };
              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'How did your coffee taste today?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    items: products
                        .map(
                          (product) => DropdownMenuItem(
                            value: product.id,
                            child: Text(product.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedProductId = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Coffee selection',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _brewMethod,
                    items: const [
                      'V60',
                      'French Press',
                      'AeroPress',
                      'Espresso',
                      'Cold Brew',
                    ]
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _brewMethod = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Brew method',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rating',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _rating.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_rating',
                    onChanged: (value) =>
                        setState(() => _rating = value.toInt()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Tasting note or mood',
                      hintText: 'Soft citrus, calm morning, slow thoughts...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveLog,
                    child: Text(_saving ? 'Saving...' : 'Save to journal'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Recent brews',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (user == null)
                    Text(
                      'Sign in to see your journal history.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    StreamBuilder<List<BrewLog>>(
                      stream: context
                          .read<FirestoreService>()
                          .watchUserBrewLogs(user.uid),
                      builder: (context, logSnapshot) {
                        if (logSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final logs = logSnapshot.data ?? [];
                        if (logs.isEmpty) {
                          return Text(
                            'No journal entries yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: logs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final productName =
                                productNameById[log.productId] ?? 'Coffee';
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      log.brewMethod,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rating: ${log.rating}/5',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    if (log.note.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        log.note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
