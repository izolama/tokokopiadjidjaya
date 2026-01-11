import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/coffee_profile.dart';
import '../theme/app_theme.dart';
import 'brew_log_page.dart';

class PersonaDetailPage extends StatefulWidget {
  const PersonaDetailPage({super.key, required this.profile});

  final CoffeeProfile profile;

  @override
  State<PersonaDetailPage> createState() => _PersonaDetailPageState();
}

class _PersonaDetailPageState extends State<PersonaDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final highlights = _highlights(profile);
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            _Stagger(
              controller: _controller,
              order: 0,
              scale: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.personaLabel,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _supportingLine(profile),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _Stagger(
              controller: _controller,
              order: 1,
              child: Text(
                _storyNarrative(profile),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 26),
            _Stagger(
              controller: _controller,
              order: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taste & habit highlights',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.85),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),

                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final item in highlights)
                          _HighlightChip(icon: item.icon, label: item.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _Stagger(
              controller: _controller,
              order: 3,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _pushSmooth(context, const BrewLogPage());
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Log another brew'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _supportingLine(CoffeeProfile profile) {
    return 'A calm ritual for unhurried moments.';
  }

  String _storyNarrative(CoffeeProfile profile) {
    final focus = profile.purpose;
    final taste = profile.tastePreference;
    final brew = profile.brewStyle;

    final tasteLine = switch (taste) {
      'bitter' => 'You lean toward deeper, bolder notes that feel grounding.',
      'acidic' =>
        'You enjoy brighter, lively cups that lift the mood without rushing it.',
      _ => 'You prefer balanced cups — steady, soft, and easy to return to.',
    };

    final brewLine = switch (brew) {
      'manual' => 'You enjoy the slow ritual of a manual brew.',
      'milk' => 'You appreciate a softer, milk-forward comfort.',
      _ => 'You like a clean, consistent cup without fuss.',
    };

    final purposeLine = switch (focus) {
      'work' => 'Coffee helps you find focus without sharp edges.',
      'socialize' => 'You enjoy coffee as a warm companion in shared moments.',
      _ => 'You use coffee as a gentle pause and reset.',
    };

    return 'You enjoy coffee as a quiet ritual.\n'
        '$tasteLine\n'
        '$brewLine\n'
        '$purposeLine';
  }

  Future<void> _pushSmooth(BuildContext context, Widget page) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  List<_Highlight> _highlights(CoffeeProfile profile) {
    return [
      _Highlight(
        icon: Icons.coffee_outlined,
        label: 'Taste: ${_capitalize(profile.tastePreference)}',
      ),
      _Highlight(
        icon: Icons.wb_sunny_outlined,
        label: 'Time: ${_capitalize(profile.drinkTime)}',
      ),
      _Highlight(
        icon: Icons.filter_hdr_outlined,
        label: 'Brew: ${_capitalize(profile.brewStyle)}',
      ),
    ];
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _Highlight {
  const _Highlight({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.deepBlue.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Stagger extends StatelessWidget {
  const _Stagger({
    required this.controller,
    required this.order,
    required this.child,
    this.scale = false,
  });

  final AnimationController controller;
  final int order;
  final Widget child;
  final bool scale;

  @override
  Widget build(BuildContext context) {
    final start = (order * 0.12).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(animation);
    final scaleAnim = Tween<double>(begin: 0.96, end: 1).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slide,
        child: scale ? ScaleTransition(scale: scaleAnim, child: child) : child,
      ),
    );
  }
}
