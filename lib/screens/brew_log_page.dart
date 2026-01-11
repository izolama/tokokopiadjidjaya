import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/brew_log.dart';
import '../services/auth_controller.dart';
import '../services/firestore_service.dart';
import '../widgets/pressable_scale.dart';

class BrewLogPage extends StatefulWidget {
  const BrewLogPage({super.key});

  @override
  State<BrewLogPage> createState() => _BrewLogPageState();
}

class _BrewLogPageState extends State<BrewLogPage>
    with SingleTickerProviderStateMixin {
  String? _selectedProductId;
  String? _selectedProductName;
  String _brewMethod = 'V60';
  int _rating = 4;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocus = FocusNode();
  bool _saving = false;
  bool _saved = false;
  bool _dragging = false;
  late final AnimationController _introController;

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _noteFocus.addListener(() {
      if (mounted) setState(() {});
    });
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
    setState(() {
      _saving = false;
      _saved = true;
    });
    HapticFeedback.lightImpact();
    _noteController.clear();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _saved = false);
      }
    });
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
                  _Stagger(
                    controller: _introController,
                    order: 0,
                    child: Text(
                      'How did your coffee taste today?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Stagger(
                    controller: _introController,
                    order: 1,
                    child: _SelectField(
                      label: 'Coffee selection',
                      value: _selectedProductName ?? 'Choose coffee',
                      onTap: () => _showSelectionSheet(
                        title: 'Choose coffee',
                        items: products.map((p) => p.name).toList(),
                        onSelected: (value) {
                          final selected = products
                              .firstWhere((p) => p.name == value);
                          setState(() {
                            _selectedProductId = selected.id;
                            _selectedProductName = selected.name;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Stagger(
                    controller: _introController,
                    order: 2,
                    child: _SelectField(
                      label: 'Brew method',
                      value: _brewMethod,
                      onTap: () => _showSelectionSheet(
                        title: 'Brew method',
                        items: const [
                          'V60',
                          'French Press',
                          'AeroPress',
                          'Espresso',
                          'Cold Brew',
                        ],
                        onSelected: (value) =>
                            setState(() => _brewMethod = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Stagger(
                    controller: _introController,
                    order: 3,
                    child: _RatingSlider(
                      value: _rating,
                      dragging: _dragging,
                      onChangeStart: () => setState(() => _dragging = true),
                      onChangeEnd: () => setState(() => _dragging = false),
                      onChanged: (value) =>
                          setState(() => _rating = value.toInt()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Stagger(
                    controller: _introController,
                    order: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasting note or mood',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _noteFocus.hasFocus
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : [],
                          ),
                          child: TextField(
                            focusNode: _noteFocus,
                            controller: _noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'How did this cup make you feel?',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MoodChip(
                              label: 'calm',
                              onTap: () => _insertMood('calm'),
                            ),
                            _MoodChip(
                              label: 'focused',
                              onTap: () => _insertMood('focused'),
                            ),
                            _MoodChip(
                              label: 'nutty',
                              onTap: () => _insertMood('nutty'),
                            ),
                            _MoodChip(
                              label: 'comforting',
                              onTap: () => _insertMood('comforting'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Stagger(
                    controller: _introController,
                    order: 5,
                    child: PressableScale(
                      scale: 0.97,
                      onTap: _saving ? null : _saveLog,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                          key: ValueKey(_saved),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: _saved
                                ? const Icon(Icons.check,
                                    color: Colors.white)
                                : Text(
                                    _saving ? 'Saving...' : 'Save to journal',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Stagger(
                    controller: _introController,
                    order: 6,
                    child: Text(
                      'Recent brews',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
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
                            return _AnimatedEntry(
                              index: index,
                              child: PressableScale(
                                scale: 0.98,
                                onTap: () {},
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          '${_ratingLabel(log.rating)} • ${log.rating}/5',
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

  void _insertMood(String mood) {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      _noteController.text = mood;
    } else if (!text.toLowerCase().contains(mood.toLowerCase())) {
      _noteController.text = '$text, $mood';
    }
    _noteController.selection = TextSelection.fromPosition(
      TextPosition(offset: _noteController.text.length),
    );
  }

  Future<void> _showSelectionSheet({
    required String title,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0DAD2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final value = items[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: const Color(0xFFF8F4EF),
                      title: Text(value),
                      onTap: () {
                        onSelected(value);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stagger extends StatelessWidget {
  const _Stagger({
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (order * 0.1).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B7B7B),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.value,
    required this.dragging,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
  });

  final int value;
  final bool dragging;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeStart;
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final label = _ratingLabel(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rating', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final position =
                (value - 1) / 4 * (trackWidth - 24) + 6;
            return Stack(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    inactiveTrackColor: const Color(0xFFE8E1D9),
                    thumbColor: Theme.of(context).colorScheme.primary,
                    thumbShape: _ScaledThumbShape(scale: dragging ? 1.1 : 1),
                    overlayColor: Colors.transparent,
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChangeStart: (_) => onChangeStart(),
                    onChangeEnd: (_) => onChangeEnd(),
                    onChanged: onChanged,
                  ),
                ),
                Positioned(
                  left: position.clamp(0, trackWidth - 60),
                  top: 0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: dragging ? 1.05 : 1,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: dragging ? 1 : 0.8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F1EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F1EB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7B7B7B),
              ),
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _DelayedFadeSlide(
      delay: Duration(milliseconds: 40 * index),
      child: child,
    );
  }
}

String _ratingLabel(int rating) {
  if (rating <= 2) return 'Too light';
  if (rating == 3) return 'Balanced';
  return 'Lovely cup ☕';
}

class _ScaledThumbShape extends SliderComponentShape {
  const _ScaledThumbShape({required this.scale});

  final double scale;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    const base = 10.0;
    return Size.square(base * scale);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFFD04640);
    context.canvas.drawCircle(center, 8 * scale, paint);
  }
}

class _DelayedFadeSlide extends StatefulWidget {
  const _DelayedFadeSlide({
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  State<_DelayedFadeSlide> createState() => _DelayedFadeSlideState();
}

class _DelayedFadeSlideState extends State<_DelayedFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_fade);
    Future.delayed(widget.delay, () {
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
